# USER_DOC.md — User Documentation

## What Is This Stack?

This project runs a complete WordPress website using Docker. It provides three services working together:

| Service    | What it does                                              |
|------------|-----------------------------------------------------------|
| **NGINX**  | Handles secure HTTPS traffic on port 443 (TLS encrypted)  |
| **WordPress** | Runs the WordPress website and admin panel            |
| **MariaDB**| Stores all website content, users, and settings           |

The website is only accessible over **HTTPS** (port 443). Regular HTTP (port 80) is blocked by design.

---

## Starting the Project

### Start all services
```bash
make
```
Or with Docker Compose directly:
```bash
docker-compose -f ./srcs/docker-compose.yml up -d
```

### Verify everything is running
```bash
docker-compose -f ./srcs/docker-compose.yml ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should show status **Up**.

---

## Stopping the Project

### Stop all services (data is kept)
```bash
make down
```
Or:
```bash
docker-compose -f ./srcs/docker-compose.yml down
```

> Your website content and database are saved automatically and will still be there when you start again.

---

## Accessing the Website

### From the host machine (your main computer)
Open your browser and go to:
```
https://192.168.56.x
```
> Replace `192.168.56.x` with your VM's host-only adapter IP (found with `ip a` on the VM, under `enp0s8`).

### From inside the VM
If `login.42.fr` is added to `/etc/hosts`:
```
https://login.42.fr
```

> You will see a **security warning** in your browser because the certificate is self-signed. This is expected — click **Advanced → Proceed** to continue.

### Verify HTTPS is working
Click the **padlock icon** in your browser's address bar to view the SSL certificate details.

### Confirm HTTP is blocked
Trying to access via HTTP should fail:
```bash
curl http://192.168.56.x:80
# Expected: Connection refused
```

---

## Accessing the Administration Panel

### WordPress Admin Dashboard
```
https://192.168.56.x/wp-admin
```
Or from inside the VM:
```
https://login.42.fr/wp-admin
```

---

## Credentials

All credentials are stored in `srcs/.env`. Here is what each one is for:

### WordPress Administrator
| Field    | Value                          |
|----------|--------------------------------|
| Username | `supervisor42`                 |
| Password | `SuperPass42!`                 |
| Email    | `super@login.42.fr`            |
| Role     | Administrator (full access)    |

### WordPress Editor
| Field    | Value                          |
|----------|--------------------------------|
| Username | `editor`                       |
| Password | `EditorPass42!`                |
| Email    | `editor@login.42.fr`           |
| Role     | Editor (can write/edit posts)  |

### MariaDB (Database)
| Field         | Value (from `.env`)       |
|---------------|---------------------------|
| Root user     | `root` (no password via socket) |
| App user      | `MYSQL_USER` value        |
| App password  | `MYSQL_PASSWORD` value    |
| Database name | `MYSQL_DB` value          |

---

## Checking That Services Are Running Correctly

### 1. All containers are up
```bash
docker-compose -f ./srcs/docker-compose.yml ps
```
All three should show **Up**.

### 2. NGINX is only on port 443
```bash
docker ps | grep nginx
```
You should see `0.0.0.0:443->443/tcp` — no port 80.

### 3. SSL/TLS certificate is active
```bash
openssl s_client -connect 192.168.56.x:443
```
Look for `Protocol: TLSv1.2` or `TLSv1.3`.

### 4. WordPress is installed (not the setup wizard)
```bash
curl -k https://127.0.0.1 -H "Host: login.42.fr" | grep -i "title"
```
You should see your site title (e.g. `incep webpage`), not `WordPress Installation`.

### 5. Volumes are correctly configured
```bash
docker volume inspect mariadb
docker volume inspect wordpress
```
The `device` field should show `/home/yourlogin/data/mariadb` and `/home/yourlogin/data/wordpress`.

### 6. Docker network is active
```bash
docker network inspect inception
```
All three containers should be listed under `Containers`.

### 7. Database is not empty
```bash
docker exec -it mariadb mysql -u root
```
```sql
USE wordpress;
SHOW TABLES;
```
You should see WordPress tables like `wp_users`, `wp_posts`, `wp_comments`.

### 8. Adding a comment (as editor)
- Log in at `https://192.168.56.x/wp-admin` with the editor account
- Open any blog post
- Scroll to the comment section and post a comment
- Verify it appears on the page

### 9. Data persists after reboot
After rebooting the VM:
```bash
docker-compose -f ./srcs/docker-compose.yml up -d
```
- Website should load normally
- Admin login should still work
- Comments and content made before reboot should still be there

---

## Common Issues

### Browser shows "Connection refused" on port 80
This is correct behaviour — port 80 is intentionally blocked.

### Browser shows certificate warning
This is expected with a self-signed certificate. Click **Advanced → Proceed**.

### Cannot reach the site from main machine
- Check your VM network adapter is set to **Host-only** in VirtualBox
- Get the correct VM IP with `ip a` (look under `enp0s8`)
- Make sure containers are running with `docker-compose ps`

### WordPress shows the installation wizard
The database connection failed during setup. Run:
```bash
docker-compose -f ./srcs/docker-compose.yml down -v
sudo rm -rf /home/yourlogin/data/wordpress/*
sudo rm -rf /home/yourlogin/data/mariadb/*
docker-compose -f ./srcs/docker-compose.yml up -d --build
```
