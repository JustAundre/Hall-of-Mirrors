#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
#
# Environment Setup & Logging
#
# Source secure environment
. ./.allrc
#
# Source variables and functions exclusive to this general script
. ./.generalrc





#
# Package Updates & Management
#
clear
cat <<-'EOF'
	Next up: Package Updates & Management

	Help Pages:
	https://www.reddit.com/r/debian/comments/ok13mj/comment/h552i6a/
	https://docs.flatpak.org/en/latest/introduction.html
	https://en.wikipedia.org/wiki/Snap_(software)
EOF
#
# Update and force-reinstall critical packages
if confirm "Reinstall/install ${pkgs[*]} and update all native binaries, flatpaks and snaps"; then
	# Update all packages
	apt-get update --error-on=any || exit 5
	apt-get full-upgrade --no-install-recommends -y
	#
	# Install script dependencies
	secure_install "${hard_deps[@]}" || exit 6
	#
	# Install packages heavily encouraged to have installed
	for pkg in "${soft_deps[@]}"; do
		secure_install "$pkg"
		#
		# Start auditd logging
		systemctl restart auditd
		#
		# Enable unattended upgrades
		dpkg-reconfigure --priority=low unattended-upgrades
	done
	#
	# Update flatpaks and snap packages respectively
	command -v flatpak >/dev/null || flatpak update -y
	command -v snap >/dev/null || snap refresh
fi
#
# Uninstall hacking packages
if confirm 'Remove reconissance tools from the system (i.e. johntheripper, aircrack-ng, etc.)'; then
	apt-get remove --purge "${reconissiance_pkgs[@]}"
	apt-get autoremove --purge
fi
#
# Remove netcat and nc binaries manually
if confirm 'Hide the netcat binaries'; then
	for binary in '/usr/bin/nc /usr/bin/netcat'; do
		dpkg-divert --add --rename --divert "/usr/bin/$binary.quarantine" "/usr/bin/$binary"
	done
	dpkg-divert --list
fi





#
# Kernel Hardening
#
clear
cat <<-'EOF'
	Help Pages:
	https://www.tecmint.com/sysctl-command-examples/
EOF
if confirm 'Apply hardened kernel configurations'; then
	# Stage and apply generic and mostly non-breaking kernel parameters
	(
		set -e
		install -m 0640 -o root -g root -D general-confs/kernel.conf /etc/sysctl.d/99-security.conf
		sysctl -p /etc/sysctl.d/99-security.conf
		sysctl --system
	)
	#
	# Is IPv6 networking needed?
	if confirm 'Disable IPv6 networking'; then
		# If not, disable.
		(
			set -e
			install -m 0640 -o root -g root -D general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
			sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
			sysctl --system
		)
	fi
fi





