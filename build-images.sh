#!/bin/bash

# Script para construir solo las imágenes Docker de los servicios

set -e  # Salir si cualquier comando falla

echo "🏗️ Construyendo imágenes Docker..."
echo "=================================="

# Verificar si Docker está corriendo
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker no está corriendo. Por favor inicia Docker Desktop."
    exit 1
fi

# Función para construir una imagen Docker
build_service() {
    local service=$1
    local port=$2
    echo "🔨 Construyendo $service (puerto $port)..."
    
    cd $service
    
    # Verificar que existe Dockerfile
    if [ ! -f "Dockerfile" ]; then
        echo "❌ No se encontró Dockerfile en $service/"
        cd ..
        return 1
    fi
    
    # Construir imagen
    docker build -t $service:latest . --no-cache
    cd ..
    
    echo "✅ $service:latest construida exitosamente"
    return 0
}

# Construir todas las imágenes
echo "📦 Construyendo servicios..."

if build_service "billing" "8080"; then
    echo "✅ Billing construido"
else
    echo "❌ Error construyendo Billing"
    exit 1
fi

if build_service "central" "8000"; then
    echo "✅ Central construido"
else
    echo "❌ Error construyendo Central"
    exit 1
fi

if build_service "inventory" "8082"; then
    echo "✅ Inventory construido"
else
    echo "❌ Error construyendo Inventory"
    exit 1
fi

# Las imágenes se construyen directamente en el daemon de Docker/Minikube
# No es necesario cargar las imágenes manualmente cuando se usa eval $(minikube docker-env)

echo ""
echo "🎉 Todas las imágenes construidas exitosamente!"
echo "=============================================="
echo ""
echo "📋 Imágenes creadas:"
docker images | grep -E "(billing|central|inventory)" | grep latest
echo ""
echo "🚀 Para inicializar el sistema completo: ./init-system.sh"
