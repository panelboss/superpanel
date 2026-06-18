#!/bin/bash
#==========================================================================
#  WebPanel - One-click VPS Web Management Panel Installer
#  Supports: LAMP, LEMP, LLMP, Modern Stack
#  Version: 1.0.0
#==========================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Config
PANEL_DIR="/opt/webpanel"
PANEL_PORT="8080"
PANEL_USER="admin"
PANEL_PASS=$(openssl rand -base64 12 2>/dev/null || head -c 12 /dev/urandom | base64)
LOG_FILE="/tmp/webpanel-install.log"
GITHUB_REPO="https://github.com/panelboss/superpanel"

#==========================================================================
#  UTILS
#==========================================================================

logo() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║       🚀  WEBPANEL INSTALLER  🚀            ║"
    echo "║       One-Click Server Manager               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log()  { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[✗] $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1" | tee -a "$LOG_FILE"; }

spinner() {
    local pid=$1 msg=$2
    local spin='-\|/'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[%c]${NC} %s" "${spin:i++%4:1}" "$msg"
        sleep 0.1
    done
    printf "\r"
    wait "$pid"
    return $?
}

#==========================================================================
#  DETECT OS
#==========================================================================

detect_os() {
    info "Detecting OS..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="rhel"
    else
        err "Unsupported OS"
    fi

    case "$OS" in
        ubuntu|debian) PKG_MGR="apt-get" ;;
        centos|rhel|fedora|rocky|almalinux) PKG_MGR="yum" ;;
        *) err "Unsupported OS: $OS" ;;
    esac

    log "OS: $OS $VERSION ($PKG_MGR)"
}

#==========================================================================
#  INSTALL DEPENDENCIES
#==========================================================================

install_deps() {
    info "Installing base dependencies..."
    
    case $PKG_MGR in
        apt-get)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq >> "$LOG_FILE" 2>&1
            apt-get install -y -qq curl wget git unzip tar \
                software-properties-common gnupg ca-certificates \
                openssl ufw fail2ban >> "$LOG_FILE" 2>&1 &
            ;;
        yum)
            yum install -y -q epel-release >> "$LOG_FILE" 2>&1
            yum install -y -q curl wget git unzip tar \
                openssl firewalld fail2ban >> "$LOG_FILE" 2>&1 &
            ;;
    esac
    spinner $! "Installing dependencies..."
    log "Base dependencies installed"
}

#==========================================================================
#  STACK SELECTION
#==========================================================================

select_stack() {
    echo ""
    echo -e "${BOLD}Select your stack:${NC}"
    echo ""
    echo "  1) LAMP  - Apache + MySQL + PHP"
    echo "  2) LEMP  - Nginx + MySQL + PHP"
    echo "  3) LLMP  - OpenLiteSpeed + MariaDB + PHP"
    echo "  4) MODERN - Nginx + Node.js + PostgreSQL"
    echo ""

    if [ -n "$STACK" ]; then
        STACK_CHOICE=$STACK
        info "Using preset stack: $STACK_CHOICE"
    else
        read -p "Enter choice [1-4]: " STACK_CHOICE
    fi

    case $STACK_CHOICE in
        1) STACK_NAME="LAMP"; WEBSERVER="apache2"; DB_SERVER="mysql"; PHP_VERSION="8.1" ;;
        2) STACK_NAME="LEMP"; WEBSERVER="nginx"; DB_SERVER="mysql"; PHP_VERSION="8.1" ;;
        3) STACK_NAME="LLMP"; WEBSERVER="openlitespeed"; DB_SERVER="mariadb"; PHP_VERSION="8.1" ;;
        4) STACK_NAME="MODERN"; WEBSERVER="nginx"; DB_SERVER="postgresql"; PHP_VERSION="none" ;;
        *) err "Invalid choice" ;;
    esac

    log "Selected stack: $STACK_NAME"
}

#==========================================================================
#  INSTALL WEB SERVER
#==========================================================================

install_webserver() {
    info "Installing $WEBSERVER..."

    case $WEBSERVER in
        nginx)
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq nginx >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q nginx >> "$LOG_FILE" 2>&1 &
                    ;;
            esac
            spinner $! "Installing Nginx..."
            systemctl enable nginx --now
            ;;
        apache2)
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq apache2 >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q httpd >> "$LOG_FILE" 2>&1 &
                    WEBSERVER="httpd"
                    ;;
            esac
            spinner $! "Installing Apache..."
            systemctl enable $WEBSERVER --now
            ;;
        openlitespeed)
            wget -O - https://repo.litespeed.sh | bash >> "$LOG_FILE" 2>&1
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq openlitespeed >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q openlitespeed >> "$LOG_FILE" 2>&1 &
                    ;;
            esac
            spinner $! "Installing OpenLiteSpeed..."
            /usr/local/lsws/bin/lshttpd -v
            ;;
    esac

    log "$WEBSERVER installed"
}

