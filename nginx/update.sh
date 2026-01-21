#!/bin/bash
set -e

cd /svr/nginx

echo "Backing up compose + configs"
tar czf backups/stack-$(date +%F).tgz docker-compose.yml nginx prometheus

echo "Pulling only pinned versions"
docker compose pull

echo "Rolling restart"
docker compose up -d --remove-orphans

echo "Health check wait"
sleep 10
docker compose ps
