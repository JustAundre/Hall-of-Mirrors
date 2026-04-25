#!/usr/bin/env bash
#
# Environment Setup
#
# Import global helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")../" || exit
. .allrc
#
# Script configuration
config=/etc/apache2/apache2.conf
config_dir=/etc/apache2/conf-enabled/99-apache-security.conf
#
# Confirm existence of drop-in configuration file
touch "${config_dir}"





#
# Service Hardening
#
# Comment index commands in all Apache config to prevent collisions.
find /etc/apache2 -type f -name '*.conf' -exec sed -ie 's/^\s*IndexIgnore/# IndexIgnore/g' -e 's/^\s*IndexOptions/# IndexOptions/g' {} +
#
# Fix the "Options" error in main config
sed -i 's/^.*Options.*Indexes.*$/\tOptions None/g'
#
# Disable risky modules
a2dismod -fq autoindex status info
#
# Install secure default configuration file
install -m 640 -o root -g root general-confs/apache2.conf /etc/apache2/conf-enabled/99-security.conf




#
# Configuration Validation
#
# If syntax check...
a2enmod headers
if
	apache2ctl -t
then
	# Passes, restart Apache.
	cat <<-'EOF'
		OK: Syntax OK
		i: Restarting Apache...
	EOF
	systemctl restart apache2
else
	# Fails, prompt the user to see why.
	cat <<-'EOF'
		E: Syntax check failed.
		i: Run (apache2ctl -t) to see why.
	EOF
	exit 1
fi





#
# Exit
#
# Exit & print success banner
# & the logs from this session.
success