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

# === Ensure .n8n directory exists ===
print_section_header "📁 Preparing .n8n Directory"
if [ ! -d ".n8n" ]; then
  mkdir .n8n
  print_info "Created .n8n directory."
else
  print_info ".n8n directory already exists."
fi

# Set permissions
sudo chmod 777 -R .n8n
print_success "Permissions set for .n8n directory."

# === Docker Compose: Run Options ===
print_section_header "🐳 Running n8n with Docker Compose"
echo -e "${YELLOW}❓ Do you want to run n8n in debug mode (foreground logs)?${RESET}"
read -p "➡️  Type 'y' for debug mode or press Enter for background: " use_debug

sudo docker compose down

if [[ "$use_debug" == "y" || "$use_debug" == "Y" ]]; then
  print_info "Starting n8n in DEBUG mode (foreground)..."
  sudo docker compose up
else
  print_info "Starting n8n in background (detached mode)..."
  sudo docker compose up -d
fi

# Final permission reset
sudo chmod 777 -R .n8n
print_success "n8n is up and running! 🎉"
