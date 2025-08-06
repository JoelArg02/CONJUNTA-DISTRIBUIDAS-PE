#!/bin/bash

# Script para detener completamente el sistema y Minikube

echo "🛑 Deteniendo sistema distribuido completo..."
echo "==========================================="

# Limpiar recursos de Kubernetes
if [ -f "cleanup-k8s.sh" ]; then
    echo "🧹 Limpiando recursos de Kubernetes..."
    ./cleanup-k8s.sh
else
    echo "⚠️ Script cleanup-k8s.sh no encontrado, limpiando manualmente..."
    kubectl delete namespace distribuidas-conjunta --ignore-not-found=true 2>/dev/null || true
fi

# Detener túnel de Minikube
echo "🚇 Deteniendo túnel de Minikube..."
pkill -f "minikube tunnel" 2>/dev/null || true

# Detener dashboard de Minikube
echo "🎛️ Deteniendo dashboard de Minikube..."
pkill -f "minikube dashboard" 2>/dev/null || true

# Detener Minikube
echo "🔧 Deteniendo Minikube..."
if command -v minikube > /dev/null 2>&1; then
    minikube stop
    echo "✅ Minikube detenido"
else
    echo "⚠️ Minikube no está instalado"
fi

# Limpiar procesos relacionados con port-forwarding (por si acaso)
echo "🔗 Limpiando port-forwards..."
pkill -f "kubectl.*port-forward" 2>/dev/null || true

# Limpiar archivos temporales
echo "🗂️ Limpiando archivos temporales..."
rm -f /tmp/minikube-tunnel.log 2>/dev/null || true
rm -f /tmp/api-gateway-ingress.yaml 2>/dev/null || true

echo ""
echo "✅ Sistema completamente detenido!"
echo "================================"
echo ""
echo "🚀 Para reiniciar el sistema:"
echo "   ./init-system.sh"
echo ""
echo "🏗️ Para solo construir imágenes:"
echo "   ./build-images.sh"
echo ""
echo "💻 Para verificar estado de Minikube:"
echo "   minikube status"