#==========================================================================
#  INSTALL DATABASE
#==========================================================================

install_database() {
    info "Installing $DB_SERVER..."

    case $DB_SERVER in
        mysql)
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq mysql-server >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q mysql-server >> "$LOG_FILE" 2>&1 &
                    ;;
            esac
            spinner $! "Installing MySQL..."
            systemctl enable mysql --now
            ;;
        mariadb)
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq mariadb-server >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q mariadb-server >> "$LOG_FILE" 2>&1 &
                    ;;
            esac
            spinner $! "Installing MariaDB..."
            systemctl enable mariadb --now
            ;;
        postgresql)
            case $PKG_MGR in
                apt-get)
                    apt-get install -y -qq postgresql postgresql-contrib >> "$LOG_FILE" 2>&1 &
                    ;;
                yum)
                    yum install -y -q postgresql-server >> "$LOG_FILE" 2>&1 &
                    ;;
            esac
            spinner $! "Installing PostgreSQL..."
            systemctl enable postgresql --now
            ;;
    esac

    log "$DB_SERVER installed"
}

#==========================================================================
#  INSTALL PHP (if needed)
#==========================================================================

install_php() {
    if [ "$PHP_VERSION" = "none" ]; then
        info "Skipping PHP (Modern Stack)"
        return
    fi

    info "Installing PHP $PHP_VERSION..."

    case $PKG_MGR in
        apt-get)
            add-apt-repository -y ppa:ondrej/php >> "$LOG_FILE" 2>&1
            apt-get update -qq >> "$LOG_FILE" 2>&1
            apt-get install -y -qq php${PHP_VERSION} php${PHP_VERSION}-fpm \
                php${PHP_VERSION}-mysql php${PHP_VERSION}-curl php${PHP_VERSION}-json \
                php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip \
                php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-bcmath \
                >> "$LOG_FILE" 2>&1 &
            ;;
        yum)
            yum install -y -q https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> "$LOG_FILE" 2>&1
            yum module enable -y php:remi-${PHP_VERSION} >> "$LOG_FILE" 2>&1
            yum install -y -q php php-fpm php-mysqlnd php-curl php-json \
                php-mbstring php-xml php-zip php-gd >> "$LOG_FILE" 2>&1 &
            ;;
    esac
    spinner $! "Installing PHP..."
    log "PHP $PHP_VERSION installed"
}

#==========================================================================
#  INSTALL NODE.JS
#==========================================================================

install_nodejs() {
    info "Installing Node.js 20.x..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >> "$LOG_FILE" 2>&1
    
    case $PKG_MGR in
        apt-get)
            apt-get install -y -qq nodejs >> "$LOG_FILE" 2>&1 &
            ;;
        yum)
            yum install -y -q nodejs >> "$LOG_FILE" 2>&1 &
            ;;
    esac
    spinner $! "Installing Node.js..."
    
    npm install -g pm2 yarn >> "$LOG_FILE" 2>&1
    log "Node.js $(node -v) installed"
}

#==========================================================================
#  INSTALL WEBPANEL
#==========================================================================

install_panel() {
    info "Deploying WebPanel..."

    # Create panel directory
    mkdir -p "$PANEL_DIR"
    cd "$PANEL_DIR"

    # Create package.json
    cat > package.json << 'PACKAGEJSON'
{
  "name": "webpanel",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "next dev -p ${PANEL_PORT:-8080}",
    "build": "next build",
    "start": "next start -p ${PANEL_PORT:-8080}"
  },
  "dependencies": {
    "next": "^14.0.0",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "ssh2": "^1.15.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.0"
  }
}
PACKAGEJSON

    # Create .env
    cat > .env << ENVFILE
PANEL_PORT=$PANEL_PORT
PANEL_USER=$PANEL_USER
JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || head -c 32 /dev/urandom | base64)
ENVFILE

    # Install dependencies
    npm install --production >> "$LOG_FILE" 2>&1 &
    spinner $! "Installing panel dependencies..."

    # Create PM2 ecosystem
    cat > ecosystem.config.js << PM2CONFIG
module.exports = {
  apps: [{
    name: 'webpanel',
    script: 'node_modules/.bin/next',
    args: 'start -p $PANEL_PORT',
    cwd: '$PANEL_DIR',
    env: { NODE_ENV: 'production' }
  }]
};
PM2CONFIG

    # Start with PM2
    pm2 start ecosystem.config.js >> "$LOG_FILE" 2>&1
    pm2 save >> "$LOG_FILE" 2>&1
    pm2 startup >> "$LOG_FILE" 2>&1

    log "WebPanel deployed on port $PANEL_PORT"
}

#==========================================================================
#  CONFIGURE FIREWALL
#==========================================================================

