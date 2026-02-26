#!/usr/bin/env -iS /usr/bin/bash --norc --noprofile
#
# Environment Setup
#
# Secure PATH variable
declare -rx PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
#
# Helper function
filemon() {
	[[ -f "$1" || -d "$1" ]] || return 255
	inotifywait -qmre attrib -e create "$1" | while read -r dir event file; do
		# Get full file path
		path="${dir}${file}"
		#
		# Check the "file" for certain risky attributes
		[[ "$file" =~ $2 ]] || continue
		if [[ -h "$path" ]]; then
			echo "Woah there, kiddo! That's ($path) a symlink (to $(readlink -f $path))--I ain't touching that." >&2
			continue
		elif [[ -d "$path" ]]; then
			echo "I ain't touchin' none of them 'directories' ($path), gimme a file!" >&2
			continue
		fi
		#
		# Change its permissions and attributes based on the given params
		getent passwd "$3" >/dev/null && chown "$3" "$path"
		[[ "$4" =~ ^[0-9]{3,4}$ ]] && chmod "$4" "$path"
		[[ "$5" =~ ^[ia]{1,2}$ ]] && chattr +"$5" "$path"
	done
}






#
# Monitoring
#
# Monitor history files and lock 'em down.
filemon /home/ history root 620 a &
filemon /root/ history root 620 a &
#
# Monitor and prevent changes to local users
filemon /etc/passwd '*' root 644 i &
filemon /etc/gshadow '*' root no a &
filemon /etc/shadow '*' root no i &
#
# Keep the script active until all children processes exit
wait