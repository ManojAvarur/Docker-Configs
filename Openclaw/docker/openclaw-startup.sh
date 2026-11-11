#!/usr/bin/env sh
set -eu

log() {
  printf '%s %s\n' '[openclaw-startup]' "$*"
}

fail() {
  log "$*"
  exit 1
}

is_gateway_command() {
  [ "${1:-}" = "node" ] && [ "${2:-}" = "dist/index.js" ] && [ "${3:-}" = "gateway" ] && return 0
  [ "${1:-}" = "node" ] && [ "${2:-}" = "openclaw.mjs" ] && [ "${3:-}" = "gateway" ] && return 0
  return 1
}

install_claude_cli_if_missing() {
  export PATH="/home/node/.local/bin:${PATH}"
  if command -v claude >/dev/null 2>&1; then
    log "Claude CLI already installed."
    return 0
  fi

  log "Installing Claude CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
}

require_anthropic_setup_token() {
  if [ -z "${ANTHROPIC_SETUP_TOKEN:-}" ]; then
    fail "ANTHROPIC_SETUP_TOKEN is required in .env. Container startup is blocked."
  fi
}

ensure_gateway_mode() {
  local_mode="${OPENCLAW_GATEWAY_MODE:-local}"
  log "Ensuring gateway.mode=${local_mode}..."
  node dist/index.js config set gateway.mode "${local_mode}"
}

configure_anthropic_setup_token() {
  log "Configuring Anthropic setup-token profile..."
  printf '%s\n' "${ANTHROPIC_SETUP_TOKEN}" | node dist/index.js models auth paste-token --provider anthropic --profile-id anthropic:manual
  if ! node dist/index.js models auth activate anthropic:manual; then
    log "Auth profile activation returned non-zero; continuing with saved profile."
  fi

  if [ -n "${OPENCLAW_DEFAULT_MODEL:-}" ]; then
    log "Setting default model to ${OPENCLAW_DEFAULT_MODEL}..."
    node dist/index.js models set "${OPENCLAW_DEFAULT_MODEL}"
  fi
}

configure_telegram_if_present() {
  if [ "${OPENCLAW_BOOTSTRAP_TELEGRAM:-1}" = "0" ]; then
    log "OPENCLAW_BOOTSTRAP_TELEGRAM=0, skipping Telegram bootstrap."
    return 0
  fi

  if [ -z "${TELEGRAM_BOT_TOKEN:-}" ]; then
    log "TELEGRAM_BOT_TOKEN not set, skipping Telegram bootstrap."
    return 0
  fi

  log "Ensuring Telegram channel is configured..."
  node dist/index.js channels add --channel telegram --token "${TELEGRAM_BOT_TOKEN}"
}

warn_if_claude_not_logged_in() {
  if [ -n "${ANTHROPIC_SETUP_TOKEN:-}" ]; then
    return 0
  fi

  export PATH="/home/node/.local/bin:${PATH}"
  if ! command -v claude >/dev/null 2>&1; then
    return 0
  fi

  if claude auth status --text >/dev/null 2>&1; then
    return 0
  fi

  log "Claude CLI is installed but not logged in."
  log "Run: docker compose run --rm --entrypoint /home/node/.local/bin/claude openclaw-cli auth login"
}

configure_browser_profile() {
  # Attach OpenClaw to the external stateful Chrome sidecar (compose service "chrome").
  # attachOnly: OpenClaw must not launch its own browser; the sidecar owns the profile.
  # 9223 is the nginx relay on the compose network (9222 is loopback-only inside the chrome container).
  cdp_url="${OPENCLAW_CHROME_CDP_URL:-http://chrome:9223}"
  log "Configuring browser profile 'gmail' -> ${cdp_url} (attachOnly)..."
  if ! node dist/index.js config set browser.profiles.gmail.cdpUrl "${cdp_url}"; then
    log "Could not set browser.profiles.gmail.cdpUrl; continuing."
    return 0
  fi
  if ! node dist/index.js config set browser.profiles.gmail.attachOnly true; then
    log "Could not set browser.profiles.gmail.attachOnly; continuing."
  fi
  # The SSRF guard blocks private/Docker-internal addresses by default. Allow only the
  # compose hostname of the Chrome sidecar, not private networks in general.
  if ! node dist/index.js config set browser.ssrfPolicy.allowedHostnames '["chrome"]'; then
    log "Could not set browser.ssrfPolicy.allowedHostnames; remote CDP will be blocked."
  fi
}

if is_gateway_command "$@"; then
  require_anthropic_setup_token
  ensure_gateway_mode
  install_claude_cli_if_missing
  configure_anthropic_setup_token
  configure_telegram_if_present
  configure_browser_profile
  warn_if_claude_not_logged_in
fi

exec node /app/docker-entrypoint.mjs "$@"
