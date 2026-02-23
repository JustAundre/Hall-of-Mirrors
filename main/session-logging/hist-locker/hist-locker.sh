#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
# Find history files and lock 'em down!
inotifywait -qmre attrib -e create /home/* | while read -r directory event file; do
	filePath="${directory}${file}"
	[[ "$file" =~ _history ]] || continue
	if [[ -h "$filePath" || -d "$filePath"]]; then
		echo "Woah there, kiddo! That's ($filePath) a symlink (to $(readlink -f $filePath))--I ain't touching that." >&2
	fi
	chown root "$filePath"
	chmod 020 "$filePath"
	chattr +a "$filePath"
done