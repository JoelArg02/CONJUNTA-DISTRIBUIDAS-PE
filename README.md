# Sistema Distribuido con Microservicios

Este proyecto implementa un sistema distribuido con microservicios usando Spring Boot, PostgreSQL, MySQL, RabbitMQ y Kubernetes.

## 🏗️ Arquitectura

- **Billing Service** (Puerto 8080): PostgreSQL + RabbitMQ
- **Central Service** (Puerto 8000): PostgreSQL + RabbitMQ  
- **Inventory Service** (Puerto 8082): MySQL + RabbitMQ

## 📋 Prerequisitos

- Docker Desktop
- Minikube
- kubectl
- Java 17
- Maven 3.9+

## 🚀 Inicio Rápido

### Inicializar sistema completo
```bash
./init-system.sh
```

Este script:
1. ✅ Verifica prerequisitos (Docker, kubectl, Minikube)
2. 🚀 Inicia Minikube con configuración óptima (7GB RAM, 4 CPUs, 30GB disco)
3. 🐳 Configura Docker para usar daemon de Minikube
4. 🏗️ Construye todas las imágenes Docker
5. 💾 Despliega bases de datos (PostgreSQL, MySQL) 
6. 🐰 Despliega RabbitMQ
7. 📱 Despliega microservicios
8. 🌐 Configura Ingress y túnel de Minikube
9. 🎛️ Abre dashboard de Minikube automáticamente

### Detener sistema completo
```bash
./stop-system.sh
```

## 🛠️ Scripts Disponibles

### `init-system.sh` - Inicialización completa
- ✅ Configura e inicia Minikube automáticamente
- 🏗️ Construye imágenes Docker localmente
- 🚀 Despliega todo el sistema en Kubernetes
- 🎛️ Abre dashboard automáticamente

### `build-images.sh` - Solo construcción de imágenes
```bash
./build-images.sh
```
Construye las imágenes Docker de los 3 microservicios.

### `deploy-k8s.sh` - Solo despliegue
```bash
./deploy-k8s.sh
```
Despliega servicios en Kubernetes (asume que las imágenes ya existen).

### `cleanup-k8s.sh` - Limpieza de Kubernetes
```bash
./cleanup-k8s.sh
```
Elimina todos los recursos de Kubernetes pero deja Minikube corriendo.

### `stop-system.sh` - Parada completa
```bash
./stop-system.sh
```
Detiene todo: servicios, Minikube, túneles, dashboards.

## 🌍 Acceso a Servicios

Una vez iniciado el sistema:

### Con Ingress (recomendado)
- 💰 **Billing Service**: http://distribuidas.local/billing
- 🏢 **Central Service**: http://distribuidas.local/central  
- 📦 **Inventory Service**: http://distribuidas.local/inventory
- 📊 **RabbitMQ Management**: http://distribuidas.local/rabbitmq
- 🎛️ **Minikube Dashboard**: Se abre automáticamente

### Configuración manual de /etc/hosts
```bash
# Agregar esta línea a /etc/hosts (la IP se muestra al ejecutar init-system.sh)
<INGRESS_IP> distribuidas.local
```

## 📊 Monitoreo y Debugging

### Ver estado de pods
```bash
kubectl get pods -n distribuidas-conjunta
```

### Ver logs de servicios
```bash
# Logs de Billing
kubectl logs -f deployment/billing -n distribuidas-conjunta

# Logs de Central  
kubectl logs -f deployment/central -n distribuidas-conjunta

# Logs de Inventory
kubectl logs -f deployment/inventory -n distribuidas-conjunta
```

### Abrir dashboard manualmente
```bash
minikube dashboard
```

### Estado de Minikube
```bash
minikube status
```

## 🗃️ Bases de Datos

### PostgreSQL
- **Host**: postgresql-service.distribuidas-conjunta.svc.cluster.local
- **Puerto**: 5432
- **Usuario**: postgres
- **Contraseña**: rootpassword
- **Bases de datos**: `billing_db`, `central_db`

### MySQL
- **Host**: mysql-service.distribuidas-conjunta.svc.cluster.local
- **Puerto**: 3306
- **Usuario**: root
- **Contraseña**: root
- **Base de datos**: `inventory_db`

## 🐰 RabbitMQ

- **Host**: rabbitmq-service.distribuidas-conjunta.svc.cluster.local
- **Puerto AMQP**: 5672
- **Puerto Management**: 15672
- **Usuario**: admin
- **Contraseña**: rootpassword

## ⚙️ Variables de Entorno

Los servicios utilizan las siguientes variables de entorno:

```bash
# Base de datos
SPRING_DATASOURCE_URL=jdbc:postgresql://...
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=rootpassword

# RabbitMQ
SPRING_RABBITMQ_HOST=rabbitmq-service...
SPRING_RABBITMQ_PORT=5672
SPRING_RABBITMQ_USERNAME=admin
SPRING_RABBITMQ_PASSWORD=rootpassword

# JPA/Hibernate
JPA_HIBERNATE_DDL_AUTO=update
HIBERNATE_SHOW_SQL=true
```

## 🔧 Troubleshooting

### Error de recursos insuficientes
```bash
# Aumentar recursos de Minikube
minikube delete --purge
minikube start --driver=docker --memory=8000 --cpus=4 --disk-size=40g
```

### Pods no inician
```bash
# Ver eventos del cluster
kubectl get events -n distribuidas-conjunta --sort-by='.lastTimestamp'

# Describir pod problemático
kubectl describe pod <pod-name> -n distribuidas-conjunta
```

### Túnel no funciona
```bash
# Reiniciar túnel manualmente
pkill -f "minikube tunnel"
minikube tunnel
```

### Imágenes no se encuentran
```bash
# Verificar que Docker esté usando daemon de Minikube
eval $(minikube docker-env)

# Reconstruir imágenes
./build-images.sh
```

## 📁 Estructura del Proyecto

```
├── billing/                    # Servicio de facturación
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── central/                    # Servicio central
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── inventory/                  # Servicio de inventario
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── k8s/                       # Configuraciones de Kubernetes
│   ├── namespace.yaml
│   ├── configmaps.yaml
│   ├── ingress.yaml
│   ├── postgresql/
│   ├── mysql/
│   ├── rabbitmq/
│   ├── billing/
│   ├── central/
│   └── inventory/
├── init-system.sh             # 🚀 Script principal de inicialización
├── build-images.sh            # 🏗️ Solo construcción de imágenes
├── deploy-k8s.sh              # 📱 Solo despliegue
├── cleanup-k8s.sh             # 🧹 Limpieza de recursos
├── stop-system.sh             # 🛑 Parada completa del sistema
└── README.md                  # 📖 Este archivo
```

## 🎯 Desarrollo

Para desarrollo, puedes usar los scripts de forma modular:

```bash
# 1. Solo construir imágenes cuando cambies código
./build-images.sh

# 2. Redesplegar servicios específicos
kubectl rollout restart deployment/billing -n distribuidas-conjunta

# 3. Ver logs en tiempo real
kubectl logs -f deployment/billing -n distribuidas-conjunta
```
