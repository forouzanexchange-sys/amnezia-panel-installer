#!/usr/bin/env bash
#
# Amnezia Web Panel - One-click installer
# Tested on Ubuntu 22.04 / 24.04
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YOUR_USER/amnezia-panel-installer/main/install.sh -o install.sh
#   bash -n install.sh
#   sudo bash install.sh
#
set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo -e "\n${BLUE}${BOLD}==>${NC} ${BOLD}$*${NC}"; }

# ── 0. Sanity checks ────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || { error "Must run as root. Try: sudo bash install.sh"; exit 1; }
grep -qiE "ubuntu (22|24)" /etc/os-release 2>/dev/null || warn "Tested on Ubuntu 22.04/24.04 only. Continuing anyway."

# ── 1. Prompt for domain and password ───────────────────────────────
echo
read -rp "$(echo -e "${BOLD}Enter your domain${NC} (e.g. panel.example.com): ")" DOMAIN
DOMAIN="${DOMAIN// /}"
[[ -n "$DOMAIN" ]] || { error "Domain is required."; exit 1; }

echo
read -rsp "$(echo -e "${BOLD}Admin password${NC} (min 8 chars, leave empty to auto-generate): ")" ADMIN_PASS
echo
if [[ -z "$ADMIN_PASS" ]]; then
    ADMIN_PASS=$(openssl rand -hex 24)
    info "Auto-generated password: ${BOLD}${ADMIN_PASS}${NC}"
