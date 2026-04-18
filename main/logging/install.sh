#!/usr/bin/env bash
# Install the logging directory
mkdir -p /var/log/sessions
chown root:root /var/log/sessions
chmod 700 /var/log/sessions
#
# Install logger.sh to /opt/logger.sh
install -m 755 -o root -g root logger.sh /opt/logger.sh
cat >>/etc/sudoers <<-'EOF'

# Run the logger script as root (needed to send log to secure locations, users are lowered to their original users/privileges)
ALL ALL=(ALL) SETENV: NOPASSWD: /opt/logger.sh'
EOF
#
# Allow passing of necessary variables through sudo
cat >>/etc/sudoers <<-'EOF'

	# Allow passthrough of SSH_* variables to programs ran via sudo for better forensics.
	Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_ORIGINAL_COMMAND"
EOF
# Install the log-locker service
install -m 600 -o root -g root log-locker/log-locker.service /etc/systemd/system/log-locker.service
install -m 600 -o root -g root log-locker/log-locker.path /etc/systemd/system/log-locker.path
install -m 700 -o root -g root log-locker/log-locker.sh /opt/log-locker.sh
systemctl enable --now log-locker.path
#
# Install the hist-locker service
install -m 600 -o root -g root file-locker/file-locker.service /etc/systemd/system/file-locker.service
install -m 700 -o root -g root file-locker/file-locker.sh /opt/file-locker.sh
systemctl enable --now hist-locker.service
#
# Enable the session logger
tee -a /etc/ssh/sshd_config <<-'EOF'
	# Force all users into terminal logger
	ForceCommand /bin/sudo /opt/logger.sh
EOF
systemctl restart sshd
#
# Get excluded users
read -erp 'Enter the usernames of users to exclude from the logger (supports the user@0.0.0.0 format) (space-separated): ' -a exclusions
#
# Set up user exclusions
for user in "${exclusions[@]}"; do
	tee -a /etc/ssh/sshd_config <<-EOF
		# Exclude user from logger script
		Match User $user
		    ForceCommand sudo /opt/logger.sh
	EOF
done