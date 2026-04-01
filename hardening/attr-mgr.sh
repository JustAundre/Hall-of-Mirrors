#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
#
# Environment Setup & Logging
#
# Source secure environment
. .allrc





#
# Immutable and Append-only removal/restoration
#
options=(
	remove
	restore
)
response=$(checklist 'Action Required' radiolist "${options[@]}")
if [[ "$response" == 'remove' ]]; then
	echo 'ℹ️: This will take a second...'
	#
	# Finds and removes immutable (i) attributes
	find / -xdev -type f -exec lsattr -d {} + |
		awk '$1 ~ /i/ { print $2 }' |
		xargs -r chattr -i \
		>>"$log_dir/immutable-files.txt"
	#
	# Finds and removes append-only (a) attributes
	find / -xdev -type f -exec lsattr -d {} + |
		awk '$1 ~ /a/ { print $2 }' |
		xargs -r chattr -a \
		>>"$log_dir/append-only-files.txt"
else
	cat "$log_dir/immutable-files.txt" |
		while IFS= read -r file_path; do
			[[ -f "$file_path" ]] &&
				chattr +i "$file_path"
	done
	cat "$log_dir/append-only-files.txt" |
		while IFS= read -r file_path; do
			[[ -f "$file_path" ]] &&
				chattr +a "$file_path"
	done
fi