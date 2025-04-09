#!/bin/bash

# === Color codes ===
BOLD="\e[1m"
RESET="\e[0m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
GRAY="\e[90m"

print_section_header() {
  echo -e "\n${GRAY}============================================================${RESET}"
  echo -e "${BLUE}${BOLD}$1${RESET}"
  echo -e "${GRAY}============================================================${RESET}"
}

print_info() {
  echo -e "${BLUE}ℹ️  $1${RESET}"
}

print_success() {
  echo -e "${GREEN}✅ $1${RESET}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${RESET}"
}

load_env() {
  print_section_header "🌍 Loading Environment Variables"
  if [ -f .env ]; then
    set -a
    source .env
    set +a
    print_success ".env variables loaded."
  else
    print_warning ".env file not found. Exiting."
    exit 1
  fi
}

configure_variables() {
  print_section_header "⚙️ Configuration Setup"

  read -p "➡️  N8N Version [$N8N_VERSION]: " input_version
  [[ -n $input_version ]] && N8N_VERSION=$input_version

  read -p "➡️  Webhook URL [$N8N_WEBHOOK_URL]: " input_webhook
  [[ -n $input_webhook ]] && N8N_WEBHOOK_URL=$input_webhook

  read -p "➡️  PostgreSQL DB Name [$DB_POSTGRESDB_DATABASE]: " input_db
  [[ -n $input_db ]] && DB_POSTGRESDB_DATABASE=$input_db

  read -p "➡️  PostgreSQL User [$DB_POSTGRESDB_USER]: " input_user
  [[ -n $input_user ]] && DB_POSTGRESDB_USER=$input_user

  read -p "➡️  PostgreSQL Password [$DB_POSTGRESDB_PASSWORD]: " input_pwd
  [[ -n $input_pwd ]] && DB_POSTGRESDB_PASSWORD=$input_pwd

  read -p "➡️  Qdrant API Key [$QDRANT_API_KEY]: " input_qdrant
  [[ -n $input_qdrant ]] && QDRANT_API_KEY=$input_qdrant

  read -p "➡️  Max execution age in hours [$EXECUTIONS_DATA_MAX_AGE]: " input_age
  [[ -n $input_age ]] && EXECUTIONS_DATA_MAX_AGE=$input_age

  read -p "➡️  Number of n8n workers [$N8N_WORKER_REPLICAS]: " input_workers
  [[ -n $input_workers ]] && N8N_WORKER_REPLICAS=$input_workers

  read -p "➡️  Enable NGINX Proxy Manager? (true/false) [$ENABLE_NGINX_PROXY_MANAGER]: " input_npm
  [[ -n $input_npm ]] && ENABLE_NGINX_PROXY_MANAGER=$input_npm

  read -p "➡️  Enable Qdrant? (true/false) [$ENABLE_QDRANT]: " input_qdrant_toggle
  [[ -n $input_qdrant_toggle ]] && ENABLE_QDRANT=$input_qdrant_toggle
}

update_env_file() {
  print_section_header "📝 Updating .env File"

  sed -i "s/^N8N_VERSION=.*/N8N_VERSION=$N8N_VERSION/" .env
  sed -i "s|^N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=$N8N_WEBHOOK_URL|" .env
  sed -i "s/^DB_POSTGRESDB_DATABASE=.*/DB_POSTGRESDB_DATABASE=$DB_POSTGRESDB_DATABASE/" .env
  sed -i "s/^DB_POSTGRESDB_USER=.*/DB_POSTGRESDB_USER=$DB_POSTGRESDB_USER/" .env
  sed -i "s/^DB_POSTGRESDB_PASSWORD=.*/DB_POSTGRESDB_PASSWORD=$DB_POSTGRESDB_PASSWORD/" .env
  sed -i "s/^QDRANT_API_KEY=.*/QDRANT_API_KEY=$QDRANT_API_KEY/" .env
  sed -i "s/^EXECUTIONS_DATA_MAX_AGE=.*/EXECUTIONS_DATA_MAX_AGE=$EXECUTIONS_DATA_MAX_AGE/" .env
  sed -i "s/^N8N_WORKER_REPLICAS=.*/N8N_WORKER_REPLICAS=$N8N_WORKER_REPLICAS/" .env
  sed -i "s/^ENABLE_NGINX_PROXY_MANAGER=.*/ENABLE_NGINX_PROXY_MANAGER=$ENABLE_NGINX_PROXY_MANAGER/" .env
  sed -i "s/^ENABLE_QDRANT=.*/ENABLE_QDRANT=$ENABLE_QDRANT/" .env

  print_success ".env updated."
}