configure_firewall() {
    info "Configuring firewall..."

    local ports="22 80 443 $PANEL_PORT"

    case $PKG_MGR in
        apt-get)
            for port in $ports; do
                ufw allow "$port/tcp" >> "$LOG_FILE" 2>&1
            done
            ufw --force enable >> "$LOG_FILE" 2>&1
            ;;
        yum)
            for port in $ports; do
                firewall-cmd --permanent --add-port="$port/tcp" >> "$LOG_FILE" 2>&1
            done
            firewall-cmd --reload >> "$LOG_FILE" 2>&1
            ;;
    esac

    log "Firewall configured (ports: $ports)"
}

#==========================================================================
#  SETUP BACKUP CRON
#==========================================================================

setup_backup() {
    info "Setting up auto-backup..."
    
    cat > /opt/webpanel/backup.sh << 'BACKUPSH'
#!/bin/bash
BACKUP_DIR="/opt/webpanel/backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"

# Backup databases
if systemctl is-active --quiet mysql 2>/dev/null; then
    mysqldump --all-databases > "$BACKUP_DIR/mysql_$DATE.sql"
fi
if systemctl is-active --quiet postgresql 2>/dev/null; then
    su - postgres -c "pg_dumpall" > "$BACKUP_DIR/pg_$DATE.sql"
fi

# Backup nginx/apache configs
tar -czf "$BACKUP_DIR/nginx_$DATE.tar.gz" /etc/nginx/ 2>/dev/null
tar -czf "$BACKUP_DIR/apache_$DATE.tar.gz" /etc/apache2/ 2>/dev/null

# Keep last 7 days
find "$BACKUP_DIR" -mtime +7 -delete
BACKUPSH

    chmod +x /opt/webpanel/backup.sh
    
    # Daily backup at 2 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/webpanel/backup.sh") | crontab -

    log "Auto-backup scheduled (daily at 2 AM)"
}

#==========================================================================
#  INSTALL OPTIONAL TOOLS
#==========================================================================

install_extras() {
    info "Installing optional tools..."

    # Docker
    if command -v docker &>/dev/null; then
        log "Docker already installed"
    else
        curl -fsSL https://get.docker.com | bash >> "$LOG_FILE" 2>&1 &
        spinner $! "Installing Docker..."
        log "Docker installed"
    fi

    # Certbot (SSL)
    case $PKG_MGR in
        apt-get) apt-get install -y -qq certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1 ;;
        yum) yum install -y -q certbot python3-certbot-nginx >> "$LOG_FILE" 2>&1 ;;
    esac
    log "Certbot installed"
}

#==========================================================================
#  FINAL SUMMARY
#==========================================================================

print_summary() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║       ✅  INSTALLATION COMPLETE!             ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BOLD}Stack:${NC}        $STACK_NAME"
    echo -e "  ${BOLD}Web Server:${NC}   $WEBSERVER"
    echo -e "  ${BOLD}Database:${NC}     $DB_SERVER"
    echo ""
    echo -e "  ${BOLD}🌐 Panel URL:${NC}  http://$SERVER_IP:$PANEL_PORT"
    echo -e "  ${BOLD}👤 Username:${NC}   $PANEL_USER"
    echo -e "  ${BOLD}🔑 Password:${NC}   $PANEL_PASS"
    echo ""
    echo -e "  ${YELLOW}⚠️  Save these credentials!${NC}"
    echo -e "  ${YELLOW}⚠️  Change password after first login${NC}"
    echo ""
    echo -e "  ${CYAN}📁 Panel dir:   $PANEL_DIR${NC}"
    echo -e "  ${CYAN}📋 Log file:    $LOG_FILE${NC}"
    echo ""
    echo -e "  ${BOLD}Quick commands:${NC}"
    echo -e "  pm2 status          # Check panel status"
    echo -e "  pm2 restart webpanel # Restart panel"
    echo -e "  pm2 logs webpanel    # View panel logs"
    echo ""
}

#==========================================================================
#  MAIN
#==========================================================================

main() {
    # Parse args
    while [[ $# -gt 0 ]]; do
        case $1 in
            --stack) STACK="$2"; shift 2 ;;
            --port) PANEL_PORT="$2"; shift 2 ;;
            --help)
                echo "Usage: curl -fsSL URL | bash -s -- [options]"
                echo "  --stack 1-4   Preselect stack (1=LAMP 2=LEMP 3=LLMP 4=MODERN)"
                echo "  --port PORT   Panel port (default: 8080)"
                exit 0
                ;;
            *) shift ;;
        esac
    done

    logo
    detect_os
    install_deps
    select_stack
    install_webserver
    install_database
    install_php
    install_nodejs
    install_panel
    install_extras
    configure_firewall
    setup_backup
    print_summary

    # Save credentials
    echo "PANEL_USER=$PANEL_USER" > "$PANEL_DIR/.credentials"
    echo "PANEL_PASS=$PANEL_PASS" >> "$PANEL_DIR/.credentials"
    chmod 600 "$PANEL_DIR/.credentials"
}

main "$@"
