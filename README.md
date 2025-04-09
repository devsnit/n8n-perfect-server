# 🚀 n8n Perfect Server Setup

Welcome to the **n8n-perfect-server** repository!  
This project helps you easily set up and run an [n8n](https://n8n.io) server — an extendable workflow automation tool — with Puppeteer integration, PostgreSQL, Redis, Gotenberg, and optional features like **Qdrant vector search** and **NGINX Proxy Manager**.  
It's optimized for Ubuntu 22.04 environments and uses Docker for clean, reproducible deployments.

---

## 📦 Prerequisites

Before you begin, make sure you have:

- ✅ Ubuntu 22.04 LTS (server recommended)
- ✅ Basic command-line knowledge
- ✅ Git installed (`sudo apt install git`)

---

## ⚙️ Installation

Follow the steps below to install and run your n8n instance.

### 1. Clone This Repository

```bash
git clone https://github.com/devsnit/n8n-perfect-server.git
cd n8n-perfect-server
```

---

### 2. Run the Setup Script

To start configuration and setup, run the `build.sh` script.

This script will:
- Prompt for your desired **n8n version**
- Ask for your **Webhook URL**
- Let you configure PostgreSQL settings
- Allow enabling/disabling **Qdrant** and **NGINX Proxy Manager**
- Automatically update the `.env` file
- Reinstall Docker if needed
- Create a Docker image and network
- Inject optional services into `docker-compose.yml` only if enabled

Make the script executable and run it:

```bash
chmod +x build.sh
./build.sh
```

---

### 3. Start the n8n Server

Once the build completes:

```bash
chmod +x run.sh
./run.sh
```

You will be prompted to run n8n in **debug** or **detached** mode.

---

## 🌐 Accessing n8n UI

Open your browser and go to:

```
http://<your-server-ip>:5678
```

Replace `<your-server-ip>` with your actual IP or domain.

---

## 🔐 Qdrant Vector Search (Optional)

Qdrant is an optional vector search engine injected into your server if enabled during setup.

- Access Qdrant at:
  ```
  http://<your-server-ip>:6333
  ```

- Use this header in API calls:
  ```http
  Authorization: ApiKey YOUR_API_KEY
  ```

- The API key is stored in `.env` under `QDRANT_API_KEY`.

---

## 🌐 NGINX Proxy Manager (Optional)

You can optionally enable [NGINX Proxy Manager](https://nginxproxymanager.com) via the `build.sh` prompt.

Once enabled and injected:
- UI is available at:
  ```
  http://<your-server-ip>:81
  ```

- Default credentials (change on first login):
  ```
  Email:    admin@example.com
  Password: changeme
  ```

Proxy Manager uses its own internal PostgreSQL container (`npm_pgdb`) and is entirely isolated.

---

## 🧠 Environment Configuration (`.env`)

Here are some key settings stored in `.env`:

```dotenv
# n8n Configuration
N8N_VERSION=latest
N8N_WEBHOOK_URL=https://yourdomain.com

# PostgreSQL
DB_POSTGRESDB_DATABASE=n8n_db
DB_POSTGRESDB_USER=n8n_db
DB_POSTGRESDB_PASSWORD=secret123

# Execution History
EXECUTIONS_DATA_SAVE_ON_SUCCESS=all
EXECUTIONS_DATA_SAVE_ON_ERROR=all
EXECUTIONS_DATA_SAVE_MANUAL_EXECUTIONS=true
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=720

# Workers
N8N_WORKER_REPLICAS=4

# Optional Features
ENABLE_QDRANT=true
ENABLE_NGINX_PROXY_MANAGER=true
QDRANT_API_KEY=your_secure_key_here
```

---

## 🧪 Example: n8n Puppeteer to Gotenberg (HTML to PDF)

This is an example workflow using Puppeteer and Gotenberg to convert HTML into a PDF:

```json
{
  "nodes": [
    {
      "parameters": {
        "operation": "toText",
        "sourceProperty": "html",
        "options": { "fileName": "index.html" }
      },
      "name": "convertToHTML",
      "type": "n8n-nodes-base.convertToFile",
      "typeVersion": 1,
      "position": [600, 220]
    },
    {
      "parameters": {
        "method": "POST",
        "url": "http://gotenberg:3000/forms/chromium/convert/html",
        "sendBody": true,
        "contentType": "multipart-form-data",
        "bodyParameters": {
          "parameters": [
            {
              "parameterType": "formBinaryData",
              "name": "files",
              "inputDataFieldName": "data"
            }
          ]
        }
      },
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [760, 220]
    }
  ],
  "connections": {
    "convertToHTML": {
      "main": [[ { "node": "HTTP Request", "type": "main", "index": 0 } ]]
    }
  }
}
```

---

## 🤝 Contributing

Pull requests are welcome!  
If you have improvements, ideas, or bug fixes, feel free to open an issue or contribute directly.

---

## 📄 License

**MIT License**

© 2024 [Alexandru Munteanu](https://devsnit.com/)  
Feel free to use, share, and modify this project. See `LICENSE` for details.

---

> Built with 💻 by DEVSNIT • https://devsnit.com