inject_nginx_proxy_to_compose() {
  print_section_header "🌐 Handling NGINX Proxy Manager Section"

  if [[ "$ENABLE_NGINX_PROXY_MANAGER" == "true" ]]; then
    print_info "NGINX Proxy Manager is enabled. Injecting service..."

    npm_services=$(cat <<EOF
  npm_app:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    environment:
      DB_POSTGRES_HOST: 'npm_pgdb'
      DB_POSTGRES_PORT: '5432'
      DB_POSTGRES_USER: 'npm'
      DB_POSTGRES_PASSWORD: 'npmpass'
      DB_POSTGRES_NAME: 'npm'
    volumes:
      - ./npm_data:/data
      - ./letsencrypt:/etc/letsencrypt
    depends_on:
      - npm_pgdb

  npm_pgdb:
    image: postgres:latest
    environment:
      POSTGRES_USER: 'npm'
      POSTGRES_PASSWORD: 'npmpass'
      POSTGRES_DB: 'npm'
    volumes:
      - ./npm_pgdata:/var/lib/postgresql/data
EOF
)

    awk -v services="$npm_services" '
      /# === NGINX_PROXY_MANAGER_SERVICES_START ===/ {
        print;
        print services;
        skip=1
        next
      }
      /# === NGINX_PROXY_MANAGER_SERVICES_END ===/ {
        skip=0
      }
      !skip
    ' docker-compose.yml > docker-compose.tmp.yml && mv docker-compose.tmp.yml docker-compose.yml

    print_success "NGINX Proxy Manager section injected."
  else
    print_info "NGINX Proxy Manager is disabled. Removing any existing config..."
    awk '
      /# === NGINX_PROXY_MANAGER_SERVICES_START ===/ { print; skip=1; next }
      /# === NGINX_PROXY_MANAGER_SERVICES_END ===/ { skip=0 }
      !skip
    ' docker-compose.yml > docker-compose.tmp.yml && mv docker-compose.tmp.yml docker-compose.yml
    print_success "NGINX Proxy Manager section removed if it existed."
  fi
}

inject_qdrant_to_compose() {
  print_section_header "🧠 Handling Qdrant Section"

  if [[ "$ENABLE_QDRANT" == "true" ]]; then
    print_info "Qdrant is enabled. Injecting service..."

    qdrant_service=$(cat <<EOF
  qdrant:
    image: qdrant/qdrant
    hostname: qdrant
    container_name: qdrant
    networks:
      - n8n_network
    restart: unless-stopped
    ports:
      - 6333:6333
    volumes:
      - qdrant_storage:/qdrant/storage
    environment:
      - QDRANT__SERVICE__API_KEY=\${QDRANT_API_KEY}
EOF
)

    awk -v services="$qdrant_service" '
      /# === QDRANT_SERVICES_START ===/ {
        print;
        print services;
        skip=1
        next
      }
      /# === QDRANT_SERVICES_END ===/ {
        skip=0
      }
      !skip
    ' docker-compose.yml > docker-compose.tmp.yml && mv docker-compose.tmp.yml docker-compose.yml

    print_success "Qdrant section injected."
  else
    print_info "Qdrant is disabled. Removing any existing config..."
    awk '
      /# === QDRANT_SERVICES_START ===/ { print; skip=1; next }
      /# === QDRANT_SERVICES_END ===/ { skip=0 }
      !skip
    ' docker-compose.yml > docker-compose.tmp.yml && mv docker-compose.tmp.yml docker-compose.yml
    print_success "Qdrant section removed if it existed."
  fi
}

install_docker_if_needed() {
  print_section_header "🐳 Checking Docker"

  reinstall=false
  if docker --version &> /dev/null; then
    read -p "➡️  Reinstall Docker with the latest version? (y/N): " ans
    ans=${ans,,}
    [[ "$ans" == "y" ]] && reinstall=true
  else
    reinstall=true
  fi

  if $reinstall; then
    echo "🧹 Removing old Docker..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
      sudo apt-get remove -y $pkg
    done
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/keyrings/docker.asc

    echo "🔑 Adding Docker repo and installing..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    print_success "Docker installed."
  else
    print_info "Docker already present."
  fi
}

setup_docker_network() {
  print_section_header "🌐 Setting up Docker Network"
  if ! sudo docker network ls | grep -qw n8n_external; then
    sudo docker network create n8n_external
    print_success "Created Docker network n8n_external."
  else
    print_info "Docker network n8n_external already exists."
  fi
}

pull_and_build_n8n() {
  print_section_header "📦 Pull & Build n8n Image"
  docker pull n8nio/n8n:$N8N_VERSION
  DOCKER_BUILDKIT=1 docker build --pull --build-arg N8N_VERSION=$N8N_VERSION -t n8n-puppeteer:$N8N_VERSION -f Dockerfile .
  if [ $? -ne 0 ]; then
    print_warning "Build failed. Make sure Docker BuildKit is enabled."
    exit 1
  fi
  docker image prune --filter "dangling=true" -f
  print_success "n8n image built: n8n-puppeteer:$N8N_VERSION"
}

# === MAIN SCRIPT ===

load_env
configure_variables
update_env_file
inject_nginx_proxy_to_compose
inject_qdrant_to_compose
install_docker_if_needed
setup_docker_network
pull_and_build_n8n

print_success "🎉 All done! Ready to run docker compose."
