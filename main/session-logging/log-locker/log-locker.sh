#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
# Define location of logs and the files being actively logged to
declare -r logDir="/var/log/sessions"
declare -r isOpen=$(lsof -c script -a +D "$logDir" -Fn 2>/dev/null | grep '^n' | cut -c2-)
#
# Iterate a check over every file in the logging directory
for file in "$logDir"/*; do
	# Skip if it's not a regular file & remove symlinks
	[[ -f "$file" ]] || continue
	[[ -h "$file" ]] && rm -f "$file"
	#
	# Apply defaults
	chown root:root "$file"
	chmod 000 "$file"
	#
	# Check if this specific file is in our list (or is being prepared for logging)
	if echo "$isOpen" | grep -qx "$file" || [[ "$(stat -c %s $file)" == '0' ]]; then
		# File is actively being logged to
		chattr +a "$file" && echo "Restricted active log: $file"
	else
		# File is idle/finished
		# Remove append-only (-a) and set immutable (+i)
		chattr -a +i "$file" && echo "Froze inactive log: $file"
	fi
done