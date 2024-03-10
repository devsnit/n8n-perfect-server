ARG N8N_VERSION

FROM n8nio/n8n:$N8N_VERSION

RUN if [ -z "$N8N_VERSION" ] ; then echo "The N8N_VERSION argument is missing!" ; exit 1; fi

USER root

# Update and install necessary packages
RUN apk add --update graphicsmagick tzdata git tini su-exec

RUN apk update \
    && apk upgrade \
    && apk add --no-cache --update \
        nodejs \
        npm \
        chromium \
        ttf-freefont \
        yarn \
        dbus \
        ttf-freefont \
        alsa-lib \
        gtk+3.0 \
        nss \
        freetype \
        harfbuzz \
        xorg-server \
        xauth \
        xterm \
        mesa-gles \
        libstdc++ 

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser

# Install n8n-nodes-puppeteer
RUN cd /home/node/ && npm install -g puppeteer && npx puppeteer browsers install chrome && npm install socks5-http-client

USER node
