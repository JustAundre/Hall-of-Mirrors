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
	[[ "$(stat -c '%U' "${file}")" == 'UNKNOWN' ]] && echo "i: (${file}) has an invalid owning user of UID $(stat -c '%u' "${file}")."
	[[ "$(stat -c '%G' "${file}")" == 'UNKNOWN' ]] && echo "i: (${file}) has an invalid owning group of GID $(stat -c '%g' "${file}")."
	#
	# Change ownership to root:root
	echo "i: Changing (${file})'s ownership to root:root..."
	chown -h root:root "${file}"
done





#
# Invalid Symlinks
#
# Map out invalid symlinks
mapfile -t broken_symlinks < <(find / -xdev -xtype l)
for symlink in "${broken_symlinks[@]}"; do
	# For every broken symlink, alert the user about it...
	# ...and remove it.
	echo "i: ${symlink} is a broken symlink; removing symlink..."
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
			echo "W: (${dir}) was (${perm}) which is deviated from the expected (1777)."
			chmod 1777 "${dir}"
		fi
	done
)





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
	# Find paths in /etc/ with ownership that is not root:root
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
					getent passwd "${user}" &>/dev/null ||
						getent passwd "${group}" &>/dev/null ||
						break
					chown -h "${user}:${group}" "${file}"
				#
				# Prompt for new permissions
				elif [[ "${choice}" == 'Change permissions' ]]; then
					read -rp 'Enter the octal permission: ' perm
					chmod "${perm}" "${file}"
				#
				# Delete the path
				elif [[ "${choice}" == 'Delete the path.' ]]; then rm -rmv "${file}"
				else echo "Unknown selection (${choice}), this error shouldn't be possible." >&2
				fi
			done
		fi
	done
)





#
# Identity & Authorization Files
#
# Handle /etc/passwd & /etc/group
chown -h root:root /etc/passwd /etc/group
chmod 644 /etc/passwd /etc/group
#
# Handle /etc/shadow & /etc/gshadow
if
	grep -q '^shadow:' /etc/group
then
	chown -h root:shadow /etc/shadow /etc/gshadow
	chmod 640 /etc/shadow /etc/gshadow
else
	chown -h root:root /etc/shadow /etc/gshadow
	chmod 600 /etc/shadow /etc/gshadow
fi
#
# Sudoers
[[ "$(stat -c '%u:%U ' /etc/sudoers)" ]] &&
	install -o root -g root -m 440 /etc/sudoers
chmod -R  /etc/sudoers.d/*
#
# Ensure only root can read the bootloader config
find /boot -type f -exec chown -h root:root {} + -exec chmod 640 {} +
find /boot -type d -exec chown -h root:root {} + -exec chmod 750 {} +
#
# Ensure SystemD unit files are secure
find /etc/systemd/system -type f -exec chown -h root:root {} + -exec chmod 640 {} +
find /etc/systemd/system -type d -exec chown -h root:root {} + -exec chmod 750 {} +
#
# Secure cron tabs & directories
chown -h root:root /etc/cron.* /etc/at.allow /etc/crontab
chmod -R 750 /etc/cron.* /etc/at.allow /etc/crontab
#
# Secure sudoers configuration
chown -R root:root /etc/sudoers /etc/sudoers.d
chmod -R 750 /etc/sudoers.d /etc/sudoers
#
# Restrict dmesg access
chown -R root:root /bin/dmesg /usr/bin/dmesg
chmod -R 700 /bin/dmesg /usr/bin/dmesg
#
# Secure SSH configurations
find /etc/ssh -type f -exec chown -h root:root {} + -exec chmod 600 {} +
find /etc/ssh -type d -exec chown -h root:root {} + -exec chmod 700 {} +
chmod -R 644 /etc/ssh/*.pub
#
# Secure MOTD/banners are secured
chown -R root:root /etc/issue /etc/issue.net /etc/motd
chmod -R 644 /etc/issue /etc/issue.net /etc/motd
#
# Ensure log files are secured
chown -h root:root /var/log
find /var/log/ -mindepth 1 -type f -exec chmod 640 {} +
find /var/log/ -type d -exec chmod 750 {} +
#
# Secure rsyslog configurations
install -o root -g root -m 640 /etc/rsyslog.conf /etc/rsyslog.conf
find /etc/rsyslog.d/ -mindepth 1 -type f -exec chown -h root:root {} + -exec chmod 640 {} +
find /etc/rsyslog.d/ -type f -exec chown -h root:root {} + -exec chmod 750 {} +
#
# Secure Auditd logs & configs
find /etc/audit -mindepth 1 -type f -exec chown -h root:root {} + -exec chmod 640 {} +
find /etc/audit -type d -exec chown -h root:root {} + -exec chmod 750 {} +
#
# Secure global shell profiles
chown -Rh root:root /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
chmod -R 644 /etc/profile /etc/bashrc /etc/bash.bashrc /etc/profile.d/*
#
# Secure existing home directories
chown -Rh root:root /root
chmod -R 700 /home/* /root
#
# Find world-writable paths
mapfile -t world_writables < <(find / -xdev -perm -0002)