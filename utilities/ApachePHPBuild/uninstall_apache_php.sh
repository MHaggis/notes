#!/bin/bash

# Exit on any error
set -e

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    log_message "Please run this script as root (use sudo)"
    exit 1
fi

# Stop Apache service
log_message "Stopping Apache service..."
systemctl stop apache2 || true

# Disable Apache service
log_message "Disabling Apache service..."
systemctl disable apache2 || true

# Remove Apache and PHP packages
log_message "Removing Apache and PHP packages..."
apt-get remove --purge -y apache2 apache2-utils apache2-bin apache2-data php libapache2-mod-php php-mysql
apt-get autoremove -y

# Remove Apache and PHP configuration files
log_message "Removing configuration files..."
rm -rf /etc/apache2
rm -rf /etc/php

# Remove log files
log_message "Removing log files..."
rm -rf /var/log/apache2
rm -rf /var/log/php

# Remove web root directory content (but keep the directory)
log_message "Cleaning web root directory..."
rm -rf /var/www/html/*

# Clean package cache
log_message "Cleaning package cache..."
apt-get clean
apt-get autoclean

log_message "Uninstallation completed successfully!"

# Show status of removed services
echo -e "\n=== Service Status ==="
systemctl status apache2 --no-pager || true