#!/usr/bin/env sh
set -eu

log() { printf '%s %s\n' '[chrome]' "$*"; }

# Remove stale lock files left by an unclean shutdown so Chromium can start
# against the persistent profile volume.
rm -f "${CHROME_PROFILE_DIR}/SingletonLock" \
      "${CHROME_PROFILE_DIR}/SingletonCookie" \
      "${CHROME_PROFILE_DIR}/SingletonSocket" 2>/dev/null || true
rm -f /tmp/.X99-lock 2>/dev/null || true

log "Starting Xvfb on ${DISPLAY} (${SCREEN_GEOMETRY})..."
Xvfb "${DISPLAY}" -screen 0 "${SCREEN_GEOMETRY}" -ac +extension RANDR >/tmp/xvfb.log 2>&1 &

# Wait for the X server socket.
i=0
while [ ! -S "/tmp/.X11-unix/X${DISPLAY#:}" ] && [ "$i" -lt 50 ]; do
  i=$((i + 1)); sleep 0.2
done

log "Starting x11vnc on ${VNC_PORT} (no password, container-internal only)..."
x11vnc -display "${DISPLAY}" -forever -shared -nopw -rfbport "${VNC_PORT}" -quiet >/tmp/x11vnc.log 2>&1 &

log "Starting noVNC on ${NOVNC_PORT}..."
websockify --web /usr/share/novnc "${NOVNC_PORT}" "localhost:${VNC_PORT}" >/tmp/novnc.log 2>&1 &

# Headful Chromium ignores --remote-debugging-address and binds CDP to 127.0.0.1
# inside the container, so Docker cannot reach it. nginx relays 0.0.0.0:9223 ->
# 127.0.0.1:9222 and rewrites Host to localhost, because Chrome rejects any other
# Host header (e.g. "chrome:9223") with HTTP 500. WebSocket upgrades are passed through.
cat > /tmp/nginx-cdp.conf <<NGINX
worker_processes 1;
pid /tmp/nginx-cdp.pid;
error_log /dev/stderr warn;
events { worker_connections 256; }
http {
  access_log off;
  client_body_temp_path /tmp/nginx-body;
  proxy_temp_path /tmp/nginx-proxy;
  fastcgi_temp_path /tmp/nginx-fastcgi;
  uwsgi_temp_path /tmp/nginx-uwsgi;
  scgi_temp_path /tmp/nginx-scgi;
  map \$http_upgrade \$connection_upgrade { default upgrade; '' close; }
  server {
    listen 9223;
    # Only the OpenClaw gateway (fixed IP on the "browser" network) may use CDP.
    allow 172.28.0.3;
    deny all;
    location / {
      proxy_pass http://127.0.0.1:${CHROME_CDP_PORT};
      proxy_http_version 1.1;
      proxy_set_header Host localhost:${CHROME_CDP_PORT};
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection \$connection_upgrade;
      proxy_read_timeout 3600s;
      # /json/version returns webSocketDebuggerUrl with ws://localhost:9222, which
      # other containers cannot reach. Rewrite it to the address the caller used.
      proxy_set_header Accept-Encoding "";
      sub_filter_types application/json;
      sub_filter 'ws://localhost:${CHROME_CDP_PORT}' 'ws://chrome:9223';
      sub_filter_once off;
    }
  }
}
NGINX
log "Starting CDP relay 0.0.0.0:9223 -> 127.0.0.1:${CHROME_CDP_PORT} (nginx)..."
nginx -c /tmp/nginx-cdp.conf -g 'daemon off;' &

log "Starting Brave with profile ${CHROME_PROFILE_DIR} (CDP on ${CHROME_CDP_PORT})..."
exec brave-browser \
  --no-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --password-store=basic \
  --user-data-dir="${CHROME_PROFILE_DIR}" \
  --remote-debugging-address=0.0.0.0 \
  --remote-debugging-port="${CHROME_CDP_PORT}" \
  --remote-allow-origins=* \
  about:blank
