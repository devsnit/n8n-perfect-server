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

# === Load .env ===
print_section_header "🌍 Loading Environment Variables"
set -a
source ./.env
set +a
print_success ".env variables loaded."

# === Determine correct docker compose command ===
if docker compose version &> /dev/null; then
  COMPOSE_CMD="docker compose"
elif docker-compose version &> /dev/null; then
  COMPOSE_CMD="docker-compose"
else
  echo "❌ Neither 'docker compose' nor 'docker-compose' is available. Please install Docker Compose."
  exit 1
fi

# === Ensure .n8n directory exists ===
print_section_header "📁 Preparing .n8n Directory"
if [ ! -d ".n8n" ]; then
  mkdir .n8n
  print_info "Created .n8n directory."
else
  print_info ".n8n directory already exists."
fi

# Set ownership to node user (UID 1000) and permissions
# Directories: 755 (rwxr-xr-x), Files: 644 (rw-r--r--), Config files: 600 (rw-------)
sudo chown -R 1000:1000 .n8n 2>/dev/null || sudo chown -R $(id -u):$(id -g) .n8n 2>/dev/null || true
find .n8n -type d -exec sudo chmod 755 {} \; 2>/dev/null || true
find .n8n -type f -name "config" -exec sudo chmod 600 {} \; 2>/dev/null || true
find .n8n -type f ! -name "config" -exec sudo chmod 644 {} \; 2>/dev/null || true
print_success "Permissions and ownership set for .n8n directory."

# === Docker Compose: Run Options ===
print_section_header "🐳 Running n8n with Docker Compose"
echo -e "${YELLOW}❓ Do you want to run n8n in debug mode (foreground logs)?${RESET}"
read -p "➡️  Type 'y' for debug mode or press Enter for background: " use_debug

sudo $COMPOSE_CMD down

if [[ "$use_debug" == "y" || "$use_debug" == "Y" ]]; then
  print_info "Starting n8n in DEBUG mode (foreground)..."
  sudo $COMPOSE_CMD up
else
  print_info "Starting n8n in background (detached mode)..."
  sudo $COMPOSE_CMD up -d
fi

# Final permission reset (ownership to node user, 755 for directories, 644 for files, 600 for config files)
sudo chown -R 1000:1000 .n8n 2>/dev/null || sudo chown -R $(id -u):$(id -g) .n8n 2>/dev/null || true
find .n8n -type d -exec sudo chmod 755 {} \; 2>/dev/null || true
find .n8n -type f -name "config" -exec sudo chmod 600 {} \; 2>/dev/null || true
find .n8n -type f ! -name "config" -exec sudo chmod 644 {} \; 2>/dev/null || true
print_success "n8n is up and running! 🎉"
