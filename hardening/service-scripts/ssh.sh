#!/usr/bin/env bash
#
# Environment Setup
#
# Variables
. ../.allrc
config_file='/etc/ssh/sshd_config'
backup_config='/etc/ssh/sshd_config~'
#
# A function to safely set SSH configurations
configure_ssh() {
	local key="$1"
	local value="$2"
	#
	# Check if the configuration key is already specified
	if grep -qE "^#?\s*${key}\s+" "$config_file"; then
		# If yes, change the value to the new value.
		sed -i "s|^\s*#\?\s*${key}\s\+.*|${key} ${value}|" "$config_file"
	else
		# If not, append a new entry of the configuration key
		echo "${key} ${value}" >>"$config_file"
	fi
}





#
# SSH Setup/Integrity Verification
#
cat <<-'EOF'
	Help Pages:
	https://unix.stackexchange.com/questions/642824/ssh-fails-to-start-due-to-missing-host-keys

	i: Installing & resetting SSH...
EOF
#
# Backup configurations
cp -p "$config_file" "$backup_config"
echo "i: Backups created at ($backup_config)"
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
) || alt_exit 8





#
# SSH Hardening
#
# Authentication (no keys, all password)
echo 'i: Applying SSH setting configurations'
configure_ssh PermitRootLogin no
configure_ssh PasswordAuthentication yes
configure_ssh PubkeyAuthentication no
configure_ssh PermitEmptyPasswords no
configure_ssh ChallengeResponseAuthentication no
configure_ssh UsePAM yes
#
# Connection hardening
configure_ssh StrictModes yes
configure_ssh MaxAuthTries 3
configure_ssh LoginGraceTime 30
configure_ssh ClientAliveInterval 300
configure_ssh ClientAliveCountMax 2
#
# Feature lockdown
configure_ssh X11Forwarding no
configure_ssh AllowTcpForwarding no
configure_ssh PrintMotd no





#
# Access Audit
#
# SSH Group Check
if getent group ssh &>/dev/null; then
	if [[ -n "$(
			getent group ssh |
				awk -F: '{print $3, $4}'
		)"
	]]; then
		cat <<-EOF
			i: The following users are in the SSH group & may be able to SSH into this machine: $members
		EOF
	else
		echo 'i: There are no members in the SSH group.'
	fi
else
	echo 'i: The SSH group does not exist.'
fi





#
# Configuration Validation
#
# Validate SSH configurations
echo 'i: Validating configuration(s)...'
#
# If SSHD configurations...
if sshd -t; then
	# Pass
	cat <<-'EOF'
		OK: SSH configuration is OK.
		i: Restarting SSHD...
	EOF
	#
	# Restart SSHD
	systemctl restart sshd
else
	# Fail
	cat <<-'EOF'
		E: Configuration validation failed.
		i: Reverting to backup_configs...
	EOF
	#
	# Revert configurations
	cp -p "$backup_config" "$config_file"
	#
	# Restart SSHD
	systemctl restart sshd
	alt_exit 1
fi





#
# Firewall Configuration
#
if confirm 'Use Fail2Ban with a secure default configuration'; then
	apt-get install fail2ban &&
		install -m 600 -o root -g root general-confs/jail.local /etc/fail2ban/jail.local
fi





#
# Exit
#
clear
alt_exit 0