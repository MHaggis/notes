#!/bin/bash

# Exit on any error
set -e

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Function to log errors
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Function to check if a command was successful
check_status() {
    if [ $? -eq 0 ]; then
        log_message "SUCCESS: $1"
    else
        log_error "$1"
        exit 1
    fi
}

# Function to verify Apache installation
verify_apache() {
    if ! command -v apache2 >/dev/null 2>&1; then
        log_error "Apache2 is not installed properly"
        return 1
    fi
    return 0
}

# Function to verify PHP installation
verify_php() {
    if ! command -v php >/dev/null 2>&1; then
        log_error "PHP is not installed properly"
        return 1
    fi
    return 0
}

# Function to enable Apache modules
enable_apache_modules() {
    local php_version=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    log_message "Detected PHP version: $php_version"
    
    # Enable PHP module
    if [ -f "/etc/apache2/mods-available/php${php_version}.load" ]; then
        a2enmod "php${php_version}"
    else
        log_error "PHP module not found for version ${php_version}"
        return 1
    fi
    
    # Enable other required modules
    a2enmod rewrite
    return 0
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run this script as root (use sudo)"
    exit 1
fi

# Stop Apache if it's running
log_message "Stopping Apache service if running..."
systemctl stop apache2 || true

# Update package list
log_message "Updating package list..."
apt-get update
check_status "Package list update"

# Install Apache and PHP
log_message "Installing Apache and PHP..."
apt-get install -y apache2 php libapache2-mod-php php-mysql
check_status "Apache and PHP installation"

# Verify installations
verify_apache || exit 1
verify_php || exit 1

# Get PHP files directory from user
while true; do
    read -p "Enter the full path to your PHP files directory: " PHP_DIR
    
    # Remove trailing slash if present
    PHP_DIR="${PHP_DIR%/}"
    
    # Validate directory
    if [ ! -d "$PHP_DIR" ]; then
        read -p "Directory doesn't exist. Create it? (y/n): " create_dir
        if [[ $create_dir =~ ^[Yy]$ ]]; then
            mkdir -p "$PHP_DIR"
            check_status "Directory creation"
        else
            log_error "Valid directory path required"
            continue
        fi
    fi
    break
done

# Update Apache configuration
log_message "Updating Apache configuration..."
cat > /etc/apache2/sites-available/000-default.conf << EOL
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot ${PHP_DIR}

    <Directory ${PHP_DIR}>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
        DirectoryIndex index.php index.html
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL
check_status "Apache virtual host configuration"

# Update main Apache configuration
log_message "Updating main Apache configuration..."
if ! grep -q "Directory ${PHP_DIR}" /etc/apache2/apache2.conf; then
    cat >> /etc/apache2/apache2.conf << EOL

# Custom PHP directory configuration
<Directory ${PHP_DIR}>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
    DirectoryIndex index.php index.html
</Directory>
EOL
fi
check_status "Apache main configuration update"

# Set proper permissions
log_message "Setting permissions..."
chown -R www-data:www-data "$PHP_DIR"
chmod -R 755 "$PHP_DIR"
check_status "Permissions setup"

# Enable Apache modules
log_message "Enabling Apache modules..."
enable_apache_modules
check_status "Apache modules enabled"

# Verify Apache config
log_message "Verifying Apache configuration..."
apache2ctl configtest
check_status "Apache configuration test"

# Start and enable Apache
log_message "Starting and enabling Apache..."
systemctl start apache2
systemctl enable apache2
check_status "Apache service start"

# Wait for Apache to fully start
sleep 2

# Verify Apache is running
if ! systemctl is-active --quiet apache2; then
    log_error "Apache failed to start"
    echo "Apache error log:"
    tail -n 10 /var/log/apache2/error.log
    exit 1
fi

# Test PHP
log_message "Testing PHP functionality..."
echo "<?php phpinfo(); ?>" > "${PHP_DIR}/test.php"
if curl -s localhost/test.php | grep -q "PHP Version"; then
    log_message "PHP is working correctly"
    rm "${PHP_DIR}/test.php"
else
    log_error "PHP is not working correctly"
    echo "Apache error log:"
    tail -n 10 /var/log/apache2/error.log
    exit 1
fi

log_message "Installation completed successfully!"

# Display connection information
echo -e "\n=== Apache Service Status ==="
systemctl status apache2 --no-pager | grep "Active:"

echo -e "\n=== Connection Information ==="
echo "Local URL: http://localhost/"

# Get all IP addresses (excluding localhost)
echo -e "\nAvailable IP addresses to connect to:"
ip -4 addr show | grep inet | grep -v '127.0.0.1' | awk '{print "http://" $2}' | cut -d'/' -f1

# Check if public IP is available
echo -e "\nPublic IP address:"
public_ip=$(curl -s ifconfig.me || wget -qO- ifconfig.me)
if [ ! -z "$public_ip" ]; then
    echo "http://$public_ip/"
else
    echo "Could not determine public IP address"
fi

echo -e "\nApache is listening on port(s):"
ss -tlpn | grep apache2

echo -e "\n=== Important File Locations ==="
echo "Web root directory: ${PHP_DIR}"
echo "Apache configuration: /etc/apache2/"
echo "Apache error log: /var/log/apache2/error.log"
echo "Apache access log: /var/log/apache2/access.log"

# List files in the directory
echo -e "\n=== Files available in ${PHP_DIR} ==="
ls -l ${PHP_DIR}

# Final verification
echo -e "\n=== Verification Steps ==="
echo "1. Apache Status: $(systemctl is-active apache2)"
echo "2. PHP Module: $(apache2ctl -M 2>/dev/null | grep php || echo 'Not loaded')"
echo "3. Directory Permissions: $(ls -ld ${PHP_DIR})"