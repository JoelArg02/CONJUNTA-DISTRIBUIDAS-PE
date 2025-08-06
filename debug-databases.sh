#!/bin/bash

# Script para diagnosticar problemas con las bases de datos en Kubernetes

echo "🔧 DIAGNÓSTICO DE BASES DE DATOS EN KUBERNETES"
echo "=============================================="

NAMESPACE="distribuidas-conjunta"

# Función para mostrar logs de un deployment
show_logs() {
    local app_name=$1
    echo ""
    echo "📋 Logs de $app_name:"
    echo "------------------------"
    
    POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=$app_name -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$POD_NAME" ]; then
        echo "Pod encontrado: $POD_NAME"
        kubectl logs $POD_NAME -n $NAMESPACE --tail=20 | head -20
    else
        echo "❌ No se encontró pod para $app_name"
    fi
}

# Función para mostrar el estado de los pods
show_pod_status() {
    echo "📊 ESTADO DE PODS:"
    echo "==================="
    kubectl get pods -n $NAMESPACE -o wide
}

# Función para mostrar eventos del namespace
show_events() {
    echo ""
    echo "🔔 EVENTOS RECIENTES:"
    echo "===================="
    kubectl get events -n $NAMESPACE --sort-by=.metadata.creationTimestamp | tail -10
}

# Función para verificar ConfigMaps y Secrets
show_config() {
    echo ""
    echo "⚙️ CONFIGURACIONES:"
    echo "==================="
    echo "ConfigMaps:"
    kubectl get configmaps -n $NAMESPACE
    echo ""
    echo "Secrets:"
    kubectl get secrets -n $NAMESPACE
}

# Función para probar conectividad
test_connectivity() {
    echo ""
    echo "🌐 PRUEBAS DE CONECTIVIDAD:"
    echo "==========================="
    
    # Test PostgreSQL
    echo "Probando PostgreSQL..."
    POSTGRES_POD=$(kubectl get pods -n $NAMESPACE -l app=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$POSTGRES_POD" ]; then
        kubectl exec $POSTGRES_POD -n $NAMESPACE -- pg_isready -U postgres 2>/dev/null && echo "✅ PostgreSQL está disponible" || echo "❌ PostgreSQL no está disponible"
    else
        echo "❌ Pod PostgreSQL no encontrado"
    fi
    
    # Test MySQL
    echo "Probando MySQL..."
    MYSQL_POD=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ ! -z "$MYSQL_POD" ]; then
        kubectl exec $MYSQL_POD -n $NAMESPACE -- mysqladmin ping -h localhost -u root -proot 2>/dev/null && echo "✅ MySQL está disponible" || echo "❌ MySQL no está disponible"
    else
        echo "❌ Pod MySQL no encontrado"
    fi
}

# Función principal
main() {
    echo "Namespace: $NAMESPACE"
    echo "Fecha: $(date)"
    
    show_pod_status
    show_events
    show_config
    test_connectivity
    
    echo ""
    echo "🔍 LOGS DETALLADOS:"
    echo "=================="
    show_logs "postgresql"
    show_logs "mysql"
    show_logs "rabbitmq"
    
    echo ""
    echo "🎯 COMANDOS ÚTILES PARA DEBUGGING:"
    echo "================================="
    echo "1. Ver logs en tiempo real:"
    echo "   kubectl logs -f <pod-name> -n $NAMESPACE"
    echo ""
    echo "2. Acceder a un pod:"
    echo "   kubectl exec -it <pod-name> -n $NAMESPACE -- /bin/bash"
    echo ""
    echo "3. Ver descripción completa de un pod:"
    echo "   kubectl describe pod <pod-name> -n $NAMESPACE"
    echo ""
    echo "4. Probar conexión a PostgreSQL:"
    echo "   kubectl exec -it <postgres-pod> -n $NAMESPACE -- psql -U postgres"
    echo ""
    echo "5. Probar conexión a MySQL:"
    echo "   kubectl exec -it <mysql-pod> -n $NAMESPACE -- mysql -u root -proot"
}

main
