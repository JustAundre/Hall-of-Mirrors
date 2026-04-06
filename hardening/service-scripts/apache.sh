#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
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
find /etc/apache2 -type f -name "*.conf"\
	-exec sed -i~ "s/^\s*IndexIgnore/# IndexIgnore/g" {} +
find /etc/apache2 -type f -name "*.conf"\
	-exec sed -i "s/^\s*IndexOptions/# IndexOptions/g" {} +
#
# Fix the "Options" error in main config
sed -i 's/^.*Options.*Indexes.*$/\tOptions None/g'
#
# Disable risky modules (no confirmation)
echo "🚧: Disabling risky modules..."
a2dismod -fq autoindex status info
#
# Hide version information
echo "🚧: Preventing web server version leaks..."
safe_add "ServerTokens Prod"
safe_add "ServerSignature Off"
#
# Standardizes the /var/www/ block to "Options None" and "AllowOverride None"
echo "🚧: Hardening Directory blocks..."
sed -Ei~ '
	/<Directory\s+\/var\/www\/>/,/<\/Directory>/ {
		s/^\s*Options.*/\tOptions None/
		s/^\s*AllowOverride.*/\tAllowOverride None/
	}
' "$apache_main_config"
# if service goes down, try AllowOverride AuthConfig or AllowOverride All
#
# Header Configuration
echo "🚧: Adding Security Headers..."
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
echo "🚧: Verifying configuration syntax..."
a2enmod headers
if apache2ctl -t; then
	echo "
		✅: Syntax OK
		🚧: Restarting Apache...
	"
	systemctl restart apache2
else
	echo '
		❌: Syntax check failed
		ℹ️: Run "apache2ctl -t" to see why.
	'
	exit 1
fi





#
# Firewall Configuration
#
# Whitelist the universal HTTP port
echo 'ℹ️: Space-separated inputs required (i.e. 80 8080 4320)'
read -rp 'What port(s) does your webserver use? (Enter nothing for defaults): ' ports
for port in "$ports"; do
	if [[ "$port" =~ $numberCheck ]]; then
		ufw allow in "$port"/tcp && echo "✅: Exempting port ($port/tcp)"
	else
		echo "❌: Erroneous input at ($port) so exempting default web server port (80/tcp)."
		ufw allow in 80/tcp
		continue
	fi
done





#
# Exit
#
clear
exit 0