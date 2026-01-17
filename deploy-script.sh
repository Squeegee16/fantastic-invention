#!/bin/bash
set -e

TARBALL="epv-docker-stack.tar.gz"
DEPLOY_DIR="/opt/epv-docker-stack"
DOMAIN="epv.onthewifi.com"
EMAIL="your-email@example.com"  # <-- replace with your email

echo "=== EPV All-in-One Deployment & Hardening ==="

# Extract tarball
[ ! -d "$DEPLOY_DIR" ] && mkdir -p "$DEPLOY_DIR" && tar xzvf "$TARBALL" -C /opt || echo "[i] Skipping extraction"

cd "$DEPLOY_DIR"

# Persistent directories
mkdir -p certbot/conf certbot/www /var/log/nginx
chmod -R 755 certbot/www /var/log/nginx

# Start stack (HTTP first for Certbot)
docker compose up -d
sleep 5

# Initial certificate
if [ ! -f "certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    docker run --rm \
      -v "$(pwd)/certbot/conf:/etc/letsencrypt" \
      -v "$(pwd)/certbot/www:/var/www/certbot" \
      certbot/certbot certonly --webroot \
      -w /var/www/certbot \
      --email "$EMAIL" --agree-tos --no-eff-email \
      -d "$DOMAIN"
fi

# Restart stack (HTTPS now works)
docker compose down
docker compose up -d

# UFW firewall
sudo apt update && sudo apt install -y ufw
sudo ufw reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 25565/tcp
sudo ufw allow 8804/tcp
sudo ufw allow 8086/tcp
sudo ufw --force enable

# Fail2Ban
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.local > /dev/null <<EOL
[DEFAULT]
bantime  = 1h
findtime  = 10m
maxretry = 5
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 5

[nginx-http-auth]
enabled = true
logpath = /var/log/nginx/error.log
maxretry = 3

[nginx-badbot]
enabled = true
port = http,https
filter = nginx-badbot
logpath = /var/log/nginx/access.log
maxretry = 2
EOL

sudo tee /etc/fail2ban/filter.d/nginx-badbot.conf > /dev/null <<EOL
[Definition]
failregex = <HOST> -.*"(GET|POST).*HTTP.*"(?:400|403|404|408|499)"
ignoreregex =
EOL

sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# Logrotate for Nginx
sudo tee /etc/logrotate.d/nginx > /dev/null <<EOL
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 root adm
    sharedscripts
    postrotate
        [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
    endscript
}
EOL

# Display status
docker compose ps
sudo fail2ban-client status

echo "[+] Deployment complete! Access:"
echo " - Minecraft Web UI: https://$DOMAIN/"
echo " - Plan UI:          https://$DOMAIN/plan/"
echo " - BlueMap UI:       https://$DOMAIN/bluemap/"
echo " - Grafana:          http://$(hostname -I | awk '{print $1}'):3000"
echo " - Prometheus:       http://$(hostname -I | awk '{print $1}'):9090"
echo " - Loki:             http://$(hostname -I | awk '{print $1}'):3100"
