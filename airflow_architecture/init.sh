#!/bin/bash
set -e  # Se qualquer comando der erro, o script para (menos onde tiver '|| true')

echo "=====> Dando permissões para as pastas da aplicação"

cd /var/teste/airflow_architecture/docker

# Permissão recursiva, pra garantir que tudo dentro tem permissão
sudo chmod -R 775 dags plugins logs

# --- SERVIÇO DO AIRFLOW ---

echo "=====> Rodando airflow-init..."
docker compose -f docker-compose.yaml run --rm airflow-init

echo "=====> Esperando 30 segundos pra garantir..."
sleep 30

echo "=====> Subindo serviços principais..."
docker compose -f docker-compose.yaml up -d

echo "=====> Esperando 30 segundos pra containers ficarem prontos..."
sleep 30

echo "=====> Checando se o worker subiu..."
if docker ps | grep -q docker-airflow-worker-1; then
    echo "=====> Limpando PID do Worker..."
    docker exec docker-airflow-worker-1 rm -f /opt/airflow/airflow-worker.pid || true
else
    echo "=====> Worker não está rodando ainda. Esperando mais 10s..."
    sleep 10
fi

echo "=====> Reiniciando Worker..."
docker compose -f docker-compose.yaml restart airflow-worker

echo "=====> Pronto! Airflow deve estar rodando. Verifica com: docker ps"
