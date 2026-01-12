FROM docker.n8n.io/n8nio/n8n

USER root

# Install Chromium and dependencies (Debian base image -> use apt-get)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      chromium \
      chromium-common \
      libnss3 \
      libglib2.0-0 \
      libfreetype6 \
      libharfbuzz0b \
      ca-certificates \
      fonts-freefont-ttf \
      udev \
      fonts-liberation \
      fonts-noto-color-emoji && \
    rm -rf /var/lib/apt/lists/*

# Symlink chromium-browser for compatibility
RUN ln -sf /usr/bin/chromium /usr/bin/chromium-browser

# Tell Puppeteer to use installed Chrome instead of downloading it
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Install n8n-nodes-puppeteer in a permanent location
RUN mkdir -p /opt/n8n-custom-nodes && \
    cd /opt/n8n-custom-nodes && \
    npm install n8n-nodes-puppeteer && \
    chown -R node:node /opt/n8n-custom-nodes

# Copy our custom entrypoint
COPY docker-custom-entrypoint.sh /docker-custom-entrypoint.sh
RUN chmod +x /docker-custom-entrypoint.sh && \
    chown node:node /docker-custom-entrypoint.sh

USER node

ENTRYPOINT ["/docker-custom-entrypoint.sh"]
