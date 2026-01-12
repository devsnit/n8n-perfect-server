ARG N8N_VERSION=2.3.2

# Stage 1: Debian builder installs Chromium and all deps
FROM debian:bookworm-slim AS chromium-builder
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
      libflac8 \
      libsndfile1 \
      libdouble-conversion3 \
      dbus-user-session \
      pulseaudio \
      udev \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Stage 2: n8n base (no package manager) — copy runtime from builder
FROM n8nio/n8n:${N8N_VERSION}

USER root

# Copy Chromium and full dependency tree from builder
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
