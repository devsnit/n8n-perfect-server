ARG N8N_VERSION=latest

# Single-stage Debian base to avoid glibc/musl mismatches
FROM node:20-bookworm-slim

USER root

# Install Chromium and system dependencies from official Debian repos
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      chromium \
      chromium-common \
      libnss3 \
      libnspr4 \
      libglib2.0-0 \
      libatk1.0-0 \
      libatk-bridge2.0-0 \
      libcups2 \
      libdrm2 \
      libxkbcommon0 \
      libatspi2.0-0 \
      libx11-6 \
      libx11-xcb1 \
      libxcb1 \
      libxcomposite1 \
      libxcursor1 \
      libxdamage1 \
      libxi6 \
      libxtst6 \
      libxrandr2 \
      libasound2 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libgtk-3-0 \
      libxss1 \
      libxshmfence1 \
      libgbm1 \
      libxext6 \
      libxfixes3 \
      libxrender1 \
      libfontconfig1 \
      fonts-liberation \
      fonts-noto-color-emoji \
      fonts-freefont-ttf \
      fonts-dejavu-core \
      libopus0 \
      libwebp7 \
      libjpeg62-turbo \
      libpng16-16 \
      libopenjp2-7 \
      liblcms2-2 \
      libxslt1.1 \
      libdav1d6 \
      libvpx7 \
      libflac12 \
      libsndfile1 \
      libdouble-conversion3 \
      dbus-user-session \
      pulseaudio \
      udev \
      ca-certificates \
      git \
      openssh-client \
      python3 \
      python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Symlink and stub to satisfy chromium wrapper expectations
RUN ln -sf /usr/bin/chromium /usr/bin/chromium-browser && \
    mkdir -p /etc/chromium.d && echo > /etc/chromium.d/00-empty

# Install n8n (official npm) and puppeteer packages for Code node + community node
RUN npm install -g n8n@${N8N_VERSION} puppeteer@latest puppeteer-core@latest && \
    mkdir -p /opt/n8n-custom-nodes && \
    cd /opt/n8n-custom-nodes && \
    npm install puppeteer@latest puppeteer-core@latest n8n-nodes-puppeteer@latest && \
    chown -R node:node /opt/n8n-custom-nodes

# Tell Puppeteer to use the installed Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
    NODE_PATH=/opt/n8n-custom-nodes/node_modules:/usr/local/lib/node_modules

# Ensure sandbox has correct permissions (falls back to --no-sandbox if absent)
RUN if [ -f /usr/lib/chromium/chrome-sandbox ]; then chmod 4755 /usr/lib/chromium/chrome-sandbox || true; fi

# Copy our custom entrypoint
COPY docker-custom-entrypoint.sh /docker-custom-entrypoint.sh
RUN chmod +x /docker-custom-entrypoint.sh && \
    chown node:node /docker-custom-entrypoint.sh

USER node

ENTRYPOINT ["/docker-custom-entrypoint.sh"]
