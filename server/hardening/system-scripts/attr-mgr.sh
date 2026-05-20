#!/usr/bin/env bash
### A compact script to remove immutable and append-only bits and save them to a file to restore at a later time.
#
# Attribute Manager
#
# Choices for attribute manager.
options=(
	remove
	restore
)
#
# Act based on selected mode
if [[ "$(checklist 'Attribute manager' radiolist "${options[@]}")" == remove ]]; then
	# Alert the user of the possible lengthy scan
	echo $'i: This will take a second; if you ask, no the script didn\'t hang.'
	#
	# Removes the (i)mmutable & (a)ppend-only attributes from all files
	find / -xdev -type f -exec lsattr -d {} + 2>/dev/null | while read -r attrs file; do
		if [[ "${attrs}" == *i* ]]; then
			echo "${file}" >>immutable-files.txt
			echo "i: Found immutable file: ${file}"
		fi
		if [[ "${attrs}" == *a* ]]; then
			echo "${file}" >>append-only-files.txt
			echo "i: Found append-only file: ${file}"
		fi
	done
	[[ -s immutable-files.txt ]] && xargs chattr -- -i <immutable-files.txt
	[[ -s append-only-files.txt ]] && xargs chattr -- -a <append-only-files.txt
else
	while IFS= read -r path; do
		[[ -f "${path}" ]] && chattr +a "${path}" && echo ''
	done <append-only-files.txt
	while IFS= read -r path; do
		[[ -f "${path}" ]] && chattr +i "${path}"
	done <immutable-files.txt
fi
