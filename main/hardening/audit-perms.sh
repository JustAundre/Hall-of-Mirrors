#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Invalid Ownership
#
# Map out files /w broken ownership.
mapfile -t broken_ownership < <(find / -xdev \( -nouser -o -nogroup \))
for file in "${broken_ownership[@]}"; do
	# Verbosity: note invalidities, their type, and the UID/GID.
	[[ "$(stat -c '%U' "${file}")" == UNKNOWN ]] && echo "i: \"${file}\" has an invalid owning user of UID $(stat -c '%u' "${file}")."
	[[ "$(stat -c '%G' "${file}")" == UNKNOWN ]] && echo "i: \"${file}\" has an invalid owning group of GID $(stat -c '%g' "${file}")."
	#
	# Change ownership to 0:0
	echo "i: Changing \"${file}\"'s ownership to 0:0..."
	chown -h 0:0 "${file}"
done





#
# Invalid Symlinks
#
# Map out invalid symlinks
mapfile -t broken_symlinks < <(find / -xdev -xtype l)
for symlink in "${broken_symlinks[@]}"; do
	# For every broken symlink, alert the user about it...
	# ...and remove it.
	echo "i: \"${symlink}\" is a broken symlink; removing symlink..."
	unlink "${symlink}"
done





#
# Sticky Temps
#
# Subshell can handle the variable cleanup for me
(
	# Define list of temporary data directories
	tmp_dirs=(
		/tmp
		/var/tmp
		/dev/shm
	)
	#
	# Check if the above directories have the sticky bit
	for dir in "${tmp_dirs[@]}"; do
		perm="$(stat -c '%a' "${dir}")"
		#
		# If they don't, log it and fix it.
		if [[ "${perm}" != 1777 ]]; then
			echo "W: \"${dir}\"'s permissions were ${perm} which is deviated from the expected (1777)."
			chmod 1777 "${dir}"
		fi
	done
)





#
# World-Writable Paths
#
# A stub. Needs to be finished.
# Find world-writable paths
mapfile -t world_writables < <(find / -xdev -perm -0002)





#
# /etc/ Ownerships
#
# Subshell can handle variable cleanup for me
(
# Choices for remediation when encountering a path owned by a non-system user in /etc/
# Developer's Note: There's 3 empty choices to act as a buffer for fat-fingering "Delete the path".
fixes=(
	'Change ownership'
	'Change permissions'
	''
	''
	''
	'Delete the path.'
)
# Find paths in /etc/ with ownership that is not 0:0
mapfile -t not_root_owned < <(find /etc \( ! -group root -o ! -user root \))
for file in "${not_root_owned[@]}"; do
	# If the owners are system users/groups, it's probably fine.
	if [[
		"$(stat -c %g -- "${file}")" -ge 1000 ||
		"$(stat -c %u -- "${file}")" -ge 1000
	]]; then
		# Prompt for action
		mapfile -t choices < <(checklist "${file} is owned by $(stat -c '%U:%G/%u:%g' "${file}") with permissions $(stat -c '%A/%a' "${file}"). What do you want to do?" checklist "${fixes[@]}")
		#
		# Act on selections
		for choice in "${choices[@]}"; do
			# Prompt for new ownership
			# Validate given user and group
			# Change the ownership
			if [[ "${choice}" == 'Change ownership' ]]; then
				read -rp 'Enter the new user owner: ' user
				read -rp 'Enter the new group owner: ' group
				getent passwd "${user}" &>/dev/null || getent group "${group}" &>/dev/null || break
				chown -h "${user}:${group}" "${file}"
			#
			# Prompt for new permissions
			elif [[ "${choice}" == 'Change permissions' ]]; then
				read -rp 'Enter the octal permission: ' perm
				chmod "${perm}" "${file}"
			#
			# Delete the path
			elif [[ "${choice}" == 'Delete the path.' ]]; then rm -rmv "${file}"
			else echo "Unknown selection \"${choice}\", this error shouldn't be possible." >&2
			fi
		done
	fi
done
)





#
# Identity & Authorization Files
#
# Handle /etc/passwd & /etc/group
chown -h 0:0 /etc/passwd /etc/group
chmod 644 /etc/passwd /etc/group
#
# Shadow file permissions vary by distribution
if [[ "${os_info[ID]}" == almalinux ]]; then
	for file in /etc/shadow /etc/gshadow /etc/shadow- /etc/gshadow-; do
		current="$(stat -c '%a %u:%g' "${file}")"
		expected='000 0:0'
		if
			[[ "${current}" != "${expected}" ]] &&
			confirm "W: ${file} is ${current} instead of the expected ${expected}. Rectify"
		then
			chown -h 0:0 "${file}"
			chmod 0000 "${file}"
		fi
	done
else
	for file in /etc/shadow /etc/gshadow; do
		current="$(stat -c '%a %u:%g' "${file}")"
		expected='640 0:42'
		if
			[[ "${current}" != "${expected}" ]] &&
			confirm "W: ${file} is ${current} instead of the expected ${expected}. Rectify"
		then
			chown -h 0:42 "${file}"
			chmod 0640 "${file}"
		fi
	done
	for file in /etc/shadow- /etc/gshadow-; do
		current="$(stat -c '%a %u:%g' "${file}")"
		expected='600 0:0'
		if
			[[ "${current}" != "${expected}" ]] &&
			confirm "W: ${file} is ${current} instead of the expected ${expected}. Rectify"
		then
			chown -h 0:0 "${file}"
			chmod 0600 "${file}"
		fi
	done
