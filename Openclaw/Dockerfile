ARG OPENCLAW_BASE_IMAGE=ghcr.io/openclaw/openclaw:latest
FROM ${OPENCLAW_BASE_IMAGE}

USER root
COPY docker/openclaw-startup.sh /usr/local/bin/openclaw-startup.sh
RUN chmod +x /usr/local/bin/openclaw-startup.sh
USER node
