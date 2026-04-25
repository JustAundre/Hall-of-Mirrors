#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
. .generalrc
#
# Helper functions to setup the environment for certain actions
env_svc_audit() {
	service_audit=i
	mapfile -t flagged_services < <(checklist 'Select services to REMOVE' checklist "${services[@]}")
}
env_mask() {
	# Define maskable binaries & other variables locally in advance
	local selected maskables=(
		vi/vim
		nc/ncat/netcat
		chpasswd
	)
	#
	# Make associative array in advance
	local -A selected_associative
	#
	# Prompt the user for which binaries to mask
	# Saves the response to an array.
	mapfile -t selected < <(checklist 'Select binaries to mask' checklist "${maskables[@]}")
	#
	# Marks selected binaries in the associative array for easy lookup
	for binary in "${selected[@]}"
	do
		selected_associative["${binary}"]=i
	done
	#
	# If a binary was selected, stage it for masking.
	[[ -n "${selected_associative[maskables[0]]}" ]] &&
		mask_staged+=(
			/usr/bin/vim
			/usr/bin/vi
			/bin/vi
			/usr/local/bin/vim
			/usr/local/bin/vi
			/usr/sbin/vim
		)
	[[ -n "${selected_associative[maskables[1]]}" ]] &&
		mask_staged+=(
			/usr/bin/nc
			/usr/bin/netcat
			/bin/nc
			/usr/local/bin/nc
			/usr/local/bin/netcat
		)
	[[ -n "${selected_associative[maskables[2]]}" ]] &&
		mask_staged+=(
			/usr/bin/chpasswd
			/usr/sbin/chpasswd
			/sbin/chpasswd
		)
}
env_schedule_audit() {
	# Cron files
	find /etc/cron* -maxdepth 1 -type f -exec nano {} \; -exec rm -i {} \;
	#
	# Crontabs
	# Enumerates all users on the system
	# Prompt to review/edit the crontab of each user
	# Prompt to delete the crontab of each user
	mapfile -t all_usernames < <(
		cat /etc/passwd |
			cut -d: -f1
	)
	for u in "${all_usernames[@]}"
	do
		crontab -eu "${u}"
		crontab -riu "${u}"
	done
	#
	# SystemD timers
	find /etc/systemd/system -maxdepth 1 -name '*.timer' -type f -exec nano {} \; -exec rm -i {} \;
	systemctl daemon-reload &
}
env_firewall() {
	firewall="$(checklist 'Which firewall are we using?' radiolist "${firewall_options[@]}")"
}
env_resource_limits() {
	# Alert the user of their system memory capacity
	# ... & of the limitations of the input
	cat <<-EOF
		i: You have ${system_memory} MB (megabytes) of RAM.
		i: Please give your response in a percentage, 1 through 100 as an integer without any decimals, prefixes or suffixes.
		i: Individual requirements must be less than (non-inclusive) the collective requirements
	EOF
	#
	# Localify variables in advance
	local collective_mem collective_cpu individual_mem individual_cpu
	#
	# Prompt for collective (all/group) limitations
	read -n3 -erp 'Enter % of memory would you like all users on the system to be able to COLLECTIVELY use: ' collective_mem
	read -n3 -erp 'Enter % of CPU would you like all users on the system to be able to COLLECTIVELY use: ' collective_cpu
	#
	# Prompt for individual (per-person) limitations
	while
		[[
			-z "${individual_mem}" ||
			"${individual_mem}" -gt 100 ||
			"${individual_mem}" -le "${collective_mem}"
		]]
	do
		read -n3 -erp 'Enter % of the max memory would you like an individual user to be able to use?: ' individual_mem
	done
	while
		[[
			-z "${individual_cpu}" ||
			"${individual_cpu}" -gt 100 ||
			"${individual_cpu}" -le "${collective_cpu}"
		]]
	do
		read -n3 -erp 'Enter % of the CPU would you like an individual user to be able to use?: ' individual_cpu
	done
	#
	# Prompt for "THE" administrative group
	while
		[[ -z "${admin_group}" ]] &&
		grep -q "${admin_group}:" /etc/group
	do
		read -erp 'What is THE administrative group? (e.x. wheel, sudo, etc.): ' admin_group
	done
}






