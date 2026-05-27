# GraceTech Development

## First Time Installation

- cp env.example .env
- (edit .env, update `PUBLIC_URL`)
- ./gen-passwords.sh
- mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
- docker image prune -a -f && docker system prune -a -f && make all
- docker compose down && service docker restart && docker compose up -d
- docker compose logs -t -f --no-color prosody > /var/www/html/files/jitsi.log &

## Rebuild web changes

- FORCE_REBUILD=1 make build_web && docker compose up -d --force-recreate web && docker compose logs -f web

## Rebuild prosody changes

- FORCE_REBUILD=1 make build_prosody && docker compose up -d --force-recreate prosody && docker compose logs -f prosody

# Firewall set up

- Docker network overrides `ufw`, so we will reply on `iptables`
- Only allow Grafana server (147.93.112.60) to collect JVB metrics via tcp port 8080
- Only allow other JVB servers (104.194.86.98) to connect to Prosody via tcp port 5222

```
sudo iptables -F DOCKER-USER

sudo iptables -I DOCKER-USER 1 -p tcp -s 147.93.112.60 --dport 8080 -j ACCEPT
sudo iptables -A DOCKER-USER -p tcp --dport 8080 -j DROP

sudo iptables -I DOCKER-USER 1 -p tcp -s 104.194.86.98 --dport 5222 -j ACCEPT
sudo iptables -A DOCKER-USER -p tcp --dport 5222 -j DROP

sudo iptables -nvL DOCKER-USER
```

Make sure you see this

```
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     6    --  *      *       104.194.86.98        0.0.0.0/0            tcp dpt:5222
    0     0 ACCEPT     6    --  *      *       147.93.112.60        0.0.0.0/0            tcp dpt:8080
    0     0 DROP       6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8080
    0     0 DROP       6    --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:5222
```

If the server is JVB only, you only need to run this

```
sudo iptables -F DOCKER-USER

sudo iptables -I DOCKER-USER 1 -p tcp -s 147.93.112.60 --dport 8080 -j ACCEPT
sudo iptables -A DOCKER-USER -p tcp --dport 8080 -j DROP

sudo iptables -nvL DOCKER-USER
```

### More SSH protection

```
sudo apt update
sudo apt install fail2ban -y

sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[DEFAULT]
bantime = 1w
findtime = 10m
maxretry = 4
backend = systemd
ignoreip = 127.0.0.1/8

[sshd]
enabled = true
port = ssh
logpath = to be ignored
filter = sshd
banaction = ufw
EOF

sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
sudo systemctl status fail2ban

sudo fail2ban-client status sshd
sudo fail2ban-client status
```
