#!/bin/bash

# Load the variables from .env file
set -a  # automatically export all variables
source ./.env
set +a  # stop automatically exporting

# Check if the .n8n directory exists, create it if it doesn't
if [ ! -d ".n8n" ]; then
  mkdir .n8n
fi

# Set permissions for the .n8n directory
sudo chmod 777 -R .n8n

# Ask the user if they want to use the -d option
echo "Do you want to run this in debug mode? (y/n)"
read use_d_option

# Conditional logic based on the user's choice
if [ "$use_d_option" = "n" ]; then
  sudo docker compose down
  sudo docker compose up -d
else
  sudo docker compose down
  sudo docker compose up
fi

# Re-Set permissions
sudo chmod 777 -R .n8n
