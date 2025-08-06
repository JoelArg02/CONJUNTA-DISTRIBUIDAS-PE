#!/bin/bash

# Script para limpiar todos los recursos de Kubernetes

echo "🧹 Limpiando recursos de Kubernetes..."

# Eliminar Ingress
echo "🌐 Eliminando Ingress..."
kubectl delete -f k8s/ingress.yaml --ignore-not-found=true

# Eliminar servicios de aplicación
echo "🏗️ Eliminando servicios de aplicación..."
kubectl delete -f k8s/billing/ --ignore-not-found=true
kubectl delete -f k8s/central/ --ignore-not-found=true
kubectl delete -f k8s/inventory/ --ignore-not-found=true

# Eliminar bases de datos y RabbitMQ
echo "💾 Eliminando bases de datos..."
kubectl delete -f k8s/postgresql/deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/mysql/deployment.yaml --ignore-not-found=true
kubectl delete -f k8s/rabbitmq/deployment.yaml --ignore-not-found=true

# Eliminar ConfigMaps y Secrets
echo "⚙️ Eliminando ConfigMaps y Secrets..."
kubectl delete -f k8s/configmaps.yaml --ignore-not-found=true

# Eliminar PVCs
echo "💽 Eliminando Persistent Volume Claims..."
kubectl delete pvc postgresql-pvc -n distribuidas-conjunta --ignore-not-found=true
kubectl delete pvc mysql-pvc -n distribuidas-conjunta --ignore-not-found=true
kubectl delete pvc rabbitmq-pvc -n distribuidas-conjunta --ignore-not-found=true

# Opcional: Eliminar namespace (descomenta si quieres eliminar completamente)
# echo "📦 Eliminando namespace..."
# kubectl delete namespace distribuidas-conjunta --ignore-not-found=true

echo ""
echo "✅ Limpieza completada!"
echo "📋 Para verificar que todo se eliminó:"
echo "   kubectl get all -n distribuidas-conjunta"
