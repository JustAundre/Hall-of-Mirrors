#!/usr/bin/env bash
#
# Environment Setup
#
# Secure PATH variable
declare -rx PATH='/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin'
#
# Define location of logs
declare -r log_dir='/var/log/sessions'
#
# Find log files currently being logged to
declare -r is_open="$(
	lsof -c script -a +D "${log_dir}" -Fn 2>/dev/null |
		grep '^n' |
		cut -c2-
)"





#
# Main Logic
#
# Iterate a check over every file in the logging directory
for file in "${log_dir}"/*; do
	# Skip if it's not a regular file & remove symlinks
	[[ -f "${file}" ]] ||
		continue
	[[ -h "${file}" ]] &&
		rm -f "${file}"
	#
	# Apply defaults
	chown root:root "${file}" &&
		chmod 600 "${file}"
	#
	# Check if this specific file is in our list (or is being prepared for logging)
	if printf '%s' "${is_open}" |
		grep -qx "${file}" ||
		[[ "$(stat -c %s "${file}")" == 0 ]];
	then
		# File is actively being logged to
		# Add append-only (+a)
		chattr +a "${file}" &&
			echo "Made append-only: ${file}"
	else
		# File is idle/finished
		# Remove append-only (-a) & set immutable (+i)
		chattr -a +i "${file}" &&
			echo "Made immutable: ${file}"
	fi
done