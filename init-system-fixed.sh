#!/bin/bash

# Script de inicialización completa del sistema distribuido
# Este script construye las imágenes Docker, despliega todo en Kubernetes y abre el dashboard

set -e  # Salir si cualquier comando falla

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  --dashboard     Abrir dashboard primero para monitorear el proceso"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                # Iniciar sistema normalmente"
    echo "  $0 --dashboard    # Iniciar sistema y abrir dashboard primero"
}

# Variables por defecto
OPEN_DASHBOARD_FIRST=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --dashboard)
            OPEN_DASHBOARD_FIRST=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "🚀 Iniciando sistema distribuido completo..."
echo "================================================"

# Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Por favor inicia Docker Desktop."
    exit 1
fi

# Verificar si kubectl está disponible
if ! command -v kubectl > /dev/null 2>&1; then
    echo "❌ kubectl no está instalado. Por favor instálalo primero."
    exit 1
fi

# Verificar que Minikube esté instalado
if ! command -v minikube > /dev/null 2>&1; then
    echo "❌ Minikube no está instalado"
    echo "📥 Instala Minikube desde: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Verificar estado de Minikube e iniciarlo si es necesario
echo "🔧 Verificando estado de Minikube..."
MINIKUBE_STATUS=$(minikube status --format='{{.Host}}' 2>/dev/null || echo "Stopped")

if [ "$MINIKUBE_STATUS" != "Running" ]; then
    echo "🚀 Iniciando Minikube (esto puede tomar unos minutos)..."
    echo "💻 Configuración: 7GB RAM, 4 CPUs, 30GB disco"
    
    # Limpiar cualquier estado corrupto antes de iniciar
    echo "🧹 Limpiando estado previo de Minikube..."
    minikube delete --purge 2>/dev/null || true
    
    # Iniciar Minikube con configuración limpia y más recursos
    minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g
    
    if [ $? -ne 0 ]; then
        echo "❌ Error iniciando Minikube"
        echo "💡 Intenta ejecutar manualmente:"
        echo "   minikube delete --purge"
        echo "   minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g"
        exit 1
    fi
    
    echo "✅ Minikube iniciado exitosamente"
else
    echo "✅ Minikube ya está ejecutándose"
    
    # Verificar que el container realmente existe
    if ! docker ps | grep -q minikube; then
        echo "⚠️  Detectado estado inconsistente de Minikube. Reiniciando..."
        minikube delete --purge
        minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g
        
        if [ $? -ne 0 ]; then
            echo "❌ Error reiniciando Minikube"
            exit 1
        fi
        
        echo "✅ Minikube reiniciado exitosamente"
    fi
fi

# Configurar kubectl para usar Minikube
kubectl config use-context minikube

# Habilitar Ingress addon con manejo de errores
echo "🌐 Habilitando Ingress Controller..."
if ! minikube addons enable ingress; then
    echo "⚠️  Error habilitando Ingress. Intentando reiniciar Minikube..."
    minikube stop
    sleep 5
    minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g
    
    # Intentar nuevamente
    if ! minikube addons enable ingress; then
        echo "⚠️ No se pudo habilitar Ingress Controller"
        echo "💡 Puedes continuar sin Ingress, pero no tendrás acceso vía URLs amigables"
    else
        echo "✅ Ingress Controller habilitado tras reinicio"
    fi
else
    echo "✅ Ingress Controller habilitado"
fi

# Configurar Docker para usar el daemon de Minikube (necesario para construir imágenes)
echo "🐳 Configurando Docker para Minikube..."
eval $(minikube docker-env)

# Verificar contexto de Kubernetes
echo "🔍 Verificando contexto de Kubernetes..."
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📋 Contexto actual: $CURRENT_CONTEXT"
echo "📋 Minikube IP: $(minikube ip)"

# Abrir dashboard primero si se solicita
if [ "$OPEN_DASHBOARD_FIRST" = true ]; then
    echo "🚀 Abriendo dashboard para monitoreo..."
    echo "💡 El dashboard se abrirá en tu navegador para que puedas ver el progreso"
    nohup minikube dashboard > /dev/null 2>&1 &
    sleep 3
    echo "✅ Dashboard abierto - puedes monitorear el progreso desde ahí"
    echo ""
fi

