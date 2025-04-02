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

# === Load .env ===
if [ -f .env ]; then
    set -a
    source ./.env
    set +a
else
    echo -e "${YELLOW}❌ .env file not found. Please create one with required variables.${RESET}"
    exit 1
fi

# === Section: Configuration Setup ===
print_section_header "🛠️  Configuration Setup"

echo -e "📌 ${BOLD}Current N8N Version:${RESET} ${GREEN}$N8N_VERSION${RESET}"
read -p "➡️  Press Enter to keep or type a new version: " input_version
if [ ! -z "$input_version" ]; then
    N8N_VERSION=$input_version
fi

echo ""
echo -e "🌐 ${BOLD}Current Webhook URL:${RESET} ${GREEN}$N8N_WEBHOOK_URL${RESET}"
read -p "➡️  Press Enter to keep or enter a new Webhook URL: " input_host
if [ ! -z "$input_host" ]; then
    N8N_WEBHOOK_URL=$input_host
fi

echo ""
echo -e "🗃️  ${BOLD}PostgreSQL Database:${RESET} ${GREEN}$DB_POSTGRESDB_DATABASE${RESET}"
read -p "➡️  Press Enter to keep or enter a new database name: " input_db_name
if [ ! -z "$input_db_name" ]; then
    DB_POSTGRESDB_DATABASE=$input_db_name
fi

echo ""
echo -e "👤 ${BOLD}PostgreSQL Username:${RESET} ${GREEN}$DB_POSTGRESDB_USER${RESET}"
read -p "➡️  Press Enter to keep or enter a new username: " input_db_user
if [ ! -z "$input_db_user" ]; then
    DB_POSTGRESDB_USER=$input_db_user
fi

echo ""
echo -e "🔒 ${BOLD}PostgreSQL Password:${RESET} ${GREEN}$DB_POSTGRESDB_PASSWORD${RESET}"
read -p "➡️  Press Enter to keep or enter a new password: " input_db_password
if [ ! -z "$input_db_password" ]; then
    DB_POSTGRESDB_PASSWORD=$input_db_password
fi

echo ""
echo -e "🔐 ${BOLD}Qdrant API Key:${RESET} ${GREEN}$QDRANT_API_KEY${RESET}"
read -p "➡️  Press Enter to keep or enter a new API key: " input_qdrant_api_key
if [ ! -z "$input_qdrant_api_key" ]; then
    QDRANT_API_KEY=$input_qdrant_api_key
fi

# === Update .env ===
print_section_header "📝 Updating .env File"

sed -i "s/^N8N_VERSION=.*/N8N_VERSION=$N8N_VERSION/" .env
sed -i "s|^N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=$N8N_WEBHOOK_URL|" .env
sed -i "s/^DB_POSTGRESDB_DATABASE=.*/DB_POSTGRESDB_DATABASE=$DB_POSTGRESDB_DATABASE/" .env
sed -i "s/^DB_POSTGRESDB_USER=.*/DB_POSTGRESDB_USER=$DB_POSTGRESDB_USER/" .env
sed -i "s/^DB_POSTGRESDB_PASSWORD=.*/DB_POSTGRESDB_PASSWORD=$DB_POSTGRESDB_PASSWORD/" .env
sed -i "s/^QDRANT_API_KEY=.*/QDRANT_API_KEY=$QDRANT_API_KEY/" .env

echo -e "${GREEN}✅ .env file updated successfully.${RESET}"

# === Docker Installation ===
print_section_header "🐳 Docker Installation (Optional)"

reinstall=false
if docker --version &> /dev/null; then
    echo -e "✔️  Docker is already installed."
    read -p "➡️  Do you want to reinstall Docker with the latest official setup? (y/N): " answer
    answer=${answer,,}
    if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
        reinstall=true
    fi
else
    reinstall=true
fi

if [ "$reinstall" = true ]; then
    echo "🧹 Removing old Docker packages..."
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
        sudo apt-get remove -y $pkg 
    done

    echo "🧼 Cleaning up old Docker sources..."
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/keyrings/docker.asc
    sudo rm -f /etc/apt/keyrings/plesk-ext-docker.gpg
    sudo rm -rf ~/.docker/cli-plugins /root/.docker/cli-plugins

    echo "🔑 Importing Docker GPG key..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8

    echo "➕ Adding Docker APT repository..."
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "🔄 Updating package index..."
    sudo apt-get update

    echo "🚀 Installing Docker Engine and plugins..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${GREEN}✅ Docker installed successfully.${RESET}"
fi

# === Docker Network ===
print_section_header "🌐 Docker Network Setup"

if ! sudo docker network ls | grep -qw n8n_external; then
    echo "➕ Creating Docker network 'n8n_external'..."
    sudo docker network create n8n_external
else
    echo -e "${GREEN}✅ Docker network 'n8n_external' already exists.${RESET}"
fi

# === Pull Base Image ===
print_section_header "📥 Pulling Base Image"

echo -e "${BLUE}📦 Pulling n8nio/n8n:$N8N_VERSION...${RESET}"
docker pull n8nio/n8n:$N8N_VERSION

# === Build Custom Image ===
print_section_header "🛠️  Building Custom n8n Docker Image"

DOCKER_BUILDKIT=1 docker build --pull --build-arg N8N_VERSION=$N8N_VERSION -t n8n-puppeteer:$N8N_VERSION -f Dockerfile .

if [ $? -ne 0 ]; then
    echo -e "\n${YELLOW}❌ Build failed. Please ensure Docker BuildKit is supported.${RESET}"
    exit 1
fi

# === Cleanup ===
print_section_header "🧹 Cleaning Up Unused Docker Images"

docker image prune --filter "dangling=true" -f

echo ""
echo -e "${GREEN}✅ All done! n8n version ${BOLD}$N8N_VERSION${RESET}${GREEN} is ready to go 🚀${RESET}"
