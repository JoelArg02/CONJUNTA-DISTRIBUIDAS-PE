#!/bin/bash
set -euo pipefail

SERVICES=(
  "billing"
  "central"
  "inventory"
)

echo "Compilando imágenes Docker multi-stage..."

for SERVICE in "${SERVICES[@]}"; do
  [ -d "$SERVICE" ] || { echo "Saltando $SERVICE (no existe)"; continue; }
  [ -f "$SERVICE/Dockerfile" ] || { echo "Saltando $SERVICE (sin Dockerfile)"; continue; }

  IMAGE_NAME=$(echo "$SERVICE" | tr '[:upper:]' '[:lower:]')
  echo "Construyendo $IMAGE_NAME:latest"
  docker build -t "$IMAGE_NAME:latest" "$SERVICE"
  echo "$IMAGE_NAME listo"
done

echo "Finalizado"
