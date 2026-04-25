#!/usr/bin/env bash
#
# Environment Setup
#
# Import global helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")../"
. .allrc
#
# Script Variables
config=/etc/vsftpd.conf
cert_dir=/etc/ssl/private
cert="${cert_dir}/vsftpd.pem"
divider='='





#
# Integrity Check
#
# Force-reinstall/instal VSFTPD.
echo 'i: Refreshing VSFTPD...'
secure_install vsftpd openssl ||
	exit 2





#
# Configuration
#
# Generate a TLS certificate if not present.
[[ ! -f "${cert}" ]] &&
	openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout /dev/stdout -out /dev/stdout -subj '/CN=FTP Server' |
	install -m 600 -u root -g root /dev/stdin "${cert}"
#
# Disable anonymous access
safe_add anonymous_enable NO
#
# Local users only
safe_add 'local_enable YES'
safe_add 'write_enable YES'
#
# Chroot/anchor users to their home directories
safe_add 'chroot_local_user YES'
safe_add 'allow_writeable_chroot YES'
#
# Restrict file permissions
safe_add 'local_umask 077'
#
# Disable risky features
safe_add 'dirmessage_enable NO'
safe_add 'xferlog_enable YES'
safe_add 'port_enable NO'
#
# Enable Logging
safe_add 'log_ftp_protocol YES'
safe_add 'vsftpd_log_file /var/log/vsftpd.log'
#
# Connection limits (brute-force mitigation)
safe_add 'max_clients 10'
safe_add 'max_per_ip 3'
safe_add 'pasv_enable YES'
safe_add 'pasv_min_port 40000'
safe_add 'pasv_max_port 40100'
#
# Banner
safe_add 'ftpd_banner Authorized access only.'
#
# TLS Hardening
safe_add ssl_enable YES
safe_add rsa_cert_file "${cert}"
safe_add rsa_private_key_file "${cert}"
#
# Force Encryption
safe_add force_local_logins_ssl YES
safe_add force_local_data_ssl YES
#
# Disable Weak SSL
safe_add ssl_sslv2 NO
safe_add ssl_sslv3 NO
safe_add ssl_tlsv1 NO
safe_add ssl_tlsv1_1 NO
safe_add ssl_tlsv1_2 YES
#
# Strong ciphers
safe_add ssl_ciphers HIGH
#
# Hide users
safe_add userlist_enable YES
safe_add userlist_deny NO
safe_add require_ssl_reuse NO





#
# Validation
#
# Have VSFTPD parse the new configuration file
if
	vsftpd "${config}"
then
	# Restart & apply if it finds no errors
	cat <<-'EOF'
		OK: Syntax OK
		i: Restarting VSFTPD...
	EOF
	systemctl restart vsftpd
else
	cat <<-EOF
		E: Syntax check failed.
		i: Run (vsftpd ${config}) to see why.
	EOF
	exit 1
fi





#
# Exit
#
# Exit & print success banner
# & the logs from this session.
success