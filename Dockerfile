FROM debian:bookworm-slim AS chromium-builder
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

FROM docker.n8n.io/n8nio/n8n

USER root

# Copy Chromium and ALL dependencies from builder into the n8n image
# (base image has no package manager, so we vendor the full tree)
COPY --from=chromium-builder /usr/bin/chromium /usr/bin/chromium
COPY --from=chromium-builder /usr/bin/chromium /usr/bin/chromium-browser
COPY --from=chromium-builder /usr/lib/ /usr/lib/
COPY --from=chromium-builder /lib/ /lib/
COPY --from=chromium-builder /usr/share/fonts/ /usr/share/fonts/
COPY --from=chromium-builder /etc/ssl/certs/ /etc/ssl/certs/
COPY --from=chromium-builder /etc/chromium/ /etc/chromium/
COPY --from=chromium-builder /etc/fonts/ /etc/fonts/

# Stub chromium.d to satisfy wrapper expectations
RUN mkdir -p /etc/chromium.d && echo > /etc/chromium.d/00-empty

# Tell Puppeteer to use the real binary (not the wrapper) and avoid downloads
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Ensure sandbox has correct permissions (falls back to --no-sandbox if absent)
RUN if [ -f /usr/lib/chromium/chrome-sandbox ]; then chmod 4755 /usr/lib/chromium/chrome-sandbox || true; fi

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
