#!/bin/bash
#==========================================================================
#  SUPERPANEL - One-click VPS Web Management Panel Installer
#  Supports: LAMP, LEMP, LLMP, Modern Stack
#  Version: 1.1.0 — Fixed interactive + pipe mode, auto-detect TTY
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
PANEL_DIR="/opt/SUPERPANEL"
PANEL_PORT="8080"
PANEL_USER="admin"
PANEL_PASS=$(openssl rand -base64 12 2>/dev/null || head -c 12 /dev/urandom | base64)
LOG_FILE="/tmp/SUPERPANEL-install.log"
GITHUB_REPO="https://github.com/panelboss/superpanel"

#==========================================================================
#  UTILS
#==========================================================================

logo() {
    clear
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║       🚀  SUPERPANEL INSTALLER  🚀            ║"
    echo "║       One-Click Server Manager               ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
}

log()  { echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[!]${NC} $1" | tee -a "$LOG_FILE"; }
err()  { echo -e "${RED}[✗] $1${NC}" | tee -a "$LOG_FILE"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1" | tee -a "$LOG_FILE"; }

spinner() {
    # Simplified: just show running status, actual install runs sync
    local pid=$1 msg=$2
    local spin='-\|/'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}[%c]${NC} %s" "${spin:i++%4:1}" "$msg"
        sleep 0.3
    done
    wait "$pid" 2>/dev/null
    local ret=$?
    printf "\r${GREEN}[✓]${NC} %s\n" "$msg"
    return $ret
}

run_install() {
    # Run install command synchronously, log output
    local msg=$1; shift
    info "$msg..."
    "$@" >> "$LOG_FILE" 2>&1
    local ret=$?
    if [ $ret -eq 0 ]; then
        log "$msg"
    else
        warn "$msg (exit code: $ret, check $LOG_FILE)"
    fi
    return $ret
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
    case $PKG_MGR in
        apt-get)
            export DEBIAN_FRONTEND=noninteractive
            apt-get update -qq >> "$LOG_FILE" 2>&1
            run_install "Installing dependencies" apt-get install -y -qq curl wget git unzip tar software-properties-common gnupg ca-certificates openssl ufw fail2ban
            ;;
        yum)
            yum install -y -q epel-release >> "$LOG_FILE" 2>&1
            run_install "Installing dependencies" yum install -y -q curl wget git unzip tar openssl firewalld fail2ban
            ;;
    esac
}

#==========================================================================
#  STACK SELECTION
#==========================================================================

#==========================================================================
#  STACK SELECTION
#==========================================================================

select_stack() {
    # Priority: 1) --stack flag, 2) interactive prompt, 3) pipe auto-detect
    if [ -n "$STACK" ]; then
        STACK_CHOICE=$STACK
        info "Stack: $STACK_CHOICE (via --stack flag)"
    elif [ -t 0 ] && [ -t 1 ]; then
        # True interactive terminal — ask user
        echo ""
        echo -e "${BOLD}Select your stack:${NC}"
        echo ""
        echo "  1) LAMP  - Apache + MySQL + PHP"
        echo "  2) LEMP  - Nginx + MySQL + PHP"
        echo "  3) LLMP  - OpenLiteSpeed + MariaDB + PHP"
        echo "  4) MODERN - Nginx + Node.js + PostgreSQL"
        echo ""
        printf "Enter choice [1-4]: "
        read STACK_CHOICE
        STACK_CHOICE=${STACK_CHOICE:-2}
    else
        # Piped mode — auto-select with clear notice
        STACK_CHOICE=2
        echo ""
        echo -e "${YELLOW}╔══════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║  Running in PIPE mode (curl | bash)         ║${NC}"
        echo -e "${YELLOW}║  Auto-selected: LEMP (Nginx+MySQL+PHP)      ║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}For interactive install, run:${NC}"
        echo -e "  wget ${GITHUB_REPO}/raw/master/install.sh && bash install.sh"
        echo -e "${CYAN}Or specify stack directly:${NC}"
        echo -e "  curl -fsSL ... | bash -s -- --stack 2   # LEMP"
        echo -e "  curl -fsSL ... | bash -s -- --stack 4   # MODERN"
        echo ""
        sleep 2
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
    case $WEBSERVER in
        nginx)
            run_install "Installing Nginx" $PKG_MGR install -y -qq nginx
            systemctl enable nginx --now
            ;;
        apache2)
            run_install "Installing Apache" $PKG_MGR install -y -qq $([ "$PKG_MGR" = "yum" ] && echo "httpd" || echo "apache2")
            [ "$PKG_MGR" = "yum" ] && WEBSERVER="httpd"
            systemctl enable $WEBSERVER --now
            ;;
        openlitespeed)
            wget -O - https://repo.litespeed.sh | bash >> "$LOG_FILE" 2>&1
            run_install "Installing OpenLiteSpeed" $PKG_MGR install -y -qq openlitespeed
            ;;
    esac
    log "$WEBSERVER installed"
}

