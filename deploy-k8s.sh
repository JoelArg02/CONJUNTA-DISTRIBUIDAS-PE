#!/bin/bash

# Script para desplegar todos los servicios en Kubernetes

echo "🚀 Desplegando aplicación distribuida en Kubernetes..."

# Crear namespace si no existe
echo "📦 Creando namespace..."
kubectl apply -f k8s/namespace.yaml

# Aplicar configuraciones
echo "⚙️ Aplicando ConfigMaps y Secrets..."
kubectl apply -f k8s/configmaps.yaml

# Desplegar bases de datos
echo "💾 Desplegando PostgreSQL..."
kubectl apply -f k8s/postgresql/deployment.yaml

echo "💾 Desplegando MySQL..."
kubectl apply -f k8s/mysql/deployment.yaml

echo "📬 Desplegando RabbitMQ..."
kubectl apply -f k8s/rabbitmq/deployment.yaml

# Esperar a que las bases de datos estén listas
echo "⏳ Esperando a que las bases de datos estén listas..."
kubectl wait --for=condition=available --timeout=300s deployment/postgresql -n distribuidas-conjunta
kubectl wait --for=condition=available --timeout=300s deployment/mysql -n distribuidas-conjunta
kubectl wait --for=condition=available --timeout=300s deployment/rabbitmq -n distribuidas-conjunta

# Desplegar servicios de aplicación
echo "🏗️ Desplegando servicios de aplicación..."
kubectl apply -f k8s/billing/
kubectl apply -f k8s/central/
kubectl apply -f k8s/inventory/

# Aplicar Ingress
echo "🌐 Aplicando Ingress..."
kubectl apply -f k8s/ingress.yaml

# Verificar estado del despliegue
echo "✅ Verificando estado del despliegue..."
kubectl get pods -n distribuidas-conjunta
kubectl get services -n distribuidas-conjunta

echo ""
echo "🎉 Despliegue completado!"
echo "📋 Para verificar el estado de los pods:"
echo "   kubectl get pods -n distribuidas-conjunta"
echo ""
echo "📋 Para ver los logs de un servicio específico:"
echo "   kubectl logs -f deployment/billing -n distribuidas-conjunta"
echo "   kubectl logs -f deployment/central -n distribuidas-conjunta"
echo "   kubectl logs -f deployment/inventory -n distribuidas-conjunta"
echo ""
echo "🌍 Servicios disponibles (si tienes un LoadBalancer o NodePort configurado):"
echo "   - Billing: http://distribuidas.local/billing"
echo "   - Central: http://distribuidas.local/central"
echo "   - Inventory: http://distribuidas.local/inventory"
echo "   - RabbitMQ Management: http://distribuidas.local/rabbitmq"
echo ""
echo "💡 Para acceso local, configura en /etc/hosts:"
echo "   127.0.0.1 distribuidas.local"
