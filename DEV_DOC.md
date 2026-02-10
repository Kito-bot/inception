# DEV_DOC.md — Developer Documentation

## Overview

This project sets up a WordPress stack using Docker Compose, consisting of three services: **NGINX** (reverse proxy with SSL/TLS), **WordPress** (with PHP-FPM), and **MariaDB** (database). All services communicate over an internal Docker network called `inception`.

---

## Architecture

```
[Browser] → HTTPS:443 → [NGINX] → [WordPress:9000] → [MariaDB:3306]
```

- **NGINX**: Only entry point from the outside, listens on port 443 (TLS only)
- **WordPress**: Runs PHP-FPM on port 9000, not exposed to the host
- **MariaDB**: Database on port 3306, not exposed to the host
- **Network**: All containers communicate on the `inception` bridge network
- **Volumes**: Data persists at `/home/yourlogin/data/mariadb` and `/home/yourlogin/data/wordpress`

---

## Prerequisites

- Docker and Docker Compose installed
- Make installed
- A Debian-based Linux system (or VM)
- The following directory structure must exist before launching:

```bash
sudo mkdir -p /home/yourlogin/data/mariadb
sudo mkdir -p /home/yourlogin/data/wordpress
```

> Replace `yourlogin` with your actual system username (`whoami`).

---

## Project Structure

```
.
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   └── conf/
        ├── wordpress/
        │   ├── Dockerfile
        │   └── conf/
        │       └── wp_conf.sh
        └── mariadb/
            ├── Dockerfile
            └── conf/
                └── mdb_conf.sh
```

---

## Configuration Files & Secrets

All environment variables are stored in `srcs/.env`. This file must exist before building.

### Required variables in `.env`:

```env
# Domain
DOMAIN_NAME=login.42.fr

# MariaDB
MYSQL_DB=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword
MYSQL_ROOT_PASSWORD=rootpassword

# WordPress Admin (super admin)
WP_ADMIN_N=supervisor42
WP_ADMIN_P=SuperPass42!
WP_ADMIN_E=super@login.42.fr
WP_TITLE=My WordPress Site

# WordPress Extra User
WP_U_NAME=editor
WP_U_PASS=EditorPass42!
WP_U_ROLE=editor
WP_U_EMAIL=editor@login.42.fr
```

> **Security note**: Never commit `.env` to version control.

---

## SSL/TLS Certificate

NGINX uses a self-signed certificate located inside the NGINX container. The certificate and key are referenced in the NGINX config as `incept.crt` and `incept.key`. TLS v1.2 and v1.3 are enforced via:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_certificate /path/to/incept.crt;
ssl_certificate_key /path/to/incept.key;
```

---

## Build & Launch

### Using the Makefile

```bash
# Build and start all containers
make

# Stop and remove containers
make down

# Full clean (containers + volumes + data)
make fclean

# Rebuild from scratch
make re
```

### Using Docker Compose directly

```bash
# Build and start
docker-compose -f ./srcs/docker-compose.yml up -d --build

# Stop
docker-compose -f ./srcs/docker-compose.yml down

# Stop and remove volumes
docker-compose -f ./srcs/docker-compose.yml down -v
```

---

## Managing Containers

### Check container status
```bash
docker-compose -f ./srcs/docker-compose.yml ps
```

### View logs
```bash
# All containers
docker-compose -f ./srcs/docker-compose.yml logs

# Specific container
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Access a container shell
```bash
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash
```

### Restart a specific container
```bash
docker-compose -f ./srcs/docker-compose.yml restart nginx
```

---

## Managing Volumes

### List volumes
```bash
docker volume ls
```

### Inspect a volume (verify path)
```bash
docker volume inspect mariadb
docker volume inspect wordpress
```

The `device` field should show `/home/yourlogin/data/mariadb` and `/home/yourlogin/data/wordpress`.

### Clear volume data (full reset)
```bash
docker-compose -f ./srcs/docker-compose.yml down -v
sudo rm -rf /home/yourlogin/data/wordpress/*
sudo rm -rf /home/yourlogin/data/mariadb/*
```

---

## Data Persistence

Data is stored on the **host machine** using bind mounts, not inside containers.

| Service   | Host Path                        | Container Path        |
|-----------|----------------------------------|-----------------------|
| MariaDB   | `/home/yourlogin/data/mariadb`   | `/var/lib/mysql`      |
| WordPress | `/home/yourlogin/data/wordpress` | `/var/www/wordpress`  |

This means:
- Data **survives container restarts and rebuilds**
- To fully reset, you must manually delete the host directories
- After a VM reboot, simply run `docker-compose up -d` — no rebuild needed

---

## Network

All containers are on the `inception` bridge network.

```bash
# List networks
docker network ls

# Inspect the inception network
docker network inspect inception
```

All three containers (`nginx`, `wordpress`, `mariadb`) should appear under `Containers` in the inspect output.

---

## Troubleshooting

### WordPress shows installation page
MariaDB was not ready when WordPress started. Fix:
```bash
docker-compose -f ./srcs/docker-compose.yml down -v
sudo rm -rf /home/yourlogin/data/wordpress/*
sudo rm -rf /home/yourlogin/data/mariadb/*
docker-compose -f ./srcs/docker-compose.yml up -d --build
```

### Cannot connect to MariaDB
Check that the user was created properly:
```bash
docker exec -it mariadb mysql -u root
```
```sql
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'wpuser'@'%';
```

### Port 443 not reachable from host machine
- Ensure your VM network adapter is set to **Host-only** or **Bridged** in VirtualBox
- Check the VM IP with `ip a` and use the `enp0s8` interface IP (Host-only: `192.168.56.x`)

### Volume mountpoint on /var instead of /home
Old volumes are being reused. Run `docker-compose down -v` to remove them, then rebuild.
