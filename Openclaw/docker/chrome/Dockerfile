# Stateful, headful Brave browser for OpenClaw (viewable via noVNC on :6080).
# Brave is Chromium-based and speaks the same DevTools protocol.
# Pin the base tag; bump deliberately.
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:99 \
    CHROME_PROFILE_DIR=/data/chrome-profile \
    CHROME_CDP_PORT=9222 \
    VNC_PORT=5900 \
    NOVNC_PORT=6080 \
    SCREEN_GEOMETRY=1440x900x24 \
    TINI_SUBREAPER=1

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xvfb \
      x11vnc \
      novnc \
      websockify \
      fonts-liberation \
      fonts-noto-color-emoji \
      ca-certificates \
      curl \
      gnupg \
      tini \
      nginx-light \
 && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" \
      > /etc/apt/sources.list.d/brave-browser-release.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends brave-browser \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --create-home --uid 1000 --shell /bin/bash chrome \
 && mkdir -p /data/chrome-profile \
 && chown -R chrome:chrome /data/chrome-profile

COPY entrypoint.sh /usr/local/bin/chrome-entrypoint.sh
RUN chmod +x /usr/local/bin/chrome-entrypoint.sh

USER chrome
WORKDIR /home/chrome
EXPOSE 9223 6080

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=5 \
  CMD curl -fsS http://127.0.0.1:9222/json/version >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/chrome-entrypoint.sh"]