#
# Questionaire
#
# Define what patches are available
patches=(
	'Run updates (apt, flatpak & snaps)'
	'Remove reconissiance packages'
	'Remove dated software'
	'Audit SystemD services'
	'Mask binaries'
	'Load secure SysCTL profile'
	'Disable IPv6 (via SysCTL profile)'
	'Fix filesystem permissions & ownership'
	'Check for user information inconsistencies'
	'Move password hashes from (public) /etc/passwd to (private) /etc/shadow'
	'Audit users'
	'Delete password for & lock root user'
	'Reconfigure PAM & /etc/login.defs'
	'Audit scheduled tasks'
	'Configure firewall'
	'Insert resource limitations (Max RAM, CPU, process fork count, etc.)'
	'Load comprehensive MOTD file'
)
#
# Shortforms to make the code more readable
declare -A shortforms=(
	[upd]="${patches[0]}"
	[recon]="${patches[1]}"
	[legacy]="${patches[2]}"
	[svcs]="${patches[3]}"
	[masking]="${patches[4]}"
	[sysctl]="${patches[5]}"
	[ipv6]="${patches[6]}"
	[perms]="${patches[7]}"
	[info_err]="${patches[8]}"
	[mv_hash]="${patches[9]}"
	[users]="${patches[10]}"
	[lock_root]="${patches[11]}"
	[pam]="${patches[12]}"
	[cron]="${patches[13]}"
	[firewall]="${patches[14]}"
	[resources]="${patches[15]}"
	[motd]="${patches[16]}"
)
#
# Ask what patches to apply
mapfile -t selected_audits < <(checklist 'Select patches to run' checklist "${patches[@]}")
#
# Associative array to act on selections
declare -A active
for selection in "${selected_audits[@]}"; do
	active["${selection}"]=i
done
#
# Whether to audit scheduled tasks
[[ -n "${selected_associative[shortforms[pam]]}" ]] &&
	env_schedule_audit
#
# Whether to configure firewall rules
[[ -n "${selected_associative[shortforms[cron]]}" ]] &&
	env_firewall
#
# Whether to configure resource limitations for users
[[ -n "${selected_associative[shortforms[resources]]}" ]] &&
	env_resource_limits





#
# Package Updates & Management
#
# Install script dependenciesd
secure_install "${hard_deps[@]}" ||
	exit 1
