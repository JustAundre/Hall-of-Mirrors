#!/usr/bin/env bash
#
# Setup
#
# Script variables
cd "$(dirname "${BASH_ARGV0[*]}")"
. ../.allrc
config_main=/etc/nginx/nginx.conf
default_page=/etc/nginx/sites-available/default
config_snippets=/etc/nginx/snippets/security-headers.conf
general_hardening=/etc/nginx/conf.d/99-hardening.conf





#
# Nginx Setup
#
# Refresh Nginx
secure_install nginx ||
	alt_exit 2
#
# Add secure headers to outgoing requests
mkdir -p /etc/nginx/snippets
install -m 640 -u root -g root general-confs/nginx-headers.conf "$config_snippets"
#
# General reduction of information leakage
install -m 640 -u root -g root general-confs/99-hardening.conf "$general_hardening"
#
# Ensures it contains the conf.d include
if ! grep -qE 'include\s+/etc/nginx/conf\.d/\*\.conf;' "$config_main"; then
	# Insert inside the http {} block right after it opens
	sed -i~ '0,/http\s*{/s/http\s*{/http {\n\tinclude \/etc\/nginx\/conf.d\/\*\.conf;/' "$config_main"
fi
#
# Update the general-confs/default file with what is appropriate with your scenario
echo 'i: Replacing default site with secure defaults...'
install -m 640 -u root -g root install general-confs/default /etc/nginx/sites-available/default
#
# Remove overlapping configuration values from nginx.conf
sed -i '/server_tokens/d' "$config_main"
sed -i '/client_body_buffer_size/d' "$config_main"
sed -i '/client_header_buffer_size/d' "$config_main"
sed -i '/client_max_body_size/d' "$config_main"
sed -i '/large_client_header_buffers/d' "$config_main"
sed -i '/ssl_protocols/d' "$config_main"
sed -i '/ssl_prefer_server_ciphers/d' "$config_main"
sed -i '/ssl_session_cache/d' "$config_main"





#
# Configuration Validation
#
if nginx -t; then
	cat <<-'EOF'
		OK: Nginx config is OK,
		i: Restarting Nginx...
	EOF
	systemctl restart nginx
else
	cat <<-'EOF'
		E: Syntax check failed.
		i: Run (nginx -t) to see why.
	EOF
	alt_exit 1
fi





#
# Exit
#
# Exit with summary
alt_exit 0