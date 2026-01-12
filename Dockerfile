ARG N8N_VERSION=2.3.2

# Stage 1: Alpine builder installs Chromium and all deps (musl-compatible)
FROM alpine:3.19 AS chromium-builder
RUN apk add --no-cache \
    chromium \
    nss \
    nspr \
    alsa-lib \
    at-spi2-core \
    avahi-libs \
    cairo \
    cups-libs \
    dbus-libs \
    eudev-libs \
    expat \
    ffmpeg-libs \
    fontconfig \
    freetype \
    glib \
    harfbuzz \
    libgcc \
    libjpeg-turbo \
    libpng \
    libwebp \
    libx11 \
    libxcomposite \
    libxcursor \
    libxdamage \
    libxext \
    libxfixes \
    libxi \
    libxrandr \
    libxrender \
    libxtst \
    mesa-gbm \
    opus \
    pango \
    ttf-freefont \
    ttf-dejavu \
    ttf-liberation \
    wqy-zenhei \
    && mkdir -p /etc/chromium && echo '{}' > /etc/chromium/policies/managed/default.json

# Stage 2: n8n base (no package manager) — copy runtime from builder
FROM n8nio/n8n:${N8N_VERSION}

USER root

# Copy Chromium and full dependency tree from builder (musl -> musl)
COPY --from=chromium-builder /usr/bin/chromium-browser /usr/bin/chromium-browser
COPY --from=chromium-builder /usr/bin/chromium /usr/bin/chromium
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
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

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
