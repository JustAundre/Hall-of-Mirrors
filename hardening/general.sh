#!/usr/bin/env bash
#
# Environment Setup & Logging
#
# Source helper functions and variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
. .generalrc




#
# Questionaire
#
# Explain how y/n priority works
echo '[y/n] prompts have either the Y or N capitalized to indicate which is the default; but never both.'
#
# Install script dependencies
confirm 'This script has dependencies; install' "${hard_deps[*]}\n(See above for aforementioned 'dependencies')" &&
	deps=y
#
# Install updates
confirm 'Update system packages, flatpaks & snaps' &&
	upd=y
#
# Remove reconissiance packages
confirm 'Remove reconissiance packages' "${reconissiance_pkgs[*]}\n(See above for aforementioned 'packages')" &&
	del_recon_pkgs=y
#
# Remove risky packages
confirm 'Remove legacy/risky *packages*' "${risky_svcs[*]}\n(See above for aforementioned 'services')" &&
	del_bad_pkgs=y
#
# Remove risky services
confirm 'Remove legacy/risky *services*' "${risky_pkgs[*]}\n(See above for aforementioned 'packages')" &&
	del_bad_svcs=y
#
# Audit SystemD services
if confirm 'Audit SystemD services'; then
	service_review=y
	mapfile -t flagged_services < <(checklist 'Select services to REMOVE' checklist "${services[@]}")
fi
#
# Whether to mask vi/vim, netcat/nc or chpasswd
confirm 'Mask vi/vim' &&
	to_be_masked+=(
		/usr/bin/vim
		/usr/bin/vi
		/bin/vi
		/usr/local/bin/vim
		/usr/local/bin/vi
		/usr/sbin/vim
	)
confirm 'Mask netcat/nc' &&
	to_be_masked+=(
		/usr/bin/nc
		/usr/bin/netcat
		/bin/nc
		/usr/local/bin/nc
		/usr/local/bin/netcat
	)
confirm 'Mask chpasswd' &&
	to_be_masked+=(
		/usr/bin/chpasswd
		/usr/sbin/chpasswd
		/sbin/chpasswd
	)
#
# Whether to preconfigure SysCTL with non-destructive values
confirm 'Configure kernel /w SysCTL' &&
	sysctl=y
#
# Whether to disable IPv6 via SysCTL
[[ -n "${sysctl}" ]] &&
	confirm 'Disable IPv6 via SysCTL' &&
	no_ipv6=y
#
# Whether to apply general fixes to filesystem ownership & modes
confirm 'Apply non-destructive filesystem permission & ownership fixes' &&
	fix_perms=y
#
# Catch logical fallacies in /etc/passwd, /etc/shadow, /etc/gshadow & /etc/groups.
# - i.e. Group specified in gshadow but not groups
# - i.e. User doesn't exist in passwd but is referenced as a member of a group in groups
confirm 'Check local user information for technical inconsistencies' "$(
	man pwck |
		head -n 25 |
		tail -n 16
	)" &&
		pwck=y
confirm 'Move possible hashes from passwd/group (public) files to shadow/gshadow (private) files' &&
	mv_hash=y
#
# Whether to audit users
confirm 'Audit local users' &&
	audit_users=y
[[ -n "${audit_users}" ]] &&
	confirm 'Lock & remove password for user (root)' &&
	lock_root=y
confirm 'Reconfigure PAM & /etc/login.defs' &&
	pam_reconfig=y
#
# Whether to audit scheduled tasks
if
	[[ -n "${audit_users}" ]] &&
	confirm 'Review & delete scheduled tasks' "(This prompt is unique in that your responses here take effect immediately unlike the others)\nYou'll be manually reviewing these scheduled tasks:\nCron files\nCrontabs\nSystemD timers\nYou'll then be asked whether the source file should be deleted after reviewing.";
then
	# Cron files
	find /etc/cron* -maxdepth 1 -type f -exec nano {} \; -exec rm -i {} \;
	#
	# Crontabs
	mapfile -t all_usernames < <(
		cat /etc/passwd |
			cut -d: -f1
	)
	for u in "${all_usernames[@]}"; do
		crontab -eu "${u}"
		crontab -eri "${u}"
	done
	#
	# SystemD timers
	find /etc/systemd/system -maxdepth 1 -name '*.timer' -type f -exec nano {} \; -exec rm -i {} \; -exec systemctl disable --now {} \;
