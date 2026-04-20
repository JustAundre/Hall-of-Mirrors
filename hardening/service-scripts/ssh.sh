#!/usr/bin/env bash
#
# Environment Setup
#
# Import global helper functions and variables
cd "$(dirname "${BASH_SOURCE[0]}")../"
. .allrc
#
# Script variables
config=/etc/ssh/sshd_config
config_dir=/etc/ssh/sshd_config.d/
divider=' '





#
# Integrity Check
#
# Refresh SSHD
secure_install openssh-server
#
# Reset SSHD keys
(
	set -e
	ssh-keygen -A
	ssh-keygen -f /root/.ssh/known_hosts -R localhost
	systemctl restart sshd
) ||
	exit 2





#
# Configuration
#
# Clear current configuration
rm -rf /etc/ssh/*
#
# Binding
safe_add Port 22
safe_add AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::
#
# Logging
LogLevel VERBOSE
#
# Authentication
safe_add GSSAPIAuthentication no
safe_add KerberosAuthentication no
safe_add PermitRootLogin no
safe_add PasswordAuthentication yes
safe_add PubkeyAuthentication no
safe_add PermitEmptyPasswords no
safe_add ChallengeResponseAuthentication no
safe_add UsePAM yes
safe_add HostbasedAuthentication no
safe_add IgnoreUserKnownHosts yes
safe_add IgnoreRhosts yes
safe_add PermitEmptyPasswords no
#
# Connection hardening
safe_add StrictModes yes
safe_add MaxAuthTries 3
safe_add LoginGraceTime 20
safe_add ClientAliveInterval 300
safe_add ClientAliveCountMax 0
#
# Disable unecessary features
safe_add X11Forwarding no
safe_add AllowTcpForwarding no
safe_add PrintMotd no
safe_add AllowAgentForwarding no
safe_add PermitUserEnvironment no
safe_add Compression none





#
# Configuration Validation
#
# Validate SSH configurations
#
# If syntax check...
if
	sshd -t
then
	# Passes, then restart SSHD.
	cat <<-'EOF'
		OK: Syntax check passed.
		i: Restarting SSHD...
	EOF
	#
	# Restart SSHD
	systemctl restart sshd
else
	# Fails, then tell the user to how to check for why.
	cat <<-'EOF'
		E: Syntax check failed.
		i: Run (sshd -t) to see why.
	EOF
	exit 1
fi





#
# Fail2Ban Configuration
#
# Install Fail2Ban & install secure rules.
if
	confirm 'Use Fail2Ban with a secure default configuration'
then
	apt-get install fail2ban &&
		install -m 600 -o root -g root general-confs/jail.local /etc/fail2ban/jail.local
fi





#
# Exit
#
# Exit & print success banner
# and the logs from this session.
success