fi
#
# Fix Sudoers configuration
find /etc/sudoers.d /etc/sudoers -type f -exec chown -h 0:0 {} + -exec chmod 600 {} +
find /etc/sudoers.d /etc/sudoers -type d -exec chown -h 0:0 {} + -exec chmod 700 {} +





#
# Misc. System Files
#
# Can be improved
# Ensure only root can read the bootloader config
find /boot -type f -exec chown -h 0:0 {} + -exec chmod 640 {} +
find /boot -type d -exec chown -h 0:0 {} + -exec chmod 750 {} +
#
# Ensure SystemD unit files are secure
find /etc/systemd/system -type f -exec chown -h 0:0 {} + -exec chmod 640 {} +
find /etc/systemd/system -type d -exec chown -h 0:0 {} + -exec chmod 750 {} +
#
# Secure cronjobs
find /etc/cron.* /etc/crontab /etc/at.allow -type f -exec chown -h 0:0 {} + -exec chmod 640 {} +
find /etc/cron.* /etc/crontab /etc/at.allow -type d -exec chown -h 0:0 {} + -exec chmod 750 {} +
#
# Restrict privileged binaries
chown -h 0:0 /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules /bin/dmesg /usr/bin/dmesg
chmod 750 /sbin/auditctl /sbin/aureport /sbin/ausearch /sbin/autrace /sbin/auditd /sbin/augenrules /bin/dmesg /usr/bin/dmesg
#
# Secure SSH configurations/private keys, and public keys.
find /etc/ssh -type f -exec chown -h 0:0 {} + -exec chmod 600 {} +
find /etc/ssh -type d -exec chown -h 0:0 {} + -exec chmod 700 {} +
find /etc/ssh -type f -exec chown -h 0:0 {} + -exec chmod 600 {} +
find /etc/ssh -name '*.pub' -type f -exec chown -h 0:0 {} + -exec chmod 644 {} +
#
# Secure MOTD/banners are secured
chown 0:0 /etc/issue /etc/issue.net /etc/motd
chmod 644 /etc/issue /etc/issue.net /etc/motd
#
# Ensure log files are secured
chown -h 0:0 /var/log
find /var/log/ -mindepth 1 -type f -exec chmod 640 {} +
find /var/log/ -type d -exec chmod 750 {} +
#
# Some distros use the adm user for these logs
auditd_log_dir="$(dirname "$(awk -F'=' '/^\s*log_file/ {print $2}' /etc/audit/auditd.conf | xargs)")"
if [[ "${os_info[ID]}" =~ ^(ubuntu|almalinux)$ && -d "${auditd_log_dir}" ]]
then find "${auditd_log_dir}" -type f -exec chown -h root:adm {} + -exec chmod 0640 {} +
else find "${auditd_log_dir}" -type f -exec chown -h 0:0 {} + -exec chmod 0600 {} +
fi
chmod 0750 "${auditd_log_dir}"
#
# Secure AuditD/rsyslog configurations
find /etc/audit /etc/rsyslog.d/ /etc/rsyslog.conf -mindepth 1 -type f -exec chown -h 0:0 {} + -exec chmod 640 {} +
find /etc/audit /etc/rsyslog.d/ -type d -exec chown -h 0:0 {} + -exec chmod 750 {} +
#
# Secure global shell profiles
find /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/ -type f -exec chown -h 0:0 {} + -exec chmod 644 {} +
find /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/ -type d -exec chmod 0:0 {} + -exec chmod 755 {} +
#
# Secure local home directories
# (including root's home @ /root)
# (Subshell for variable cleanup)
(
# Iterate over all interactive users'...
for user in "${int_users[@]}"; do
	# Home directories.
	home="$(grep "^${user}:" | tail -n1 | cut -d: -f6)"
	#
	# Check permissions on them
	current="$(stat -c '%a %U:%G' "${home}")"
	expected="700 ${user}:${user}"
	if
		[[ "${current}" != "${expected}" ]] &&
		confirm "W: ${user}'s home @ \"${home}\" is \"${current}\" instead of the expected \"${expected}\". Rectify"
	then
		find "${home}" -type f -exec chown "${user}:${user}" {} + -exec chmod 600 {} +
		find "${home}" -type d -exec chown "${user}:${user}" {} + -exec chmod 700 {} +
	fi
done
)
find /root -type f -exec chown 0:0 {} + -exec chmod 600 {} +
find /root -type d -exec chown 0:0 {} + -exec chmod 700 {} +
#
# Debian-based distros exclusive: APT keyrings
if [[ "${os_info[ID]}" == debian || "${os_info[ID]}" == ubuntu ]]; then
	[[ -d /etc/apt/trusted.gpg.d ]] && find /etc/apt/trusted.gpg.d -type f -exec chown -h 0:0 {} + -exec chmod 644 {} +
	[[ -d /usr/share/keyrings ]] && find /usr/share/keyrings -type f -exec chown -h 0:0 {} + -exec chmod 644 {} +
fi