#==========================================================================
#  INSTALL DATABASE
#==========================================================================

install_database() {
    case $DB_SERVER in
        mysql)
            run_install "Installing MySQL" $PKG_MGR install -y -qq mysql-server
            systemctl enable mysql --now
            ;;
        mariadb)
            run_install "Installing MariaDB" $PKG_MGR install -y -qq mariadb-server
            systemctl enable mariadb --now
            ;;
        postgresql)
            run_install "Installing PostgreSQL" $PKG_MGR install -y -qq postgresql postgresql-contrib 2>/dev/null || run_install "Installing PostgreSQL" $PKG_MGR install -y -qq postgresql-server
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

    case $PKG_MGR in
        apt-get)
            add-apt-repository -y ppa:ondrej/php >> "$LOG_FILE" 2>&1 || true
            apt-get update -qq >> "$LOG_FILE" 2>&1
            run_install "Installing PHP $PHP_VERSION" apt-get install -y -qq php${PHP_VERSION} php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql php${PHP_VERSION}-curl php${PHP_VERSION}-json php${PHP_VERSION}-mbstring php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-gd php${PHP_VERSION}-intl php${PHP_VERSION}-bcmath
            ;;
        yum)
            yum install -y -q https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> "$LOG_FILE" 2>&1 || true
            yum module enable -y php:remi-${PHP_VERSION} >> "$LOG_FILE" 2>&1 || true
            run_install "Installing PHP $PHP_VERSION" yum install -y -q php php-fpm php-mysqlnd php-curl php-json php-mbstring php-xml php-zip php-gd
            ;;
    esac
    log "PHP $PHP_VERSION installed"
}

#==========================================================================
#  INSTALL NODE.JS
#==========================================================================

install_nodejs() {
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >> "$LOG_FILE" 2>&1
    run_install "Installing Node.js 20.x" $PKG_MGR install -y -qq nodejs
    npm install -g pm2 >> "$LOG_FILE" 2>&1
    log "Node.js $(node -v) installed"
}

#==========================================================================
#  INSTALL SUPERPANEL
#==========================================================================

install_panel() {
    info "Deploying SuperPanel..."

    # Create panel directory
    mkdir -p "$PANEL_DIR"
    cd "$PANEL_DIR"

    # Clone panel from GitHub
    info "Downloading panel source..."
    if [ -d ".git" ]; then
        git pull origin master >> "$LOG_FILE" 2>&1
    else
        git clone https://github.com/panelboss/superpanel.git "$PANEL_DIR" >> "$LOG_FILE" 2>&1
    fi

    # Go to panel source
    cd "$PANEL_DIR/panel"

    # Create .env
    cat > .env << ENVFILE
PANEL_PORT=$PANEL_PORT
PANEL_USER=$PANEL_USER
PANEL_PASSWORD=$PANEL_PASS
ENVFILE

    # Install dependencies
    run_install "Installing npm packages" npm install

    # Build Next.js
    info "Building panel (this may take a minute)..."
    npm run build >> "$LOG_FILE" 2>&1
    log "Panel build complete"

    # Create PM2 ecosystem
    cat > ecosystem.config.js << PM2CONFIG
module.exports = {
  apps: [{
    name: 'superpanel',
    script: 'node_modules/.bin/next',
    args: 'start -p $PANEL_PORT',
    cwd: '$PANEL_DIR/panel',
    env: { 
      NODE_ENV: 'production',
      PANEL_PASSWORD: '$PANEL_PASS'
    }
  }]
};
PM2CONFIG

    # Stop old instance if exists
    pm2 delete superpanel 2>/dev/null || true

    # Start with PM2
    pm2 start ecosystem.config.js >> "$LOG_FILE" 2>&1
    pm2 save >> "$LOG_FILE" 2>&1
    pm2 startup >> "$LOG_FILE" 2>&1

    log "SuperPanel deployed on port $PANEL_PORT"
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
    
    cat > /opt/SUPERPANEL/backup.sh << 'BACKUPSH'
#!/bin/bash
BACKUP_DIR="/opt/SUPERPANEL/backups"
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

    chmod +x /opt/SUPERPANEL/backup.sh
    
    # Daily backup at 2 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/SUPERPANEL/backup.sh") | crontab -

    log "Auto-backup scheduled (daily at 2 AM)"
}

#==========================================================================
#  INSTALL OPTIONAL TOOLS
#==========================================================================

install_extras() {
    # Docker (optional)
    if command -v docker &>/dev/null; then
        log "Docker already installed"
    else
        curl -fsSL https://get.docker.com | bash >> "$LOG_FILE" 2>&1 || warn "Docker install skipped"
    fi

    # Certbot (SSL)
    run_install "Installing Certbot" $PKG_MGR install -y -qq certbot python3-certbot-nginx 2>/dev/null || \
    run_install "Installing Certbot" $PKG_MGR install -y -qq certbot
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
    echo -e "  pm2 restart SUPERPANEL # Restart panel"
    echo -e "  pm2 logs SUPERPANEL    # View panel logs"
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
