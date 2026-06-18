# 🚀 WebPanel

**One-click VPS Web Management Panel** — install LAMP/LEMP/LLMP/MODERN stack + web dashboard dalam satu perintah.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)](https://www.gnu.org/software/bash/)

## 📦 Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash
```

**Pilih stack:**
```bash
# LAMP (Apache + MySQL + PHP)
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash -s -- --stack 1

# LEMP (Nginx + MySQL + PHP)  
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash -s -- --stack 2

# LLMP (OpenLiteSpeed + MariaDB + PHP)
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash -s -- --stack 3

# MODERN (Nginx + Node.js + PostgreSQL)
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash -s -- --stack 4

# Custom port
curl -fsSL https://raw.githubusercontent.com/tejok/webpanel/main/install.sh | bash -s -- --port 3000
```

## ✨ Features

- 🔧 **Auto-detect OS** — Ubuntu, Debian, CentOS, RHEL, Rocky, AlmaLinux
- 🌐 **4 Stack Options** — LAMP, LEMP, LLMP, MODERN
- 🛡️ **Auto SSL** — Let's Encrypt via Certbot
- 🔥 **Auto Firewall** — UFW/Firewalld pre-configured
- 📦 **Auto Backup** — Daily database + config backup
- 🐳 **Docker Ready** — Optional Docker installation
- 📊 **Web Dashboard** — Manage sites, databases, DNS, SSL
- 🔐 **Secure** — Random password generated, fail2ban included

## 🏗️ Supported Stacks

| Stack | Web Server | Database | PHP | Best For |
|-------|-----------|----------|-----|----------|
| LAMP | Apache | MySQL | 8.1 | WordPress, shared hosting |
| LEMP | Nginx | MySQL | 8.1 | High traffic sites |
| LLMP | OpenLiteSpeed | MariaDB | 8.1 | Speed-optimized hosting |
| MODERN | Nginx | PostgreSQL | - | Node.js apps, APIs |

## 🌐 Web Dashboard

After installation, access your dashboard at:

```
http://YOUR_VPS_IP:8080
```

**Panel features:**
- 📊 Server monitoring (CPU, RAM, Disk, Network)
- 🌐 Nginx/Apache site management
- 🗄️ Database manager (MySQL/PostgreSQL)
- 🔄 Cloudflare DNS management
- 📁 File manager via web
- 🐳 Docker container management
- 📦 Automated backups
- 🔐 SSL certificate management

## 🖥️ System Requirements

- Ubuntu 20.04+ / Debian 11+ / CentOS 8+ / RHEL 8+
- 1 GB RAM minimum (2 GB recommended)
- 10 GB disk space
- Fresh VPS recommended

## 📁 Directory Structure

```
/opt/webpanel/          # Panel installation directory
├── backups/            # Auto backups
├── .credentials        # Admin credentials (chmod 600)
├── ecosystem.config.js # PM2 process config
└── /etc/nginx/         # Nginx configs
└── /etc/apache2/       # Apache configs
```

## 🛠️ Management Commands

```bash
# Panel
pm2 status                # Check panel status
pm2 restart webpanel      # Restart panel
pm2 logs webpanel         # View logs

# Services
systemctl restart nginx
systemctl restart mysql
systemctl restart php8.1-fpm

# Backup
/opt/webpanel/backup.sh   # Manual backup
```

## 🔒 Security

- Random admin password on install
- UFW/Firewalld pre-configured (22, 80, 443, 8080)
- Fail2ban active for SSH
- Credentials stored in `/opt/webpanel/.credentials` (600)

## 📝 License

MIT © 2026 Tejok

---

**⚠️ Always use on a fresh VPS installation**
