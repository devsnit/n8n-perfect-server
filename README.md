
# n8n Perfect Server Setup

Welcome to the `n8n-perfect-server` repository! This project is designed to help you set up and run an n8n server, an extendable workflow automation tool, on an Ubuntu 22 server environment. Follow the instructions below to get started.

## Prerequisites

Before you begin, ensure that you have:

- A machine running Ubuntu 22 (server edition recommended).
- Basic knowledge of terminal and command-line operations.
- Git installed on your machine. If not, you can install it using `sudo apt-get install git`.

## Installation

To set up the n8n server, follow these steps:

### 1. Clone the Repository

First, clone this repository to your local machine. Open your terminal and run the following command:

```bash
git clone https://github.com/devsnit/n8n-perfect-server.git
```

Navigate into the project directory:

```bash
cd n8n-perfect-server
```

### 2. Configure Environment Variables

Before running the build script, you need to configure the environment variables in the `.env` file. Update the `N8N_VERSION` to `latest` to use the latest version of n8n. For the `N8N_WEBHOOK_URL`, use your hostname without the `http://` part. This setup is crucial for the correct operation of your n8n instance.

### 3. Run Build Script

Before starting the server, you need to run the build script. This script prepares your server environment for n8n. Make sure the script is executable; if not, you can make it executable by running:

```bash
chmod +x build.sh
```

After ensuring it is executable, run the build script:

```bash
./build.sh
```

### 4. Run the Server

Once the build process is complete, start the n8n server by executing the run script. Again, ensure the script is executable:

```bash
chmod +x run.sh
```

Then, start the server:

```bash
./run.sh
```

## Usage

After running the `run.sh` script, your n8n server will be up and running. You can access the n8n web interface by navigating to `http://localhost:5678` on your web browser (replace `localhost` with your server's IP address if accessing from a different machine).

## Contributing

Contributions to the `n8n-perfect-server` project are welcome! If you have suggestions, improvements, or bug reports, please feel free to open an issue or submit a pull request.

## License

[Insert your chosen license here]

