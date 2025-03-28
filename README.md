# 🚀 n8n Perfect Server Setup

Welcome to the **n8n-perfect-server** repository!  
This project helps you easily set up and run an [n8n](https://n8n.io) server — an extendable workflow automation tool — with Puppeteer integration, optimized for an Ubuntu 22.04 environment.

Get ready to harness the full power of n8n with custom automation, PDF generation, and more!

---

## 📦 Prerequisites

Before you begin, make sure you have:

- ✅ Ubuntu 22.04 LTS (server recommended)
- ✅ Basic command-line knowledge
- ✅ Git installed (`sudo apt-get install git` if not already installed)

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

To set everything up, simply run the `build.sh` script. This script will:

- Prompt you to choose the n8n version to install (e.g. `latest`, `1.39.1`, etc.)
- Ask for the **Webhook URL**, which is used for handling **webhook callbacks** (e.g. from external tools and services).
  > ⚠️ This is **not the URL of your n8n instance UI**, but the **public URL that external services will call** when they trigger webhooks in your workflows.  
  > Example: `https://webhooks.example.com`

Make the script executable and run it:

```bash
chmod +x build.sh
./build.sh
```

This will install Docker, build the n8n image, and configure everything automatically.

---

### 3. Start the n8n Server

Once the build completes, start the server with:

```bash
chmod +x run.sh
./run.sh
```

---

## 🌐 Accessing the n8n UI

After starting the server, open your browser and navigate to:

```
http://<your-server-ip>:5678
```

Replace `<your-server-ip>` with your server’s IP address or domain name.

---

## 🧪 Example: n8n Puppeteer to Gotenberg (HTML to PDF)

This is an example workflow using Puppeteer and Gotenberg for HTML to PDF conversion:

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
