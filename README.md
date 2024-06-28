
# n8n Perfect Server Setup

Welcome to the n8n-perfect-server repository! This project is designed to help you set up and run an n8n server, an extendable workflow automation tool, on an Ubuntu 22 server environment. Our setup includes integration with Puppeteer and Gotenberg (an HTML to PDF API).

Follow the instructions below to get started and harness the full power of n8n with enhanced capabilities.

## Prerequisites

Before you begin, ensure that you have:

- A machine running Ubuntu 22 (server edition recommended).
- Basic knowledge of terminal and command-line operations.
- Git installed on your machine. If not, you can install it using sudo apt-get install git.

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

Before running the build script, you need to configure the environment variables in the .env file. Update the N8N_VERSION to latest to use the latest version of n8n. For the N8N_WEBHOOK_URL, use your hostname without the http:// prefix.

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

After running the run.sh script, your n8n server will be up and running. You can access the n8n web interface by navigating to http://localhost:5678 on your web browser (replace localhost with your server's IP address if accessing remotely).

## N8N DEMO NODES FOR GOTENBERG:

```json
{
  "meta": {
    "templateCredsSetupCompleted": true,
    "instanceId": "1e3fd810253bd4f201696deceaaa9dd99e894764e45070b3e7382ec61e702ba2"
  },
  "nodes": [
    {
      "parameters": {
        "operation": "toText",
        "sourceProperty": "html",
        "options": {
          "fileName": "index.html"
        }
      },
      "id": "98edce69-a2a7-4f04-8f67-35c43aa14c55",
      "name": "convertToHTML",
      "type": "n8n-nodes-base.convertToFile",
      "typeVersion": 1.1,
      "position": [
        600,
        220
      ]
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
        },
        "options": {}
      },
      "id": "ba4bda33-b549-480d-b8d8-d1d10885c9e8",
      "name": "HTTP Request",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 3,
      "position": [
        760,
        220
      ]
    }
  ],
  "connections": {
    "convertToHTML": {
      "main": [
        [
          {
            "node": "HTTP Request",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "pinData": {}
}
```

## Contributing

Contributions to the n8n-perfect-server project are welcome! If you have suggestions, improvements, or bug reports, please feel free to open an issue or submit a pull request.

## License

MIT License

Copyright (c) 2024 Alexandru Munteanu ([DEVSNIT](https://devsnit.com/))

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