# Función para construir una imagen Docker (con cache inteligente)
build_service() {
    local service=$1
    local port=$2
    echo "🏗️ Construyendo imagen Docker para $service..."
    
    cd $service
    
    # Verificar si la imagen ya existe
    if docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$service:latest"; then
        echo "📦 Imagen $service:latest ya existe - Docker usará cache para optimizar"
    else
        echo "📦 Primera construcción de $service:latest"
    fi
    
    # Construir imagen (Docker automáticamente usa cache cuando es posible)
    docker build -t $service:latest .
    cd ..
    
    echo "✅ Imagen $service:latest lista"
}

# Limpiar solo recursos de Kubernetes (mantener imágenes Docker)
echo "🧹 Limpiando recursos de Kubernetes (manteniendo imágenes Docker)..."
echo "======================================================================"

# Solo eliminar el namespace de Kubernetes
kubectl delete namespace distribuidas-conjunta --ignore-not-found=true 2>/dev/null || true

echo "⏳ Esperando a que el namespace se elimine completamente..."
while kubectl get namespace distribuidas-conjunta > /dev/null 2>&1; do
    sleep 2
done

echo "✅ Recursos de Kubernetes limpiados (imágenes Docker preservadas)"
sleep 2

# Construir todas las imágenes Docker
echo "🏗️ Construyendo imágenes Docker..."
echo "=================================="

build_service "billing" "8080"
build_service "central" "8000"
build_service "inventory" "8082"

echo "✅ Todas las imágenes Docker construidas exitosamente"

# Las imágenes se construyen automáticamente en el daemon de Minikube
# gracias a eval $(minikube docker-env) ejecutado anteriormente
echo "✅ Imágenes disponibles en Minikube"

# Crear namespace si no existe
echo "📦 Creando namespace..."
kubectl apply -f k8s/namespace.yaml

# Aplicar configuraciones
echo "⚙️ Aplicando ConfigMaps y Secrets..."
kubectl apply -f k8s/configmaps.yaml

# Desplegar bases de datos y servicios de infraestructura
echo "💾 Desplegando infraestructura..."
echo "================================"

echo "🐘 Desplegando PostgreSQL..."
kubectl apply -f k8s/postgresql/deployment.yaml

echo "🐬 Desplegando MySQL..."
kubectl apply -f k8s/mysql/deployment.yaml

echo "🐰 Desplegando RabbitMQ..."
kubectl apply -f k8s/rabbitmq/deployment.yaml

# Esperar a que la infraestructura esté lista
echo "⏳ Esperando a que la infraestructura esté lista..."
kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n distribuidas-conjunta || {
    echo "⚠️ PostgreSQL tardó mucho en iniciarse, continuando..."
}

kubectl wait --for=condition=available --timeout=300s deployment/mysql -n distribuidas-conjunta || {
    echo "⚠️ MySQL tardó mucho en iniciarse, continuando..."
}

kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq -n distribuidas-conjunta || {
    echo "⚠️ RabbitMQ tardó mucho en iniciarse, continuando..."
}

echo "✅ Infraestructura lista"

# Pequeña pausa adicional para asegurar que los servicios estén completamente listos
echo "⏳ Esperando estabilización de servicios..."
sleep 30

# Desplegar servicios de aplicación
echo "🏗️ Desplegando servicios de aplicación..."
echo "========================================"

echo "💰 Desplegando Billing Service..."
kubectl apply -f k8s/billing/

echo "🏢 Desplegando Central Service..."
kubectl apply -f k8s/central/

echo "📦 Desplegando Inventory Service..."
kubectl apply -f k8s/inventory/

# Aplicar Ingress
echo "🌐 Aplicando configuración de Ingress..."
kubectl apply -f k8s/ingress.yaml

# Esperar a que los servicios estén listos
echo "⏳ Esperando a que los servicios estén listos..."
kubectl wait --for=condition=available --timeout=300s deployment/billing -n distribuidas-conjunta || {
    echo "⚠️ Billing Service tardó mucho en iniciarse"
}

kubectl wait --for=condition=available --timeout=300s deployment/central -n distribuidas-conjunta || {
    echo "⚠️ Central Service tardó mucho en iniciarse"
}

kubectl wait --for=condition=available --timeout=300s deployment/inventory -n distribuidas-conjunta || {
    echo "⚠️ Inventory Service tardó mucho en iniciarse"
}

# Mostrar estado del sistema
echo "📊 Estado del sistema:"
echo "====================="
kubectl get pods -n distribuidas-conjunta
echo ""
kubectl get services -n distribuidas-conjunta

# Configurar acceso externo usando túnel de Minikube
echo ""
echo "🌐 Configurando acceso externo..."
echo "==============================="

