#!/usr/bin/env bash





#
# Register Shellcam
#
# Create the logging directory
mkdir -p /var/log/sessions
chown 0:0 /var/log/sessions
chmod 640 /var/log/sessions
#
# Allow shellcam to be ran as root by all users without a password (needed to send log to secure locations, users are lowered to their original users/privileges)
# Allow passing of necessary variables through sudo
# Register shellcam in a ForceCommand directive
{
	printf '%s\n%s' '# Run shellcam script as root w/o' 'ALL ALL=(ALL) SETENV: NOPASSWD: /opt/shellcam/main.sh'
	printf '%s\n\t%s' '# Allow passthrough of SSH_* variables to programs ran via sudo for better forensics.' 'Defaults env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_ORIGINAL_COMMAND"'
	printf '%s\n%s' '# Force all users into terminal logger' 'ForceCommand sudo /opt/shellcam/main.sh'
} >> /etc/sudoers
#
# Restart SSH(D)
systemctl restart sshd || systemctl restart ssh





#
# Protect Shellcam Logs
#
# Install monitor service
cd "$(dirname "${0}")" || exit 1
ln -v sc-monitor.service /etc/systemd/system/sc-monitor.service
ln -v sc-monitor.path /etc/systemd/system/sc-monitor.path
#
# Register and enable monitor service
systemctl daemon-reload
systemctl enable --now sc-monitor.service
systemctl enable --now sc-monitor.path
