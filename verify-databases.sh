#!/bin/bash

# Script para verificar el estado de las bases de datos en Kubernetes

echo "🔍 Verificando estado de las bases de datos..."
echo "============================================="

# Función para verificar si un pod está corriendo
check_pod_status() {
    local app_name=$1
    local namespace="distribuidas-conjunta"
    
    echo "📋 Verificando $app_name..."
    kubectl get pods -n $namespace -l app=$app_name --no-headers | while read pod_info; do
        pod_name=$(echo $pod_info | awk '{print $1}')
        status=$(echo $pod_info | awk '{print $3}')
        echo "  Pod: $pod_name - Status: $status"
    done
}

# Verificar PostgreSQL
echo ""
echo "🐘 PostgreSQL Status:"
check_pod_status "postgresql"

# Verificar MySQL  
echo ""
echo "🐬 MySQL Status:"
check_pod_status "mysql"

# Verificar RabbitMQ
echo ""
echo "🐰 RabbitMQ Status:"
check_pod_status "rabbitmq"

echo ""
echo "🔍 Verificando conectividad de bases de datos..."

# Verificar PostgreSQL databases
echo ""
echo "📊 Verificando bases de datos PostgreSQL..."
POSTGRES_POD=$(kubectl get pods -n distribuidas-conjunta -l app=postgresql -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$POSTGRES_POD" ]; then
    echo "Conectando al pod PostgreSQL: $POSTGRES_POD"
    echo "Bases de datos disponibles:"
    kubectl exec -it $POSTGRES_POD -n distribuidas-conjunta -- psql -U postgres -c "\l" 2>/dev/null || echo "❌ Error al conectar a PostgreSQL"
else
    echo "❌ No se encontró pod PostgreSQL"
fi

# Verificar MySQL database
echo ""
echo "📊 Verificando base de datos MySQL..."
MYSQL_POD=$(kubectl get pods -n distribuidas-conjunta -l app=mysql -o jsonpath='{.items[0].metadata.name}')
if [ ! -z "$MYSQL_POD" ]; then
    echo "Conectando al pod MySQL: $MYSQL_POD"
    echo "Bases de datos disponibles:"
    kubectl exec -it $MYSQL_POD -n distribuidas-conjunta -- mysql -u root -proot -e "SHOW DATABASES;" 2>/dev/null || echo "❌ Error al conectar a MySQL"
else
    echo "❌ No se encontró pod MySQL"
fi

echo ""
echo "✅ Verificación completada!"
