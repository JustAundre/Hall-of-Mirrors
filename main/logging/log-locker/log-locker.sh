#!/usr/bin/env -iS /usr/bin/bash --norc --noprofile
#
# Environment Setup
#
# Secure PATH variable
declare -rx PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
#
# Define location of logs
declare -r logDir='/var/log/sessions'
#
# Find log files currently being logged to
declare -r isOpen=$(lsof -c script -a +D "$logDir" -Fn 2>/dev/null | grep '^n' | cut -c2-)





#
# Main Logic
#
# Iterate a check over every file in the logging directory
for file in "$logDir"/*; do
	# Skip if it's not a regular file & remove symlinks
	[[ -f "$file" ]] || continue
	[[ -h "$file" ]] && rm -f "$file"
	#
	# Apply defaults
	chown root:root "$file"
	chmod 600 "$file"
	#
	# Check if this specific file is in our list (or is being prepared for logging)
	if echo "$isOpen" | grep -qx "$file" || [[ "$(stat -c %s $file)" == '0' ]]; then
		# File is actively being logged to
		# Add append-only (+a)
		chattr +a "$file" && echo "Made append-only: $file"
	else
		# File is idle/finished
		# Remove append-only (-a) and set immutable (+i)
		chattr -a +i "$file" && echo "Made immutable: $file"
	fi
done