#!/usr/bin/env bash
#
# Environment Setup
#
# Import global helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")../" || exit
. .allrc
#
# Script variables
config_main=/etc/nginx/nginx.conf
default_page=/etc/nginx/sites-available/default
config_snippets=/etc/nginx/snippets/security-headers.conf
general_hardening=/etc/nginx/conf.d/99-hardening.conf





#
# Configuration
#
# Remove overlapping configuration values from nginx.conf
sed -ie '/server_tokens/d' -e '/client_body_buffer_size/d' -e '/client_header_buffer_size/d' -e '/client_max_body_size/d' -e '/large_client_header_buffers/d' -e '/ssl_protocols/d' -e '/ssl_prefer_server_ciphers/d' -e '/ssl_session_cache/d' "${config_main}"
#
# Apply secure header rules & general information leakage prevention
# Install secure default template
mkdir -p /etc/nginx/snippets
install -m 640 -u root -g root general-confs/nginx-headers.conf "${config_snippets}"
install -m 640 -u root -g root general-confs/99-hardening.conf "${general_hardening}"
install -m 640 -u root -g root install general-confs/default /etc/nginx/sites-available/default
#
# Ensures it contains the conf.d include
# !!! LORD I NEED TO REFACTOR THIS I CAN'T READ THIS !!!
grep -qE 'include\s+/etc/nginx/conf\.d/\*\.conf;' "${config_main}" ||
	sed -i '0,/http\s*{/s/http\s*{/http {\n\tinclude \/etc\/nginx\/conf.d\/\*\.conf;/' "${config_main}"





#
# Configuration Validation
#
if
	nginx -t
then
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
	exit 1
fi





#
# Exit
#
# Exit & print success banner
# & the logs from this session.
success