elif [[ ${#ADMIN_PASS} -lt 8 ]]; then
    error "Password must be at least 8 characters."; exit 1
fi

# ── 2. DNS check ────────────────────────────────────────────────────
step "Checking DNS for ${DOMAIN}"
apt-get install -y -qq dnsutils >/dev/null 2>&1 || true
SERVER_IP=$(curl -s4 --max-time 10 ifconfig.me 2>/dev/null || curl -s4 --max-time 10 icanhazip.com 2>/dev/null || echo "")
DOMAIN_IP=$(dig +short A "$DOMAIN" @1.1.1.1 2>/dev/null | head -1 || true)
if [[ -n "$SERVER_IP" && -n "$DOMAIN_IP" && "$SERVER_IP" != "$DOMAIN_IP" ]]; then
    warn "DNS mismatch: ${DOMAIN} -> ${DOMAIN_IP}, server IP -> ${SERVER_IP}"
    read -rp "Continue anyway? [y/N]: " CONT
    [[ "$CONT" =~ ^[Yy]$ ]] || { error "Aborted."; exit 1; }
else
    info "DNS check passed (${DOMAIN_IP:-unknown})."
fi

# ── 3. Base packages ────────────────────────────────────────────────
step "Installing base packages"
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    ca-certificates curl gnupg git openssl apt-transport-https lsb-release

# ── 4. Docker ───────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    step "Installing Docker"
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
        > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
        docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    info "Docker already installed."
fi

# ── 5. Caddy ────────────────────────────────────────────────────────
if ! command -v caddy &>/dev/null; then
    step "Installing Caddy"
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq debian-keyring debian-archive-keyring
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        | tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
    apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq caddy
else
    info "Caddy already installed."
fi

# ── 6. Deploy panel ─────────────────────────────────────────────────
step "Deploying Amnezia Web Panel"
INSTALL_DIR=/opt/amnezia-panel
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

PANEL_IMAGE=""
if docker pull ghcr.io/prvtpro/amnezia-panel:latest 2>/dev/null; then
    PANEL_IMAGE="ghcr.io/prvtpro/amnezia-panel:latest"
    info "Pulled prebuilt image from ghcr.io"
else
    warn "ghcr.io pull failed - building from source instead (this may take a few minutes)."
    [[ -d "$INSTALL_DIR/src" ]] || git clone --depth=1 https://github.com/PRVTPRO/Amnezia-Web-Panel.git "$INSTALL_DIR/src"
    docker build -t amnezia-panel:local "$INSTALL_DIR/src"
    PANEL_IMAGE="amnezia-panel:local"
fi

SECRET_KEY=$(openssl rand -hex 32)

cat > docker-compose.yml <<EOF
services:
  amnezia-panel:
    image: ${PANEL_IMAGE}
    container_name: amnezia-web-panel
    restart: unless-stopped
    ports:
      - "127.0.0.1:5000:5000"
    volumes:
      - ./data:/app/data
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - DATA_FILE=/app/data/data.json
EOF

docker compose up -d

step "Waiting for panel to become available..."
PANEL_READY=false
for i in $(seq 1 90); do
    if curl -sf -o /dev/null http://127.0.0.1:5000/ 2>/dev/null; then
        info "Panel is up after ${i}s."
        PANEL_READY=true
        break
    fi
    sleep 1
done
if [[ "$PANEL_READY" != "true" ]]; then
    error "Panel did not respond in 90s. Check logs:"
    error "  cd ${INSTALL_DIR} && docker compose logs"
    exit 1
fi

# ── 7. Best-effort admin password change via API ───────────────────
step "Setting admin password"
PASSWORD_SET=false
COOKIE_JAR=$(mktemp)
trap 'rm -f "$COOKIE_JAR"' EXIT

curl -s -c "$COOKIE_JAR" -o /dev/null -X POST "http://127.0.0.1:5000/api/login" \
    -H "Content-Type: application/json" \
    -d '{"username":"admin","password":"admin"}' 2>/dev/null || true

for ep in \
    "/api/users/change-password" \
    "/api/users/password" \
    "/api/me/password" \
    "/api/users/1/password"; do
    RESP=$(curl -s -b "$COOKIE_JAR" -X POST "http://127.0.0.1:5000${ep}" \
        -H "Content-Type: application/json" \
        -d "{\"current_password\":\"admin\",\"old_password\":\"admin\",\"password\":\"${ADMIN_PASS}\",\"new_password\":\"${ADMIN_PASS}\"}" 2>/dev/null || true)
    if [[ -n "$RESP" ]] && ! grep -qiE '"(error|detail|invalid|incorrect)"' <<<"$RESP"; then
        PASSWORD_SET=true
        info "Password updated successfully via ${ep}"
        break
    fi
done

if [[ "$PASSWORD_SET" != "true" ]]; then
    warn "Automatic password change is not supported by this panel version."
    warn "Default login: admin / admin - change it immediately in the Users section."
    ADMIN_PASS="admin (must be changed after first login)"
fi

# ── 8. Caddy configuration and SSL ──────────────────────────────────
step "Configuring Caddy for ${DOMAIN}"
cat > /etc/caddy/Caddyfile <<EOF
${DOMAIN} {
    encode gzip
    reverse_proxy 127.0.0.1:5000
}
EOF
systemctl enable caddy >/dev/null 2>&1 || true
systemctl restart caddy
info "Caddy restarted. SSL will be issued on first request."

# ── 9. Firewall ─────────────────────────────────────────────────────
step "Configuring firewall"
SSH_PORT=$(grep -E '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
SSH_PORT="${SSH_PORT:-22}"
if command -v ufw &>/dev/null; then
    ufw allow "${SSH_PORT}/tcp" >/dev/null 2>&1 || true
    ufw allow 80/tcp  >/dev/null 2>&1 || true
    ufw allow 443/tcp >/dev/null 2>&1 || true
    ufw --force enable >/dev/null 2>&1 || true
    info "UFW enabled. Open ports: ${SSH_PORT}, 80, 443"
else
    warn "UFW not found - firewall not configured."
fi

# ── 10. Save credentials ────────────────────────────────────────────
step "Saving credentials"
cat > "$INSTALL_DIR/credentials.txt" <<EOF
Amnezia Web Panel
=================
URL:       https://${DOMAIN}
Username:  admin
Password:  ${ADMIN_PASS}
Installed: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
EOF
chmod 600 "$INSTALL_DIR/credentials.txt"

# ── 11. Summary ─────────────────────────────────────────────────────
echo
echo -e "${GREEN}${BOLD}=========================================${NC}"
echo -e "${GREEN}${BOLD}   Installation complete!${NC}"
echo -e "${GREEN}${BOLD}=========================================${NC}"
echo
echo -e "  ${BOLD}Panel URL${NC}: https://${DOMAIN}"
echo -e "  ${BOLD}Username${NC}:  admin"
echo -e "  ${BOLD}Password${NC}:  ${ADMIN_PASS}"
echo
echo -e "  Credentials saved to: ${BOLD}${INSTALL_DIR}/credentials.txt${NC}"
echo
echo -e "  ${BOLD}Useful commands:${NC}"
echo "    cd ${INSTALL_DIR} && docker compose ps"
echo "    cd ${INSTALL_DIR} && docker compose logs -f"
echo "    cd ${INSTALL_DIR} && docker compose restart"
echo "    cd ${INSTALL_DIR} && docker compose down"
echo
