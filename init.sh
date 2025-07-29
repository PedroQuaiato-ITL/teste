#!/bin/bash
set -e  # Para o script se qualquer comando der erro

# Pega o diretório onde o script tá salvo
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WAIT_FOR_IT="$SCRIPT_DIR/wait-for-it.sh"

echo "=====> Verificando wait-for-it.sh..."

# Baixa se não existir
if [ ! -f "$WAIT_FOR_IT" ]; then
  echo "=====> Baixando wait-for-it.sh..."
  curl -s -o "$WAIT_FOR_IT" https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh
  chmod +x "$WAIT_FOR_IT"
else
  echo "=====> wait-for-it.sh já existe, seguindo..."
fi

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

echo "=====> Esperando Postgres ficar pronto..."
$WAIT_FOR_IT localhost:5432 -- echo "=====> Postgres OK"

echo "=====> Esperando Redis ficar pronto..."
$WAIT_FOR_IT localhost:6379 -- echo "=====> Redis OK"

echo "=====> Rodando airflow-init..."
docker compose -f docker-compose.yaml run --rm airflow-init

echo "=====> Subindo Airflow stack..."
docker compose -f docker-compose.yaml up -d

echo "=====> Esperando Airflow Webserver ficar pronto..."
$WAIT_FOR_IT localhost:8080 -- echo "=====> Airflow Webserver OK"

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

echo "=====> Esperando Elastic (9200)..."
$WAIT_FOR_IT localhost:9200 -- echo "=====> Elastic OK"

echo "=====> Subindo NGINX HUB..."
cd /var/teste/web_architecture/hub
docker compose -f docker-compose-nginx-hub.yaml up -d

echo "=====> Subindo NGINX Vendas..."
cd /var/teste/web_architecture/map_sales
docker compose -f docker-compose-nginx-sales.yml up -d

echo "=====> Subindo Prometheus..."
cd /var/teste/infrastructure_architecture/infrastructure
docker compose -f docker-compose-prometheus.yaml up -d

echo "=====> FIM! Tudo rodando. Verifica com: docker ps"
