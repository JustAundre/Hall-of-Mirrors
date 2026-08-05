#!/usr/bin/env bash
#
# Installation
#
# Install the logging directory
mkdir -p /var/log/sessions
chown 0:0 /var/log/sessions
chmod 640 /var/log/sessions
#
# Install logger.sh to /opt/logger.sh
install -m 750 -o 0 -g 0 logger.sh /opt/logger.sh
cat >>/etc/sudoers <<-'EOF'

	# Run the logger script as root (needed to send log to secure locations, users are lowered to their original users/privileges)
	ALL ALL=(ALL) SETENV: NOPASSWD: /opt/logger.sh
EOF
#
# Allow passing of necessary variables through sudo
cat >>/etc/sudoers <<-'EOF'

	# Allow passthrough of SSH_* variables to programs ran via sudo for better forensics.
	Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_ORIGINAL_COMMAND"
EOF
#
# Install the log-locker service
install -m 640 -o 0 -g 0 log-locker/log-locker.service /etc/systemd/system/log-locker.service
install -m 640 -o 0 -g 0 log-locker/log-locker.path /etc/systemd/system/log-locker.path
install -m 750 -o 0 -g 0 log-locker/log-locker.sh /opt/log-locker.sh
systemctl enable --now log-locker.path
#
# Install the file-locker service
install -m 640 -o 0 -g 0 file-locker/file-locker.service /etc/systemd/system/file-locker.service
install -m 750 -o 0 -g 0 file-locker/file-locker.sh /opt/file-locker.sh
systemctl enable --now file-locker.service
#
# Enable the session logger
cat >>/etc/ssh/sshd_config <<-'EOF'

	# Force all users into terminal logger
	ForceCommand sudo /opt/logger.sh
EOF
#
# Get excluded users
read -erp 'Enter the usernames of users to exclude from the logger (supports the username@ip format) (space-separated): ' -a exclusions
#
# Set up user exclusions
for user in "${exclusions[@]}"; do
	cat >>/etc/ssh/sshd_config <<-EOF

		# Exclude user from logger script
		Match User ${user}
		    ForceCommand none
	EOF
done
#
# Restart SSH/SSHD (svc name depends on distro/age of distro)
systemctl restart ssh
systemctl restart sshd