#
# User & Group Auditing
#
if confirm 'Configure user & authentication management'; then
	# Get authorized users and administrator users
	cat <<-'EOF'
		ℹ️: Comma-seperated entries only (i.e. john,jane,chris)
		⚠️: Active Directory users not included!
	EOF
	read -rp 'Users allowed on the system: ' authorized
	read -rp 'Admins on the system: ' admins
	read -rp 'Groups exclusive to admins: ' administrative_groups
	#
	# Parse provided user input into arrays
	IFS=, read -ra authorized <<< "$authorized"
	IFS=, read -ra admins <<< "$admins"
	IFS=, read -ra administrative_groups <<< "$administrative_groups"
	#
	# Audit users & their groups
	clear
	for user in $(getent passwd | awk -F: '($1 != "root") && ($7 !~ /(nologin|false)$/) { print $1 }'); do
		# Skip user if user is the user running the script
		[[ "$user" == "$(logname)" ]] && continue
		#
		# Break the loop if any of the required variables are missing
		if [[ -z "$authorized" || -z "$admins" || -z "$administrative_groups" ]]; then
			echo '⚠️: Missing input for one of the 3 prompts; skipping user management...'
			break
		fi
		#
		# Check if user is authorized or an admin
		found='false'
		for authUser in "${authorized[@]}" "${admins[@]}"; do
			if [[ "$user" == "$authUser" ]]; then
				found='true'
				break
			fi
		done
		#
		# Delete unauthorized users
		if [[ "$found" == 'false' ]]; then
			if confirm "Delete local user ($user)"; then
				userdel "$user"
			fi
			continue
		fi
		#
		# Remove admin groups from non-admin authorized users
		is_admin='false'
		for admin in "${admins[@]}"; do
			if [[ "$user" == "$admin" ]]; then
				is_admin='true'
				break
			fi
		done
		#
		# Cleanly iterate through administrative_groups to remove user
		if [[ "$is_admin" == 'false' ]]; then
			for group in "${administrative_groups[@]}"; do
				gpasswd -d "$user" "$group"
			done
		fi
		#
		# No one should be in these groups
		for group in "${protected_groups[@]}"; do
			gpasswd -d "$user" "$group"
		done
	done
	#
	# Purge Crontabs
	clear
	if confirm 'Delete crontabs for all users (to remove persistent backdoors)'; then
		for user in $(getent passwd | cut -d: -f1); do
			crontab -ru "$user"
		done
	fi
	#
	# Demote users found with UID 0 that isn't root
	clear
	for uid_zero_user in "$(getent passwd | awk -F: '($3 == 0 && $1 != "root") { print $1 }')"; do
		if confirm "Should user ($uid_zero_user) have UID 0"; then
			usermod -u "$temp_id" "$uid_zero_user"
			(( temp_id-- ))
		fi
	done
	#
	# Demote groups with GID 0 that aren't named root
	clear
	for gid_zero_user in "$(getent group | awk -F: '($3 = 0 && $1 != "root") { print $1 }')"; do
		if confirm "Should ($gid_zero_user) have GID 0 (less risk than UID 0--still risky)"; then
			groupmod -g "$temp_id" "$gid_zero_user"
			(( temp_id-- ))
		fi
	done
fi





#
# PAM, Password Quality & Password Security
#
clear
cat <<-'EOF'
	Help Pages:
	https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/managing_smart_cards/pam_configuration_files
	https://unix.stackexchange.com/questions/461022/answer/461025
EOF
if confirm 'Configure PAM and password quality/age policies to secure defaults'; then
	(
		set -e
		#
		# Backup existing PAM pwquality template
		mv /usr/share/pam-configs/pwquality{,.disabled}
		#
		# Insert our PAM pwquality template and pwquality configuration
		install -m 0640 -o root -g root -D general-confs/pwquality /usr/share/pam-configs/pwquality
		install -m 0640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
		#
		# Update PAM configurations
		pam-auth-update --force --package
	)
	#
	# Reject login requests for users with no password
	sed -i 's/[[:space:]]*nullok//g' /usr/share/pam-configs/unix
	#
	# Enforce Password Age Policies (Applies exclusively to non-system users (UID >= 1000))
	for user in "$(getent passwd | awk -F: '$3 >= 1000 { print $1 }')"; do
		(
			# Skips the iterated user if they're the user running the script
			# Apply the password age restrictions to the user
			# Sets the date they last changed their password to current date to avoid accidental lockouts
			set -e
			[[ "$user" != "$SUDO_USER" ]]
			chage -m 7 -M 90 -W 14 "$user"
			chage -d $(date +%Y-%m-%d) "$user"
		)
	done
	#
	# Apply global defaults via login.defs
	for entry in "${login_def_configs[@]}"; do
		safe_add "$entry" /etc/login.defs
	done
	#
	# Migrate stray hashes from passwd to shadow
	# Check for duplicate users on the system and prompt for rectification
	pwconv
	pwck -r
fi





#
# Default Firewall Rules (UFW)
#
clear
cat <<-'EOF'
	Help Pages:
	https://help.ubuntu.com/community/UFW
