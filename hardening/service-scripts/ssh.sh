#!/usr/bin/env bash
#
# Environment Setup
#
# Variables
cd "$(dirname "${BASH_ARGV0[*]}")"
. ../.allrc
config=/etc/ssh/sshd_config
#
# A function to safely set SSH configurations
safe_add() {
	local key="$1"
	local value="$2"
	#
	# Check if the configuration key is already specified
	if grep -qE "^#?\s*${key}\s+" "$config"; then
		# If yes, change the value to the new value.
		sed -i "s|^\s*#\?\s*${key}\s\+.*|${key} ${value}|" "$config"
	else
		# If not, append a new entry of the configuration key
		echo "${key} ${value}" >>"$config"
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
	alt_exit 2





#
# SSH Hardening
#
# Authentication (no keys, all password)
echo 'i: Applying SSH setting configurations'
safe_add PermitRootLogin no
safe_add PasswordAuthentication yes
safe_add PubkeyAuthentication no
safe_add PermitEmptyPasswords no
safe_add ChallengeResponseAuthentication no
safe_add UsePAM yes
#
# Connection hardening
safe_add StrictModes yes
safe_add MaxAuthTries 3
safe_add LoginGraceTime 30
safe_add ClientAliveInterval 300
safe_add ClientAliveCountMax 2
#
# Feature lockdown
safe_add X11Forwarding no
safe_add AllowTcpForwarding no
safe_add PrintMotd no





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
		E: Syntax check failed.
		i: Run (sshd -t) to see why.
	EOF
	#
	# Restart SSHD
	systemctl restart sshd
	alt_exit 1
fi





#
# Fail2Ban Configuration
#
# Install Fail2Ban & install secure rules.
if confirm 'Use Fail2Ban with a secure default configuration'; then
	apt-get install fail2ban &&
		install -m 600 -o root -g root general-confs/jail.local /etc/fail2ban/jail.local
fi





#
# Exit
#
# Exit with summary
alt_exit 0