fi
#
# Whether to configure firewall rules
if confirm 'Configure the firewall'; then
	firewall_config=y
	firewall="$(checklist 'Which firewall are we using?' radiolist "${firewall_options[@]}")"
fi
#
# Whether to configure resource limitations for users
if confirm 'Configure resource limitations for users'; then
	resource_cap=y
	#
	# Alert the user of their system memory capacity
	# ...& of the limitations of the input
	cat <<-EOF
		i: You have ${max_mem} megabytes (MB) of RAM.
		i: Please give your response in a percentage, 1 through 100 as an integer without any decimals, prefixes or suffixes.
		i: Individual requirements must be less than (non-inclusive) the collective requirements
	EOF
	#
	# Prompt for collective (all/group) limitations
	read -n3 -erp 'Enter % of memory would you like all users on the system to be able to COLLECTIVELY use: ' collective_mem
	read -n3 -erp 'Enter % of CPU would you like all users on the system to be able to COLLECTIVELY use: ' collective_cpu
	#
	# Prompt for individual (per-person) limitations
	while [[
		-z "${individual_mem}" ||
		"${individual_mem}" -gt 100 ||
		individual_mem -le collective_mem
	]]; do
		read -n3 -erp 'Enter % of the max memory would you like an individual user to be able to use?: ' individual_mem
	done
	while [[
		-z "${individual_cpu}" ||
		${individual_cpu} -gt 100 ||
		${individual_cpu} -le ${collective_cpu}
	]]; do
		read -n3 -erp 'Enter % of the CPU would you like an individual user to be able to use?: ' individual_cpu
	done
	#
	# Prompt for "THE" administrative group
	admin_group=placeholder
	while [[ -z "$(getent group "${admin_group}")" ]]; do
		read -erp 'What is THE administrative group? (e.x. wheel, sudo, etc.): ' admin_group
	done
fi
#
# Whether to install a well-formatted & extensive but brief MOTD file
confirm 'Install a well-formated & extensive but brief MOTD file' &&
	motd=y





#
# Package Updates & Management
#
# Install script dependenciesd
[[ -n "${deps}" ]] &&
	secure_install "${hard_deps[@]}" ||
	alt_exit 1
#
# Run updates (in the bg)
[[ -n "${upd}" ]] && (
	# Update APT updates
	apt-get update
	apt-get full-upgrade --no-install-recommends -y
	#
	# Update flatpaks (if present)
	hash flatpak &&
		flatpak update -y
	#
	# Update snaps (if present)
	hash snap &&
		snap refresh
) &
#
# Uninstall reconissiance packages (in the bg)
[[ -n "${del_recon_pkgs}" ]] && (
	apt-get autoremove --purge "${reconissiance_pkgs[@]}"
) &
#
# Mask selected risky (in the bg)
[[ -n "${to_be_masked[*]}" ]] && (
	for binary in "${to_be_masked[@]}"; do
		(
			set -e
			stat "${binary}"
			update-alternatives --install "${binary}" "$(basename "${binary}")" /bin/false 1
			update-alternatives --set "$(basename "${binary}")" /bin/false
		)
	done
) &





#
# Service Management
#
# Uninstalls risky packages (in the bg)
[[ -n "${del_bad_pkgs}" ]] && (
	apt-get autoremove --purge -y "${risky_pkgs[@]}"
) &
#
# Disables & masks risky services (in the bg)
[[ -n "${del_bad_svcs}" ]] && (
	for service in "${risky_svcs[@]}"; do
		decommission "${service}"
	done
) &
#
# Remove flagged services (if selected) (in the bg)
[[ -n "${service_review}" ]] && (
	for service in "${services[@]}"; do
		# Mark any service that was selected to be removed, to be removed.
		for flagged_service in "${flagged_services[@]}"; do
			if [[ "${service}" == "${flagged_service}" ]]; then
				# Attempt to remove package behind service
				# Will just decommission service file if cannot locate resposible package.
				apt-get remove --purge -y "$(
					dpkg -S "/etc/systemd/system/${flagged_service}.service" |
						cut -d: -f1
				)" ||
					decommission "${flagged_service}"
			elif [[ -z "${is_del}" ]]; then
				# If not removed, patch service with a secure SystemD override.
				svc_patch "${service}"
			fi
		done
	done
	#
	# Apply SystemD drop-ins for misc. services
	svc_patch cron
	svc_patch mosquitto
	svc_patch systemd-udevd
	#
	# Reload SystemD
	systemctl daemon-reload
) &





