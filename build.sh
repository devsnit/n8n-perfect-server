#!/bin/bash

# === Color codes ===
BOLD="\e[1m"
RESET="\e[0m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
GRAY="\e[90m"

# === Section Header ===
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
    echo -e "${YELLOW}❌ .env file not found. Please create one with N8N_VERSION and N8N_WEBHOOK_URL.${RESET}"
    exit 1
fi

# === Section: Configuration Setup ===
print_section_header "🛠️  Configuration Setup"

echo -e "📌 ${BOLD}Current N8N Version:${RESET} ${GREEN}$N8N_VERSION${RESET}"
read -p "➡️  Press Enter to keep '$N8N_VERSION' or type a version (e.g. 1.39.1 or 'latest'): " input_version
if [ ! -z "$input_version" ]; then
    N8N_VERSION=$input_version
fi

echo ""
echo -e "🌐 ${BOLD}Current Webhook URL:${RESET} ${GREEN}$N8N_WEBHOOK_URL${RESET}"
read -p "➡️  Press Enter to keep the current one or enter a new URL: " input_host
if [ ! -z "$input_host" ]; then
    N8N_WEBHOOK_URL=$input_host
fi

# Update .env
echo ""
echo -e "${BLUE}📝 Updating .env file...${RESET}"
sed -i "s/^N8N_VERSION=.*/N8N_VERSION=$N8N_VERSION/" .env
sed -i "s|^N8N_WEBHOOK_URL=.*|N8N_WEBHOOK_URL=$N8N_WEBHOOK_URL|" .env
echo -e "${GREEN}✅ .env file updated.${RESET}"

# === Section: Docker Installation ===
print_section_header "🐳 Docker Installation (Official & Clean)"

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

    echo "🧼 Cleaning up conflicting Docker sources (if any)..."
    [ -f /etc/apt/sources.list.d/docker.list ] && sudo rm /etc/apt/sources.list.d/docker.list
    [ -f /etc/apt/keyrings/docker.asc ] && sudo rm /etc/apt/keyrings/docker.asc
    [ -f /etc/apt/keyrings/plesk-ext-docker.gpg ] && sudo rm /etc/apt/keyrings/plesk-ext-docker.gpg
    sudo rm -rf ~/.docker/cli-plugins /root/.docker/cli-plugins

    echo "🔑 Importing Docker GPG key..."
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8

    echo "➕ Adding Docker APT repo..."
    echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu noble stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "🔄 Updating APT index..."
    sudo apt-get update

    echo "🚀 Installing Docker Engine and plugins..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo -e "${GREEN}✅ Docker and plugins installed successfully!${RESET}"
fi

# === Section: Docker Network ===
print_section_header "🌐 Docker Network Setup"

if ! sudo docker network ls | grep -qw n8n_external; then
    echo "➕ Creating Docker network 'n8n_external'..."
    sudo docker network create n8n_external
else
    echo -e "${GREEN}✅ Docker network 'n8n_external' already exists.${RESET}"
fi

# === Section: Pull Latest Base Image ===
print_section_header "📥 Pulling Latest Base Image"

echo -e "${BLUE}📦 Pulling base image n8nio/n8n:$N8N_VERSION...${RESET}"
docker pull n8nio/n8n:$N8N_VERSION

# === Section: Build Docker Image ===
print_section_header "🛠️  Build Custom n8n Image"

echo -e "${BLUE}⏳ Building with BuildKit and forced base image pull...${RESET}"
DOCKER_BUILDKIT=1 docker build --pull --build-arg N8N_VERSION=$N8N_VERSION -t n8n-puppeteer:$N8N_VERSION -f Dockerfile .

if [ $? -ne 0 ]; then
    echo -e "\n${YELLOW}❌ Build failed. Please ensure Docker BuildKit is supported on your system.${RESET}"
    exit 1
fi

# === Section: Cleanup ===
print_section_header "🧹 Cleaning Up Unused Docker Images"

echo -e "${BLUE}🗑️ Pruning unused Docker images (dangling only)...${RESET}"
docker image prune --filter "dangling=true" -f

echo ""
echo -e "${GREEN}✅ All done! n8n version ${BOLD}$N8N_VERSION${RESET}${GREEN} is ready to go 🚀${RESET}"
