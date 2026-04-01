# Install the logging directory
mkdir -p /var/log/sessions
chown root:root /var/log/sessions
chmod 700 /var/log/sessions
#
# Install logger.sh to /opt/logger.sh
install -m 755 -o root -g root logger.sh /opt/logger.sh
echo 'ALL ALL=(ALL) SETENV: NOPASSWD: /opt/logger.sh' >> /etc/sudoers
#
# Allow passing of necessary variables through sudo
echo 'Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_ORIGINAL_COMMAND"' >> /etc/sudoers
#
# Install the log-locker service
install -m 600 -o root -g root log-locker/log-locker.service /etc/systemd/system/log-locker.service
install -m 600 -o root -g root log-locker/log-locker.timer /etc/systemd/system/log-locker.path
install -m 700 -o root -g root log-locker/log-locker.sh /opt/log-locker.sh
systemctl enable --now log-locker.path
#
# Install the hist-locker service
install -m 600 -o root -g root hist-locker/file-locker.service /etc/systemd/system/file-locker.service
install -m 700 -o root -g root hist-locker/file-locker.sh /opt/file-locker.sh
systemctl enable --now hist-locker.service
#
# Enable the session logger
tee -a /etc/ssh/sshd_config <<-'EOF'
	# Force all users into terminal logger
	ForceCommand /opt/logger.sh
EOF
systemctl restart sshd
#
# Get excluded users
read -rp 'Type the usernames of users you wish to exclude from the logger (CSV-formatted): ' exclusions
IFS=, read -ra exclusions <<< "$exclusions"
#
# Set up user exclusions
for user in "$exclusions"; do
	tee -a /etc/ssh/sshd_config <<-EOF
		# Exclude user from logger script
		Match User $exclusion
		    ForceCommand sudo /opt/logger.sh
	EOF
done