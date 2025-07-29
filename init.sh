#!/bin/bash
set -e

# Log de execução
arquivo="/var/teste/log_exec.txt"

if [ ! -e "$arquivo" ]; then
  echo "Log de execuções do arquivo init.sh:" > "$arquivo"
  echo "Arquivo criado em $(date)" >> "$arquivo"
  echo "-----------------------------------------" >> "$arquivo"
fi

read -p "Digite seu nome: " nome
read -p "Digite seu email: " email
data=$(date '+%Y-%m-%d %H:%M:%S')

echo "Executado por: $nome | Email: $email | Data: $data" >> "$arquivo"
echo "-----------------------------------------" >> "$arquivo"

echo "=====> Dando permissões para as pastas da aplicação"
cd /var/teste/airflow_architecture/airflow
sudo chmod -R 775 dags logs plugins

echo "=====> Subindo Postgres e Redis..."
docker compose -f docker-compose.yaml up -d postgres redis

echo "=====> Esperando 20 segundos pro Postgres e Redis ficarem prontos..."
sleep 20

echo "=====> Rodando airflow-init..."
docker compose -f docker-compose.yaml run --rm airflow-init

echo "=====> Esperando 10 segundos após airflow-init..."
sleep 10

echo "=====> Subindo Airflow stack..."
docker compose -f docker-compose.yaml up -d

echo "=====> Esperando 30 segundos pro Airflow inicializar..."
sleep 30

echo "=====> Checando Worker..."
if docker ps | grep -q docker-airflow-worker-1; then
  echo "=====> Limpando PID do Worker..."
  docker exec docker-airflow-worker-1 rm -f /opt/airflow/airflow-worker.pid || true
fi

echo "=====> Reiniciando Worker..."
docker compose -f docker-compose.yaml restart airflow-worker

echo "=====> Subindo Elastic..."
cd /var/teste/infrastructure_architecture/infrastructure
docker compose -f docker-compose-elastic.yaml up -d

echo "=====> Esperando 30 segundos pro Elastic ficar pronto..."
sleep 30

echo "=====> Subindo NGINX HUB..."
cd /var/teste/web_architecture/hub
docker compose -f docker-compose-nginx-hub.yaml up -d

echo "=====> Esperando 10 segundos..."
sleep 10

echo "=====> Subindo NGINX Vendas..."
cd /var/teste/web_architecture/map_sales
docker compose -f docker-compose-nginx-sales.yml up -d

echo "=====> Esperando 10 segundos..."
sleep 10

echo "=====> Subindo Prometheus..."
cd /var/teste/infrastructure_architecture/infrastructure
docker compose -f docker-compose-prometheus.yaml up -d

echo "=====> FIM! Tudo rodando. Verifica com: docker ps"
