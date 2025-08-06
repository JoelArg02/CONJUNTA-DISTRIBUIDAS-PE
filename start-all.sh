#!/bin/bash

# Script completo para construir imágenes y desplegar en Kubernetes
set -e

echo "🚀 INICIANDO PROCESO COMPLETO DE BUILD Y DEPLOY"
echo "=============================================="

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  --build-only    Solo construir imágenes Docker"
    echo "  --deploy-only   Solo desplegar en Kubernetes (asume que las imágenes ya existen)"
    echo "  --clean         Limpiar recursos existentes antes de desplegar"
    echo "  --no-clean      NO limpiar recursos (por defecto SÍ se limpian para evitar conflictos)"
    echo "  --dashboard     Abrir Minikube dashboard al principio para monitorear"
    echo "  --check-only    Solo verificar prerequisitos y configurar entorno"
    echo "  --help          Mostrar esta ayuda"
    echo ""
    echo "Sin opciones: Construir imágenes y desplegar (con limpieza automática)"
}

# Variables por defecto
BUILD_IMAGES=true
DEPLOY_SERVICES=true
CLEAN_FIRST=true  # Por defecto limpiamos recursos para evitar conflictos de puertos
CHECK_ONLY=false
OPEN_DASHBOARD=false

# Procesar argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            DEPLOY_SERVICES=false
            shift
            ;;
        --deploy-only)
            BUILD_IMAGES=false
            shift
            ;;
        --clean)
            CLEAN_FIRST=true
            shift
            ;;
        --no-clean)
            CLEAN_FIRST=false
            shift
            ;;
        --dashboard)
            OPEN_DASHBOARD=true
            shift
            ;;
        --check-only)
            CHECK_ONLY=true
            BUILD_IMAGES=false
            DEPLOY_SERVICES=false
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

# Verificar que los scripts necesarios existan
if [ ! -f "build-images.sh" ]; then
    echo "Script build-images.sh no encontrado"
    exit 1
fi

if [ ! -f "deploy-k8s.sh" ]; then
    echo "Script deploy-k8s.sh no encontrado"
    exit 1
fi

# Hacer scripts ejecutables
chmod +x build-images.sh
chmod +x deploy-k8s.sh

# Verificar prerequisitos y configurar entorno
echo ""
echo "VERIFICANDO PREREQUISITOS..."

# Verificar que Docker esté instalado y ejecutándose
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "Docker no está ejecutándose. Por favor, inicia Docker Desktop"
    exit 1
fi

echo "Docker está ejecutándose"

# Verificar que Minikube esté instalado
if ! command -v minikube &> /dev/null; then
    echo "Minikube no está instalado"
    echo "📥 Instala Minikube desde: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

echo "Minikube está instalado"

# Verificar que kubectl esté instalado
if ! command -v kubectl &> /dev/null; then
    echo "kubectl no está instalado"
    echo "📥 Instala kubectl desde: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

echo "kubectl está instalado"

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
        echo "Error iniciando Minikube"
        echo "💡 Intenta ejecutar manualmente:"
        echo "   minikube delete --purge"
        echo "   minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g"
        exit 1
    fi
    
    echo "Minikube iniciado exitosamente"
else
    echo "Minikube ya está ejecutándose"
    
    # Verificar que el container realmente existe
    if ! docker ps | grep -q minikube; then
        echo "⚠️  Detectado estado inconsistente de Minikube. Reiniciando..."
        minikube delete --purge
        minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g
        
        if [ $? -ne 0 ]; then
            echo "Error reiniciando Minikube"
            exit 1
        fi
        
        echo "Minikube reiniciado exitosamente"
    fi
fi

# Verificar que Minikube esté configurado correctamente
echo "⚙️ Configurando entorno..."

# Configurar kubectl para usar Minikube
kubectl config use-context minikube

