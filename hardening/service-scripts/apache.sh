#!/usr/bin/env bash
#
# Setup
#
. ../.allrc
apache_main_config="/etc/apache2/apache2.conf"
apache_additional_config="/etc/apache2/conf-enabled/99-apache-security.conf"
#
# Confirm existence of drop-in configuration file
touch "$apache_additional_config"
#
# Append a configuration if the configuration doesn't already exist; otherwise skip.
safe_add() {
	grep -qF -- "$1" "$apache_main_config" ||
		echo "$1" >>"$apache_main_config"
}





#
# Service Hardening
#
# Comment out Indexing commands in ALL config files (prevents the "Invalid command IndexIgnore" error)
find /etc/apache2 -type f -name '*.conf' -exec sed -i~ 's/^\s*IndexIgnore/# IndexIgnore/g' {} +
find /etc/apache2 -type f -name '*.conf' -exec sed -i 's/^\s*IndexOptions/# IndexOptions/g' {} +
#
# Fix the "Options" error in main config
sed -i 's/^.*Options.*Indexes.*$/\tOptions None/g'
#
# Disable risky modules (no confirmation)
echo "i: Disabling risky modules..."
a2dismod -fq autoindex status info
#
# Hide version information
echo "i: Preventing web server version leaks..."
safe_add "ServerTokens Prod"
safe_add "ServerSignature Off"
#
# Standardizes the /var/www/ block to "Options None" & "AllowOverride None"
echo "i: Hardening Directory blocks..."
sed -Ei~ '
	/<Directory\s+\/var\/www\/>/,/<\/Directory>/ {
		s/^\s*Options.*/\tOptions None/
		s/^\s*AllowOverride.*/\tAllowOverride None/
	}
' "$apache_main_config"
# if service goes down, try AllowOverride AuthConfig or AllowOverride All
#
# Header Configuration
echo "i: Adding Security Headers..."
echo '
	<IfModule mod_headers.c>
		Header always set X-Frame-Options "SAMEORIGIN"
		Header always set X-Content-Type-Options "nosniff"
		Header set X-XSS-Protection "1"
	</IfModule>
' >>"$apache_main_config"





#
# Configuration Validation
#
echo "i: Verifying configuration syntax..."
a2enmod headers
if apache2ctl -t; then
	echo "
		OK: Syntax OK
		i: Restarting Apache...
	"
	systemctl restart apache2
else
	echo '
		E: Syntax check failed
		i: Run "apache2ctl -t" to see why.
	'
	alt_exit 1
fi





#
# Exit
#
clear
alt_exit 0