EOF
if confirm 'Configre default firewall rules via UFW (Uncomplicated Firewall)';
	(
		set -e
		#
		# Ensures necessary kernel modules are loaded
		for module in "${firewall_kernel_modules[@]}"; do
			lsmod |
				grep -q "^${module}" ||
				modprobe "$module"
		done
		#
		# Default Rules
		ufw reset
		ufw --force enable
		ufw default deny incoming
		ufw default allow outgoing
	)
fi





#
# Service Management
#
# NOTE: CAN BE IMPROVED
clear
cat <<-'EOF'
	Next up: Service Management

	Help Pages:
	https://serverfault.com/questions/840999
EOF
pause
#
# Uninstall insecure packages/services
if confirm 'Remove insecure/legacy packages and services'; then
	(
		set -e
		apt-get remove --purge -y "${insecure_pkgs[@]}"
		apt-get autoremove --purge
	)
	for service in "${insecure_services[@]}"; do
		decommission "$service"
	done
fi
#
# Ask for services which are to be removed
if confirm 'Audit every service on the system'; then
	removed_service=$(checklist 'Choose services to REMOVE' checklist "${services[@]}")
	for service in "${services[@]}"; do
		# Mark any service that was selected to be removed, to be removed.
		is_del=
		for kept_service in $removed_service; do
			if [[ "$service" == "$kept_service" ]]; then
				is_del=true
				break
			fi
		done
		#
		# If service was marked to be removed, uninstall if possible; if not, fallback to disable and masking.
		if [[ "$is_del" == 'true' ]]; then
			service_file=$(systemctl show -p FragmentPath --value "$service")
			if [[ -f "$service_file" ]]; then
				service_pkg=$(dpkg -S "$service_file" | cut -d: -f1)
				apt-get remove --purge -y "$service_pkg" || decommission "$service"
			fi
		else
			# If not removed/disabled, configure some small patches if patches for the service exists.
			case "$service" in
				mysql)
					sysdpatch mysql
				;;
				mariadb)
					sysdpatch mariadb
				;;
				postgresql)
					sysdpatch postgresql
				;;
				apache2)
					(
						set -e
						sysdpatch apache2
						install -m 0640 -o root -g root ./general-confs/apache2.conf /etc/apache2/conf-enabled/99-security.conf
					)
				;;
			esac
		fi
	done
fi
#
# Apply SystemD drop-ins for misc. services
sysdpatch cron
sysdpatch mosquitto
sysdpatch systemd-udevd
#
# Reload SystemD
systemctl daemon-reload





#
# Filesystem & Permission Tweaks
#
clear
cat <<-'EOF'
	Next up: Filesystem & Permission Tweaks

	Help Pages:
	https://www.redhat.com/en/blog/linux-file-permissions-explained
EOF
pause
#
# Add Sticky Bit to world-writable directories
find / -xdev -type d -perm -0002 ! -perm -1000 -exec chmod -f +t {} +
#
# For files with an invalid owner user/group, change the owner user/group to root
find / -xdev \( -nouser -o -nogroup \) -exec chown -h root:root {} +
#
# Remove broken symlinks
find / -xdev -xtype l -exec rm {} +
#
# Fix file permissions for identity management files
chown root:root /etc/passwd /etc/group /etc/sudoers
if grep -qE '^shadow:' /etc/group; then
	chown root:shadow /etc/shadow /etc/gshadow
	chmod -f 640 /etc/shadow /etc/gshadow
else
	chown root:root /etc/shadow /etc/gshadow
	chmod -f 600 /etc/shadow /etc/gshadow
fi
chmod -f 644 /etc/passwd /etc/group
chmod -f 440 /etc/sudoers
#
# Ensure only root can read the bootloader config
chown root:root /boot/grub/grub.cfg ||\
	chown root:root /boot/grub2/grub.cfg
