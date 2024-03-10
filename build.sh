#!/bin/bash

# Load the variables from .env file
set -a  # automatically export all variables
source ./.env
set +a  # stop automatically exporting

# Check if Docker is installed
if docker --version &> /dev/null; then
    echo "Docker is already installed."
    read -p "Do you want to reinstall Docker? (y/n) " answer
    if [[ "$answer" == [Yy]* ]]; then
        echo "Removing Docker..."
        sudo apt-get remove -y docker docker-engine docker.io containerd runc

		# Update the apt package index
		echo "Updating apt package index..."
		sudo apt-get update

		# Install packages to allow apt to use a repository over HTTPS
		echo "Installing dependencies..."
		sudo apt-get install -y ca-certificates curl gnupg lsb-release

		# Add Docker’s official GPG key
		echo "Adding Docker's GPG key..."
		sudo mkdir -p /etc/apt/keyrings
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

		# Set up the stable repository
		echo "Setting up the Docker repository..."
		echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

		# Update the apt package index again
		echo "Updating apt package index again..."
		sudo apt-get update

		# Install Docker Engine, Docker CLI, and containerd
		echo "Installing Docker Engine and containerd..."
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    fi
    # Whether reinstalled or not, no exit here, so the script continues
else
    # Docker is not installed, proceed with Docker installation
    echo "Docker is not installed. Installing Docker..."
	    
	# Update the apt package index
	echo "Updating apt package index..."
	sudo apt-get update

	# Install packages to allow apt to use a repository over HTTPS
	echo "Installing dependencies..."
	sudo apt-get install -y ca-certificates curl gnupg lsb-release

	# Add Docker’s official GPG key
	echo "Adding Docker's GPG key..."
	sudo mkdir -p /etc/apt/keyrings
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

	# Set up the stable repository
	echo "Setting up the Docker repository..."
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

	# Update the apt package index again
	echo "Updating apt package index again..."
	sudo apt-get update

	# Install Docker Engine, Docker CLI, and containerd
	echo "Installing Docker Engine and containerd..."
	sudo apt-get install -y docker-ce docker-ce-cli containerd.io

fi

# Check if the Docker network exists
if ! sudo docker network ls | grep -qw n8n_external; then
    echo "Creating Docker network 'n8n_external'..."
    sudo docker network create n8n_external
else
    echo "Docker network 'n8n_external' already exists, skipping creation."
fi

# Build custom n8n
echo "Building custom n8n..."
sudo docker build --build-arg N8N_VERSION=$N8N_VERSION -t n8n-puppeteer:$N8N_VERSION -f Dockerfile .

echo "Script completed successfully."