# Habilitar Ingress addon con manejo de errores
echo "Habilitando Ingress Controller..."
if ! minikube addons enable ingress; then
    echo "⚠️  Error habilitando Ingress. Intentando reiniciar Minikube..."
    minikube stop
    sleep 5
    minikube start --driver=docker --memory=7000 --cpus=4 --disk-size=30g
    
    # Intentar nuevamente
    if ! minikube addons enable ingress; then
        echo "No se pudo habilitar Ingress Controller"
        echo "💡 Puedes continuar sin Ingress, pero no tendrás acceso vía URLs amigables"
        echo "   Presiona Enter para continuar o Ctrl+C para cancelar..."
        read -r
    else
        echo "Ingress Controller habilitado tras reinicio"
    fi
else
    echo "Ingress Controller habilitado"
fi

# Configurar Docker para usar el daemon de Minikube (necesario para construir imágenes)
echo "🐳 Configurando Docker para Minikube..."
eval $(minikube docker-env)

echo "Entorno configurado correctamente"

# Abrir dashboard si se solicita (al principio para monitorear todo el proceso)
if [ "$OPEN_DASHBOARD" = true ]; then
    echo ""
    echo "🎛️ Abriendo Minikube Dashboard..."
    echo "💡 Se abrirá en tu navegador predeterminado para monitorear el despliegue"
    
    # Abrir dashboard en background
    nohup minikube dashboard > /dev/null 2>&1 &
    
    # Esperar un momento para que se inicie
    sleep 3
    
    echo "Dashboard iniciado en background"
fi

# Mostrar información del cluster
echo ""
echo "📊 INFORMACIÓN DEL CLUSTER:"
echo "   Minikube IP: $(minikube ip)"
echo "   Context actual: $(kubectl config current-context)"
echo ""

# Si solo se quiere verificar, terminar aquí
if [ "$CHECK_ONLY" = true ]; then
    echo "🎉 Verificación completada. El entorno está listo para el despliegue."
    echo ""
    echo "💡 Para desplegar todos los servicios ejecuta:"
    echo "   $0"
    echo ""
    echo "🔧 Para construir solo las imágenes:"
    echo "   $0 --build-only"
    echo ""
    echo "🚀 Para desplegar solo (si ya tienes las imágenes):"
    echo "   $0 --deploy-only"
    exit 0
fi

# Limpiar recursos si se solicita
if [ "$CLEAN_FIRST" = true ]; then
    echo ""
    echo "🧹 PASO 0: Limpiando recursos existentes..."
    
    kubectl delete namespace distribuidas --ignore-not-found=true
    
    echo "Esperando a que el namespace se elimine completamente..."
    while kubectl get namespace distribuidas > /dev/null 2>&1; do
        sleep 2
    done
    
    echo "Recursos limpiados"
fi

# Construir imágenes
if [ "$BUILD_IMAGES" = true ]; then
    echo ""
    echo "🔨 PASO 1: Construyendo imágenes Docker..."
    ./build-images.sh
    
    if [ $? -ne 0 ]; then
        echo "Error construyendo imágenes Docker"
        exit 1
    fi
    
    echo "Imágenes Docker construidas exitosamente"
fi

# Desplegar servicios
if [ "$DEPLOY_SERVICES" = true ]; then
    echo ""
    echo "🚀 PASO 2: Desplegando servicios en Kubernetes..."
    ./deploy-k8s.sh
    
    if [ $? -ne 0 ]; then
        echo "Error desplegando servicios en Kubernetes"
        exit 1
    fi
    
    echo "Servicios desplegados exitosamente"
fi

echo ""
echo "🎊 ¡PROCESO COMPLETO FINALIZADO EXITOSAMENTE!"
echo ""