chmod -f 700 /boot
chmod -f 600 /boot/grub/grub.cfg ||
	chmod -f 600 /boot/grub2/grub.cfg
chmod -f o-rx /boot
#
# Secure cron tabs and directories
chown root:root /etc/crontab /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d /etc/cron.allow /etc/at.allow
chmod -f 600 /etc/crontab
chmod -f 700 /etc/cron.hourly /etc/cron.daily /etc/cron.weekly /etc/cron.monthly /etc/cron.d
#
# Prevent non-root users from viewing kernel symbol maps
chmod -f 600 /boot/System.map-*
#
# Secure sudoers configuration
chown -R root:root /etc/sudoers.d
chmod -f 750 /etc/sudoers.d
chmod -f 440 /etc/sudoers.d/*
#
# Secure SSH configurations
chown -R root:root /etc/ssh /etc/ssh/sshd_config /etc/ssh/sshd_config.d
chmod -f 700 /etc/ssh /etc/ssh/sshd_config.d
chmod -f 600 /etc/ssh/*_key /etc/ssh/sshd_config /etc/cron.allow /etc/at.allow /etc/ssh/sshd_config.d/*.conf
chmod -f 644 /etc/ssh/*.pub
#
# Secure MOTD/banners are secured
chown root:root /etc/issue /etc/issue.net /etc/motd
chmod -f 644 /etc/issue /etc/issue.net /etc/motd
#
# Ensure log files are secured
chown root:root /var/log
chmod -f 750 /var/log
#
# Secure rsyslog or syslog-ng configs
chown root:root /etc/rsyslog.conf /etc/rsyslog.d/*
chmod -f 640 /etc/rsyslog.conf /etc/rsyslog.d/*
#
# Secure Auditd logs and configs
chown root:root /etc/audit/audit.rules /etc/audit/auditd.conf
chmod -f 640 /etc/audit/audit.rules /etc/audit/auditd.conf
#
# Restrict dmesg access
chmod -f 700 /bin/dmesg || chmod -f 700 /usr/bin/dmesg
#
# Secure existing home directories
chown root:root /root
chmod -f 700 /home/* /root
#
# Secure global shell profiles
chown root:root /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
chmod -f 644 /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
#
# Ensure sticky-bit on world-writable dirs
chmod -f +t /tmp /var/tmp /dev/shm




#
# Lockout Policies
#
clear
cat <<-'EOF'
	Next up: Lockout Policies

	Help Pages:
	https://linux.die.net/man/8/faillock
EOF
#
# Lock out an account temporarily with 3 consecutive bad passwords
if confirm 'Enable account lockout policies via faillock'; then
	(
		set -e
		install -m 0640 -o root -g root -D/general-confs/faillock /usr/share/pam-configs/faillock
		install -m 0640 -o root -g root -D general-confs/faillock_reset /usr/share/pam-configs/faillock_reset
		install -m 0640 -o root -g root -D general-confs/faillock_notify /usr/share/pam-configs/faillock_notify
		pam-auth-update --package
	)
fi
#
# Disable guest & automatic login in LightDM
if [[ -d /etc/lightdm ]]; then
	echo '🚧: LightDM found--disabling guest & automatic login...'
	sed -Ei 's/^# allow-guest.*/allow-guest=false/' /etc/lightdm/lightdm.conf
	sed -Ei 's/^# AutomaticLogin.*/AutomaticLogin=false/' /etc/lightdm/lightdm.conf
fi
#
# Apply a strong MOTD
if confirm 'Apply a strong MOTD'; then
	(
		set -e
		install -m 0640 -o root -g root -D general-confs/motd /etc/motd
		install -m 0640 -o root -g root -D general-confs/motd /etc/issue
		install -m 0640 -o root -g root -D general-confs/motd /etc/issue.net
	)
fi




#
# Exit
#
# Clear terminal & exit successfully
clear
exit 0