#
# Run updates (in the bg)
[[ -n "${selected_associative[patches[0]]}" ]] && (
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
[[ -n "${selected_associative[shortforms[upd]]}" ]] &&
	(apt-get autoremove --purge "${reconissiance_pkgs[@]}") &

# Removes/disables & masks risky services/packages (in the bg)
[[ -n "${selected_associative[shortforms[recon]]}" ]] && (
	apt-get autoremove --purge -y "${risky_pkgs[@]}"
	for service in "${risky_svcs[@]}"
	do
		decommission "${service}"
	done
) &
#
# Remove flagged services (if selected) (in the bg)
[[ -n "${selected_associative[shortforms[legacy]]}" ]] && (
	for service in "${services[@]}"
	do
		# Mark any service that was selected to be removed, to be removed.
		for flagged_service in "${flagged_services[@]}"
		do
			if
				[[ "${service}" == "${flagged_service}" ]]
			then
				# Attempt to remove package behind service
				# Will just decommission service file if cannot locate resposible package.
				apt-get remove --purge -y "$(
					dpkg -S "/etc/systemd/system/${flagged_service}.service" |
						cut -d: -f1
				)" ||
					decommission "${flagged_service}"
			elif
				[[ -z "${is_del}" ]]
			then
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
# Mask selected binaries (in the bg)
[[ -n "${selected_associative[shortforms[svcs]]}" ]] && (
	for binary in "${mask_staged[@]}"
	do
		(
			set -e
			stat "${binary}"
			update-alternatives --install "${binary}" "$(basename "${binary}")" /bin/false 1
			update-alternatives --set "$(basename "${binary}")" /bin/false
		)
	done
) &





#
# Kernel Hardening
#
# Apply generic sysctl hardening values
# (Not likely to cause issues)
# (in the bg)
[[ -n "${selected_associative[shortforms[sysctl]]}" ]] && (
	# Stage & apply generic & mostly non-breaking kernel parameters
	install -m 640 -o root -g root -D general-confs/kernel.conf /etc/sysctl.d/99-security.conf
	sysctl -f /etc/sysctl.d/99-security.conf
) &
#
# Disables IPv6 if requested
# (in the bg)
[[ -n "${selected_associative[shortforms[ipv6]]}" ]] && (
	install -m 640 -o root -g root -D general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
	sysctl -f /etc/sysctl.d/99-disable-ipv6.conf
) &
sysctl --system





#
# Access Control Repair
#
# Repair filesystem ownership & modes
# (in the bg)
[[ -n "${selected_associative[shortforms[perms]]}" ]] && (
	# Add Sticky Bit to world-writable directories
	find / -xdev -type d -perm -0002 ! -perm -1000 -exec chmod +t {} +
	#
	# For files with an invalid owning user or group, change the owning user & group to root
	find / -xdev \( -nouser -o -nogroup \) -exec chmod 640 {} + -exec chown root:root {} +
	#
	# Remove broken symlinks
	find / -xdev -xtype l -exec rm {} +
	#
	# Ensure sticky-bit on world-writable dirs
	chmod +t /tmp /var/tmp /dev/shm
	#
	# Fix permissions for files regarding identity management
	chown root:root /etc/passwd /etc/group /etc/sudoers
	if
		grep -q '^shadow:' /etc/group
	then
		chown root:shadow /etc/shadow /etc/gshadow
		chmod 640 /etc/shadow /etc/gshadow
	else
		chown root:root /etc/shadow /etc/gshadow
		chmod 600 /etc/shadow /etc/gshadow
	fi
	chmod 644 /etc/passwd /etc/group
	#
	# Ensure only root can read the bootloader config
	find /boot -type f -exec chown root:root {} + -exec chmod 640 {} +
	find /boot -type d -exec chown root:root {} + -exec chmod 750 {} +
	#
	# Ensure SystemD unit files are secure
	find /etc/systemd/system -type f -exec chown root:root {} + -exec chmod 640 {} +
	find /etc/systemd/system -type d -exec chown root:root {} + -exec chmod 750 {} +
	#
	# Secure cron tabs & directories
	chown root:root /etc/cron* /etc/at.allow
	chmod -R 750 /etc/cron.* /etc/at.allow
	chmod -R 640 /etc/crontab
	#
	# Secure sudoers configuration
	chown -R root:root /etc/sudoers /etc/sudoers.d
	chmod -R 640 /etc/sudoers
	chmod -R 750 /etc/sudoers.d
	chmod -R 640 /etc/sudoers.d
	#
	# Restrict dmesg access
	chown -R root:root /bin/dmesg /usr/bin/dmesg
	chmod -R 700 /bin/dmesg /usr/bin/dmesg
	#
	# Secure SSH configurations
	find /etc/ssh -type f -exec chown root:root {} + -exec chmod 600 {} +
	find /etc/ssh -type d -exec chown root:root {} + -exec chmod 700 {} +
	chmod -R 644 /etc/ssh/*.pub
	#
	# Secure MOTD/banners are secured
	chown -R root:root /etc/issue /etc/issue.net /etc/motd
	chmod -R 644 /etc/issue /etc/issue.net /etc/motd
	#
	# Ensure log files are secured
	chown -R root:root /var/log
	chmod -R 750 /var/log
	#
	# Secure rsyslog or syslog-ng configs
	chown -R root:root /etc/rsyslog.conf /etc/rsyslog.d/*
	chmod -R 640 /etc/rsyslog.conf /etc/rsyslog.d/*
	#
	# Secure Auditd logs & configs
	find /etc/audit -type f -exec chown root:root {} + -exec chmod 640 {} +
	find /etc/audit -type d -exec chown root:root {} + -exec chmod 750 {} +
	#
	# Secure global shell profiles
	chown -R root:root /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
	chmod -R 644 /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
	#
	# Secure existing home directories
	chown -R root:root /root
	chmod -R 700 /home/* /root
) &





#
# User & Group Auditing
#
if
	[[ -n "${selected_associative[shortforms[users]]}" ]]
then
	# Delete users flagged as to be deleted
	for u in "${users_del[@]}"
	do
		userdel -rf "${u}"
	done
	#
	# Delete passwords of users flagged to have their password removed
	for u in "${users_nullpass[@]}"
	do
		passwd "${u}" -d
	done
	#
	# Lock users flagged to be locked
	for u in "${users_lock[@]}"
	do
		passwd "${u}" -l
	done
	#
	# Prompt to change the shell for users flagged to be reshelled
	for u in "${users_reshell[@]}"
	do
		while
			[[ ! -x "${shell}" ]]
		do
			read -erp 'Enter the path to the new shell: ' shell
		done
		usermod -s "${shell}" "${u}"
	done
	#
	# Prompt to change the UID of users flagged to be reUIDed
	for u in "${users_reuid[@]}"
	do
		while
			[[ "${uid}" =~ ^[0-9]+$ ]] &&
			grep -qE "^[^:]+:[^:]+:${uid}" /etc/passwd
		do
			read -erp 'Enter the new UID: ' uid
		done
		usermod -s "${uid}" "${u}"
	done
	#
	# Change the primary & supplementary groups
	for u in "${users_regroup[@]}"
	do
		# Prompt for the new primary group
		while
			[[ -z "${primary_group}" ]] ||
			! grep -qE "^[^:]+:[^:]+:${primary_group}" /etc/group
		do
			read -erp 'Enter new primary group: ' primary_group
		done
		#
		# Prompt for the new supplementary groups
		while
			[[ -z "${stop}" ]]
		do
			read -erp 'Enter new supplemental groups (space-separated): ' -a supplemental_groups
			stop=i
			for group in "${supplemental_groups[@]}"
			do
				grep -qE "^[^:]+:[^:]+:${primary_group}" /etc/group ||
					stop=
			done
		done
		#
		# Change the groups
		usermod -g "${primary_group}" "${u}"
		usermod -G "${supplemental_groups[*]// /,}" "${u}"
	done
fi
#
# Secures root user
# (L)ocks user (root) & (d)eletes their password
[[ -n "${selected_associative[shortforms[lock_root]]}" ]] &&
	passwd root -ld





#
# PAM & Authentication Configuration
#
# Configure PAM with secure defaults (in the bg)
if
	[[ -n "${selected_associative[shortforms[pam]]}" ]]
then
	# RHEL-like distros
	if
		hash authselect
	then
		(
			set -e
			#
			# Configure PAM /w secure defaults enabled & further configure password QA
			authselect select sssd with-faillock with-pamaccess with-pwhistory with-pwquality with-mkhomedir with-sudo without-nullok --force
			install -m 640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
			#
			# Regenerate PAM configurations /w previous configuration
			authselect apply-changes
		) &
	# Debian-like distros
	elif
		hash pam-auth-update
	then
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
	# Enforce password age policies (to users w/ UID 1000=<)
	mapfile -t nonsys_users < <(awk -F: '$2 !~ /^(!|\*|$)/ { print $1 }' /etc/shadow)
	for u in "${nonsys_users[@]}"
	do
		# Skips the iterated user if they're the user running the script
		# Apply the password age restrictions to the user
		# Sets the date they last changed their password to current date to avoid accidental lockouts
		[[ "${u}" != "${SUDO_USER}" ]] &&
			chage -m 7 -M 90 -W 14 "${u}" &&
			chage -d "$(date +%Y-%m-%d)" "${u}"
	done
	#
	# Apply global defaults via login.defs
	for entry in "${login_def_configs[@]}"
	do
		safe_add "${entry}" /etc/login.defs
	done
	#
	# Check for duplicate users on the system & prompt for rectification
	# Migrate stray hashes from passwd to shadow & from group to gshadow
	[[ -n "${selected_associative[shortforms[info_err]]}" ]] &&
		pwck
	if
		[[ -n "${selected_associative[shortforms[mv_hash]]}" ]]
	then
		pwconv
		grpconv
	fi
	#
	# Disable guest & automatic login in LightDM
	if
		[[ -f /etc/lightdm/lightdm.conf ]]
	then
		safe_add 'allow-guest false' /etc/lightdm/lightdm.conf
		safe_add 'AutomaticLogin false' /etc/lightdm/lightdm.conf
	fi
fi





#
# Firewall Rules
#
if
	[[ -n "${selected_associative[shortforms[firewall]]}" ]]
then
	# Ensures necessary kernel modules are loaded
	for module in "${firewall_kernel_modules[@]}"
	do
		lsmod |
			grep -q "^${module}" ||
			modprobe "${module}"
	done
	#
	# Configure baseline ruleset (in the bg)
	# Uncomplicated Firewall/ufw
	# (Unfortunately UFW isn't flexible enough to block certain ICMP ping types)
	if
		[[ "${firewall}" == UFW ]]
	then
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
	elif
		[[ "${firewall}" == FirewallD ]]
	then
		(
			set -e
			#
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
	while
		[[
			-n "$(
				for port in "${ports[@]}"
				do
					[[ ! "${port}" =~ ^[0-9]{1,5}(-[0-9]{1,5})?$ ]] &&
						echo placeholder
				done
			)" ||
			-z "${ports[*]}"
		]]
	do
		read -erp 'Enter any remaining port numbers to allow in: ' -a ports
	done
	for port in "${ports[@]}"
	do
		# Whitelist ports
		if
			[[ "${firewall}" == UFW ]]
		then
			ufw allow in "${port}/tcp"
		elif
			[[ "${firewall}" == FirewallD ]]
		then
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
# Resource Management
#
# Prompt for external information
if
	[[ -n "${selected_associative[shortforms[resources]]}" ]]
then
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
[[ -n "${selected_associative[shortforms[motd]]}" ]] &&
	for banner_file in "${banner_files[@]}"
	do
		install -m 640 -o root -g root -D general-confs/motd "${banner_file}"
	done





#
# Exit
#
# Wait for all children to exit
echo 'i: Patches in progress; this may take a while depending on your selections...'
wait
#
# Exit & print success banner
# & the logs from this session.
success