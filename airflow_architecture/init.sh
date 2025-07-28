#!/bin/bash

# --- SERVIÇO DO AIRFLOW ---

echo "Rodando airflow-init..."
docker compose -f /var/server_architecture/airflow_architecture/docker/docker-compose.yaml run --rm airflow-init
sleep 30

echo "Subindo serviços principais..."
docker compose -f /var/server_architecture/airflow_architecture/docker/docker-compose.yaml up -d
sleep 30

echo "Limpando PID do Worker..."
docker exec docker-airflow-worker-1 rm -f /opt/airflow/airflow-worker.pid || true
sleep 30

echo "Reiniciando Worker..."
docker compose -f /var/server_architecture/airflow_architecture/docker/docker-compose.yaml restart airflow-worker
sleep 10