#!/usr/bin/env bash
#
# Environment Setup & Logging
#
# Source secure environment
cd "$(dirname "${BASH_ARGV0[*]}")"
. .allrc





#
# Attribute Manager
#
# Set the choices
options=(
	remove
	restore
)
response="$(checklist 'Attribute manager' radiolist "${options[@]}")"
if [[ "$response" == remove ]]; then
	# Alert the user of the possible lengthy scan
	echo i: This will take a second...
	#
	# Removes the (i)mmutable & (a)ppend-only attributes from all files
	find / -xdev -type f -exec lsattr -d {} + |
		tee >(
			awk '$1 ~ /i/ { print $2 }' |
				tee "immutable-files.txt" |
				xargs chattr -i
		) >(
			awk '$1 ~ /a/ { print $2 }' |
				tee "append-only-files.txt" |
				xargs chattr -a
		) >/dev/null
elif [[ "$response" == restore ]]; then
	cat append-only-files.txt |
		while IFS= read -r path; do
			[[ -f "$path" ]] &&
				chattr +a "$path"
		done
	cat immutable-files.txt |
		while IFS= read -r path; do
			[[ -f "$file_path" ]] &&
				chattr +i "$file_path"
		done
fi