if [ "$DEPLOY_SERVICES" = true ]; then
    echo ""
    echo "PASO 3: Configurando acceso externo y validando sistema..."
    
    # Esperar a que todos los pods estén listos
    echo "Esperando que todos los servicios estén listos..."
    kubectl wait --for=condition=available --timeout=300s deployment --all -n distribuidas
    
    # Verificar estado de Ingress Controller
    echo "Verificando Ingress Controller..."
    kubectl wait --namespace ingress-nginx \
        --for=condition=ready pod \
        --selector=app.kubernetes.io/component=controller \
        --timeout=300s || echo "⚠️ Ingress Controller no está listo, continuando..."
    
    # Crear configuración de Ingress para API Gateway usando sslip.io
    echo "Configurando Ingress para API Gateway con sslip.io..."
    MINIKUBE_IP=$(minikube ip)
    
    cat > /tmp/api-gateway-ingress.yaml << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-gateway-ingress
  namespace: distribuidas
  annotations:
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization"
    nginx.ingress.kubernetes.io/enable-cors: "true"
spec:
  rules:
  - host: gateway.$MINIKUBE_IP.sslip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-gateway
            port:
              number: 8000
  - host: auth.$MINIKUBE_IP.sslip.io
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: servicio-auth
            port:
              number: 8080
EOF

    kubectl apply -f /tmp/api-gateway-ingress.yaml
    
    # Obtener IP de Minikube para mostrar URLs
    MINIKUBE_IP=$(minikube ip)
    
    # Iniciar túnel de Minikube en background para acceso a Ingress
    echo "🚇 Iniciando túnel de Minikube..."
    echo "💡 Se necesitan permisos de administrador para el túnel"
    
    # Matar túneles existentes
    pkill -f "minikube tunnel" 2>/dev/null || true
    
    # Iniciar nuevo túnel en background
    nohup minikube tunnel > /tmp/minikube-tunnel.log 2>&1 &
    TUNNEL_PID=$!
    
    # Esperar a que el túnel esté activo
    echo "⏳ Esperando que el túnel esté activo..."
    sleep 10
    
    # Verificar que el Ingress tenga IP
    echo "Verificando Ingress..."
    for i in {1..30}; do
        INGRESS_IP=$(kubectl get ingress api-gateway-ingress -n distribuidas -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        if [ -n "$INGRESS_IP" ]; then
            echo "Ingress configurado con IP: $INGRESS_IP"
            break
        fi
        echo "   Esperando Ingress... (intento $i/30)"
        sleep 2
    done

    
    echo ""
    echo "📱 Comandos útiles:"
    echo "   Ver pods:          kubectl get pods -n distribuidas"
    echo "   Ver servicios:     kubectl get services -n distribuidas"
    echo "   Ver ingress:       kubectl get ingress -n distribuidas"
    echo "   Ver logs:          kubectl logs -f deployment/<service> -n distribuidas"
    echo "   Abrir dashboard:   minikube dashboard"
    echo "   Parar túnel:       pkill -f 'minikube tunnel'"
    echo ""
    echo "URLs principales:"
    echo "   API Gateway:       http://api.microservices.local"
    echo "   Auth Service:      http://auth.microservices.local"
    echo "   Health Check:      http://api.microservices.local/actuator/health"
    echo ""
    echo "🔐 Endpoints de autenticación:"
    echo "   Registro:          POST http://api.microservices.local/auth/register"
    echo "   Login:             POST http://api.microservices.local/auth/login"
    echo ""
    echo "📋 Ejemplo de registro:"
    echo '   curl -X POST http://api.microservices.local/auth/register '
    echo '     -H "Content-Type: application/json" '
    echo '     -d {"username":"test","email":"test@example.com","password":"pass123"}'
    echo ""
    echo "🔄 Para reiniciar todo:"
    echo "   $0 --clean"
    echo ""
    echo "Para solo verificar entorno:"
    echo "   $0 --check-only"
    echo ""
    echo "🎛️ Para incluir dashboard:"
    echo "   $0 --dashboard"
    echo ""
    echo "🛠️  Para troubleshooting:"
    echo "   kubectl describe pod <pod-name> -n distribuidas"
    echo "   kubectl get events -n distribuidas --sort-by='.lastTimestamp'"

        sleep 2
    done
 