# Obtener IP de Minikube
MINIKUBE_IP=$(minikube ip)
echo "📋 IP de Minikube: $MINIKUBE_IP"

# Matar procesos de túnel anteriores si existen
echo "🧹 Limpiando túneles anteriores..."
pkill -f "minikube tunnel" 2>/dev/null || true
sleep 2

# Configurar túnel de Minikube en segundo plano
echo "🚇 Iniciando túnel de Minikube..."
echo "💡 Se necesitan permisos de administrador para el túnel"
nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
TUNNEL_PID=$!

# Esperar a que el túnel esté activo
echo "⏳ Esperando que el túnel esté activo..."
sleep 10

# Verificar que el Ingress tenga IP
echo "🔍 Verificando Ingress..."
for i in {1..30}; do
    INGRESS_IP=$(kubectl get ingress distribuidas-ingress -n distribuidas-conjunta -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
    if [ -n "$INGRESS_IP" ]; then
        echo "✅ Ingress configurado con IP: $INGRESS_IP"
        break
    fi
    echo "   Esperando Ingress... (intento $i/30)"
    sleep 2
done

# Abrir el dashboard principal si no se abrió antes
if [ "$OPEN_DASHBOARD_FIRST" = false ]; then
    echo "🚀 Abriendo dashboard principal..."
    nohup minikube dashboard > /dev/null 2>&1 &
    sleep 3
fi

# También abrir RabbitMQ si está disponible
if [ -n "$INGRESS_IP" ]; then
    echo "🐰 Intentando abrir RabbitMQ Management..."
    if command -v open > /dev/null 2>&1; then
        # macOS
        open http://distribuidas.local/rabbitmq > /dev/null 2>&1 || true
    elif command -v xdg-open > /dev/null 2>&1; then
        # Linux
        xdg-open http://distribuidas.local/rabbitmq > /dev/null 2>&1 || true
    fi
fi

echo ""
echo "🎉 ¡Sistema distribuido iniciado exitosamente!"
echo "=============================================="
echo ""
if [ "$OPEN_DASHBOARD_FIRST" = true ]; then
    echo "📊 Dashboard ya abierto para monitoreo continuo"
else
    echo "📊 Dashboard disponible para monitoreo"
fi
echo ""
echo "🌍 Servicios disponibles:"
if [ -n "$INGRESS_IP" ]; then
    echo "  🎛️ Minikube Dashboard:    http://127.0.0.1:xxxxx (se abrió automáticamente)"
    echo "  💰 Billing Service:      http://distribuidas.local/billing"
    echo "  🏢 Central Service:      http://distribuidas.local/central"
    echo "  📦 Inventory Service:    http://distribuidas.local/inventory"
    echo "  📊 RabbitMQ Management:  http://distribuidas.local/rabbitmq (admin/rootpassword)"
    echo ""
    echo "💡 Asegúrate de tener en /etc/hosts:"
    echo "   $INGRESS_IP distribuidas.local"
else
    echo "  ⚠️ Ingress no está disponible, usa port-forward manualmente:"
    echo "  kubectl port-forward service/billing 8080:8080 -n distribuidas-conjunta"
    echo "  kubectl port-forward service/central 8000:8000 -n distribuidas-conjunta"
    echo "  kubectl port-forward service/inventory 8082:8082 -n distribuidas-conjunta"
    echo "  kubectl port-forward service/rabbitmq-service 15672:15672 -n distribuidas-conjunta"
fi
echo ""
echo "🔧 Comandos útiles:"
echo "  📊 Ver dashboard:         minikube dashboard"
echo "  📋 Ver pods:              kubectl get pods -n distribuidas-conjunta"
echo "  📋 Ver servicios:         kubectl get services -n distribuidas-conjunta"
echo "  📋 Ver ingress:           kubectl get ingress -n distribuidas-conjunta"
echo "  📋 Ver logs (billing):    kubectl logs -f deployment/billing -n distribuidas-conjunta"
echo "  📋 Ver logs (central):    kubectl logs -f deployment/central -n distribuidas-conjunta"
echo "  📋 Ver logs (inventory):  kubectl logs -f deployment/inventory -n distribuidas-conjunta"
echo ""
echo "🛑 Para detener el sistema:"
echo "  ./stop-system.sh"
echo ""
echo "🚇 Para detener el túnel:"
echo "  pkill -f 'minikube tunnel'"
echo ""
echo "🔄 Para reiniciar (con dashboard desde el inicio):"
echo "  ./init-system.sh --dashboard"