#
# Kernel Hardening
#
# Apply generic sysctl hardening values
# (Not likely to cause issues)
# (in the bg)
[[ -n "${sysctl}" ]] && (
	# Stage & apply generic & mostly non-breaking kernel parameters
	install -m 640 -o root -g root -D general-confs/kernel.conf /etc/sysctl.d/99-security.conf
	sysctl -p /etc/sysctl.d/99-security.conf
	sysctl --system
) &
#
# Disables IPv6 if requested
# (in the bg)
[[ -n "${no_ipv6}" ]] && (
	install -m 640 -o root -g root -D general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
	sysctl -p /etc/sysctl.d/99-disable-ipv6.conf
	sysctl --system
) &





#
# Access Control Repair
#
# Repair filesystem ownership & modes
# (in the bg)
[[ -n "${fix_perms}" ]] && (
	# Add Sticky Bit to world-writable directories
	find / -xdev -type d -perm -0002 ! -perm -1000 -exec chmod -h +t {} +
	#
	# For files with an invalid owning user or group, change the owning user & group to root
	find / -xdev \( -nouser -o -nogroup \) -exec chmod 640 {} + -exec chown -h root:root {} +
	#
	# Remove broken symlinks
	find / -xdev -xtype l -exec rm {} +
	#
	# Ensure sticky-bit on world-writable dirs
	chmod -h +t /tmp /var/tmp /dev/shm
	#
	# Fix permissions for files regarding identity management
	chown root:root /etc/passwd /etc/group /etc/sudoers
	if grep -qE '^shadow:' /etc/group; then
		chown root:shadow /etc/shadow /etc/gshadow
		chmod -h 640 /etc/shadow /etc/gshadow
	else
		chown root:root /etc/shadow /etc/gshadow
		chmod -h 600 /etc/shadow /etc/gshadow
	fi
	chmod -h 644 /etc/passwd /etc/group
	#
	# Ensure only root can read the bootloader config
	find /boot -type f -exec chown root:root {} + -exec chmod 640 {} +
	find /boot -type d -exec chown root:root {} + -exec chmod 750 {} +
	#
	# Ensure SystemD unit files are secure
	find /etc/systemd/system -type f -exec chown root:root {} + -exec chmod -h 640 {} +
	find /etc/systemd/system -type d -exec chown root:root {} + -exec chmod -h 750 {} +
	#
	# Secure cron tabs & directories
	chown root:root /etc/cron* /etc/at.allow
	chmod -h 750 /etc/cron.* /etc/at.allow
	chmod -h 640 /etc/crontab
	#
	# Secure sudoers configuration
	chown -R root:root /etc/sudoers /etc/sudoers.d
	chmod -h 640 /etc/sudoers
	chmod -h 750 /etc/sudoers.d
	chmod -Rh 640 /etc/sudoers.d
	#
	# Restrict dmesg access
	chown root:root /bin/dmesg /usr/bin/dmesg
	chmod -h 700 /bin/dmesg /usr/bin/dmesg
	#
	# Secure SSH configurations
	find /etc/ssh -type f -exec chown root:root {} + -exec chmod -h 600 {} +
	find /etc/ssh -type d -exec chown root:root {} + -exec chmod -h 700 {} +
	chmod -h 644 /etc/ssh/*.pub
	#
	# Secure MOTD/banners are secured
	chown root:root /etc/issue /etc/issue.net /etc/motd
	chmod -h 644 /etc/issue /etc/issue.net /etc/motd
	#
	# Ensure log files are secured
	chown root:root /var/log
	chmod -h 750 /var/log
	#
	# Secure rsyslog or syslog-ng configs
	chown root:root /etc/rsyslog.conf /etc/rsyslog.d/*
	chmod -h 640 /etc/rsyslog.conf /etc/rsyslog.d/*
	#
	# Secure Auditd logs & configs
	find /etc/audit -type f -exec chown root:root {} + -exec chmod -h 640 {} +
	find /etc/audit -type d -exec chown root:root {} + -exec chmod -h 750 {} +
	#
	# Secure global shell profiles
	chown root:root /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
	chmod -h 644 /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
	#
	# Secure existing home directories
	chown root:root /root
	chmod -h 700 /home/* /root
) &





#
# User & Group Auditing
#
# (in the bg)
if [[ -n "${audit_users}" ]]; then
	# Delete users flagged as to be deleted
	# Delete passwords of users flagged to have their password removed
	# Lock users flagged to be locked
	# Prompt to change the shell for users flagged to be reshelled
	# Prompt to change the UID of users flagged to be reUIDed
	# Prompt to change the primary & supplemental groups of users flagged to be regrouped
	for u in "${users_del[@]}"; do
		userdel -rf "${u}" &
	done
	for u in "${users_nullpass[@]}"; do
		passwd "${u}" -d &
	done
	for u in "${users_lock[@]}"; do
		passwd "${u}" -l &
	done
	for u in "${users_reshell[@]}"; do
		while [[ ! -x "${shell}" ]]; do
			read -erp 'Enter the path to the new shell: ' shell
		done
		usermod -s "${shell}" "${u}" &
	done
	for u in "${users_reuid[@]}"; do
		while [[
				"${uid}" =~ ^[0-9]+$ &&
				-n "$(getent passwd "${uid}")"
			]];
		do
			read -erp 'Enter the new UID: ' uid
		done
		usermod -s "${uid}" "${u}" &
	done
	for u in "${users_regroup[@]}"; do
		while [[ -z "$(getent passwd "${primary_group}")" ]]; do
			read -erp 'Enter new primary group: ' primary_group
		done
		stop=placeholder
		while [[ -n "${stop}" ]]; do
			read -erp 'Enter new supplemental groups (space-separated): ' -a supplemental_groups
			for group in "${supplemental_groups[@]}"; do
				[[ -n "$(getent passwd "${group}")" ]] &&
					stop=
			done
		done
		usermod -g "${primary_group}" "${u}" &
		usermod -G "${supplemental_groups[*]// /,}" "${u}" &
	done
fi
#
# Secures root user
# (L)ocks user (root) & (d)eletes their password
[[ -n "${lock_root}" ]] &&
	passwd root -ld &





#
# Firewall Rules
#
if [[ -n "${firewall_config}" ]]; then
	# Ensures necessary kernel modules are loaded
	for module in "${firewall_kernel_modules[@]}"; do
		lsmod |
			grep -q "^${module}" ||
			modprobe "${module}"
	done
	#
	# Configure baseline ruleset (in the bg)
	# Uncomplicated Firewall/ufw
	# (Unfortunately UFW isn't flexible enough to block certain ICMP ping types)
	if [[ "${firewall}" == UFW ]]; then
		(
			set -e
			#
			# Start the firewall
			systemctl unmask ufw
			systemctl restart --now ufw
			ufw --force enable
			#
			# Reset the firewall
			ufw reset
			#
			# Deny all incoming, allow all outgoing.
			ufw default deny incoming
			ufw default allow outgoing
		) &
	# FirewallD/firewall-cmd
	elif [[ "${firewall}" == FirewallD ]]; then
		(
			set -e
			# Start the firewall
			systemctl unmask firewalld
			systemctl restart --now firewalld
			#
			# Reset the firewall
			firewall-cmd --reset-to-defaults
			firewall-cmd --set-default-zone public
			#
			# Deny all incoming, allow all outgoing.
			firewall-cmd --permanent --load-zone-defaults public
			#
			# Block ICMP echo requests & timestamp requests/replies
			firewall-cmd --permanent --add-icmp-block echo-request
			firewall-cmd --permanent --add-icmp-block timestamp-reply
			firewall-cmd --permanent --add-icmp-block timestamp-request
		) &
	else
		echo 'E: Unsupported firewall software.'
	fi
	#
	# Prompt to whitelist any remaining ports/services
	ports=placeholder
	while [[
		-n "$(
			for port in "${ports[@]}"; do
				[[ ! "${port}" =~ ^[0-9]{1,5}(-[0-9]{1,5})?$ ]] &&
					echo placeholder
			done
		)" ||
		-z "${ports[*]}"
	]]; do
		read -erp 'Enter any remaining port numbers to allow in: ' -a ports
	done
	for port in "${ports[@]}"; do
		# Whitelist ports
		if [[ "${firewall}" == UFW ]]; then
			ufw allow in "${port}/tcp"
		elif [[ "${firewall}" == FirewallD ]]; then
			firewall-cmd --permanent --add-port "${port}/tcp" &
		else
			echo 'E: Unsupported firewall software.'
		fi
	done
	#
	# Apply changes (FirewallD exclusive)
	[[ "${firewall}" == FirewallD ]] &&
		firewall-cmd --reload &
fi





#
# Lockout Policies
#
# Configure PAM with secure defaults (in the bg)
if [[ -n "${pam_reconfig}" ]]; then
	# RHEL-like distros
	if hash authselect; then
		(
			set -e
			#
			# Configure PAM /w secure defaults enabled & further configure password QA
			authselect select sssd with-faillock with-pamaccess with-pwhistory with-pwquality with-mkhomedir with-sudo without-nullok --force
			install -m 640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
			#
			# Regenerate PAM configurations /w previous configuration
			authselect apply-changes
		)
	# Debian-like distros
	elif hash pam-auth-update; then
		(
			set -e
			#
			# Insert password QA configuration
			install -m 640 -o root -g root -D general-confs/pwquality /usr/share/pam-configs/pwquality
			install -m 640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
			#
			# Insert faillock configuration
			install -m 640 -o root -g root -D general-confs/faillock /usr/share/pam-configs/faillock
			install -m 640 -o root -g root -D general-confs/faillock_reset /usr/share/pam-configs/faillock_reset
			install -m 640 -o root -g root -D general-confs/faillock_notify /usr/share/pam-configs/faillock_notify
			#
			# Reject logins for users with no password
			sed -i 's/[[:space:]]*nullok//g' /usr/share/pam-configs/unix
			#
			# Update PAM configurations
			pam-auth-update --force --package
		) &
	else
		echo 'Your PAM configuration setup is unsupported.'
	fi
	#
	# Enforce password age policies (Applies exclusively to non-system users (UID >= 1000))
	mapfile -t nonsys_users < <(awk -F: '$2 !~ /^(!|\*|$)/ { print $1 }' /etc/shadow)
	for u in "${nonsys_users[@]}"; do
		# Skips the iterated user if they're the user running the script
		# Apply the password age restrictions to the user
		# Sets the date they last changed their password to current date to avoid accidental lockouts
		[[ "${u}" != "${SUDO_USER}" ]] &&
			chage -m 7 -M 90 -W 14 "${u}" &&
			chage -d "$(date +%Y-%m-%d)" "${u}"
	done
	#
	# Apply global defaults via login.defs
	for entry in "${login_def_configs[@]}"; do
		safe_add "${entry}" /etc/login.defs
	done
	#
	# Migrate stray hashes from passwd to shadow & from group to gshadow
	# Check for duplicate users on the system & prompt for rectification
	if [[ -n "${mv_hash}" ]]; then
		pwconv
		grpconv
	fi
	[[ -n "${pwck}" ]] &&
		pwck
	#
	# Disable guest & automatic login in LightDM
	if [[ -f /etc/lightdm/lightdm.conf ]]; then
		safe_add 'allow-guest false' /etc/lightdm/lightdm.conf
		safe_add 'AutomaticLogin false' /etc/lightdm/lightdm.conf
	fi
fi





#
# Resource Management
#
# Prompt for external information
if [[ -n "${resource_cap}" ]]; then
	# Parse given information into configuration
	# ...& install configuration into the system
	sed -e "s/foo/${collective_mem}/g" -e "s/bar/${collective_cpu}/g" general-confs/slice-shared.conf |
		install -m 640 -o root -g root /dev/stdin /etc/systemd/system/user.slice.d/override.conf
	sed -e "s/foo/${individual_mem}/g" -e "s/bar/${individual_cpu}/g" general-confs/slice-individual.conf |
		install -m 640 -o root -g root /dev/stdin /etc/systemd/system/user-.slice.d/override.conf
	sed "s/wheel/${admin_group}/g" general-confs/limits.conf |
		install -m 644 -o root -g root /dev/stdin /etc/security/limits.conf
	#
	# Reload SystemD
	systemctl daemon-reload
fi





#
# Message of the Day
#
[[ -n "${motd}" ]] &&
	for banner_file in "${banner_files[@]}"; do
		install -m 640 -o root -g root -D general-confs/motd "${banner_file}"
	done





#
# Exit
#
# Wait for all children to exit
echo 'i: Started work on all fixes dc, this may take a while depending on your selections...'
wait
#
# Exit & print success banner
# and the logs from this session.
alt_exit 0