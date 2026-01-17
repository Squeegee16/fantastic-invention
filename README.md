A Docker proxy for a bare metal MC server with Docker Compose stack 
(Nginx, community web UI, Plan, BlueMap, Prometheus, Grafana, Loki, node_exporter, Minecraft exporter)

Nginx config with HTTPS, HTTP/2, security headers, proxy for plugins
Certbot auto certificate issuance and renewal
UFW firewall & Fail2Ban hardening
Log rotation for Nginx and Docker
Pre-configured Prometheus & Grafana dashboards
All volumes and persistent directories


epv-docker-stack/
├── docker-compose.yml
├── deploy-epv-all-in-one.sh
├── nginx/
│   ├── epv.conf
│   └── default.conf (optional)
├── certbot/
│   ├── conf/
│   └── www/
├── prometheus/
│   ├── prometheus.yml
│   └── rules/
├── grafana/
│   └── provisioning/
│       ├── dashboards/
│       └── datasources/
└── README.md
