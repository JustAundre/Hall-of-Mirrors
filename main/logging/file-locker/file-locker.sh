#!/usr/bin/env bash
#
# Environment Setup
#
# Helper function to modify file metadata
# path, owner, octal perm, attribute
metamod() {
	# Change its permissions & attributes based on the given options
	# If given owner exists...
	if
		getent passwd "$2" &>/dev/null
	then
		# Owner exists, so execute the chown.
		chown -- "$2" "$1"
	fi
	#
	# If octal permission format is detected...
	if
		[[ "$3" =~ ^[0-9]{3,4}$ ]]
	then
		# Command is valid, so execute.
		chmod -- "$3" "$1"
	fi
	#
	# If any combination of lowercase i/a (immutable/append-only)...
	if
		[[ "$4" =~ ^[ia]{1,2}$ ]]
	then
		# Command is valid, so execute.
		chattr +"$4" -- "$1"
	fi
}
#
# Helper function to check paths
# path, pattern
pathchk() {
	# Match path with pattern given
	if
		[[ ! "$(basename -- "$1")" =~ $2 ]]
	then
		# If no match, fail.
		echo "The basename of $1 ($(basename -- "$1")) didn't match pattern ($2); ignoring..." >&2
		return 1
	# Check if path is a directory
	elif
		[[ -d "$1" ]]
	then
		# If is a directory, fail.
		echo "$1 is a directory; ignoring..." >&2
		return 2
	# Check if path is symlink
	elif
		[[ -h "$1" ]]
	then
		# If is symlink, fail.
		echo "$1 is a symlink to $(readlink -f -- "$1"); ignoring..." >&2
		return 3
	# Check if path is a file
	elif
		[[ ! -f "$1" ]]
	then
		# If is not a file, it doesn't exist.
		echo "$1 doesn't exist anymore; ignoring..."
		return 4
	else
		return 0
	fi
}
#
# Helper function to check a directory
dirchk() {
	find "$1" -type f -print0 -maxdepth 2 |
		while
			IFS= read -r -d '' path;
		do
			pathchk "${path}" "$2" &&
				metamod "${path}" "$3" "$4" "$5"
		done
}
#
# Helper function to monitor files
filemon() {
	# Initial check
	echo "Performing initial scan on $1 for files matching $2 -- on detection will set owner $3, mode $4 & attributes $5."
	dirchk "$1" "$2" "$3" "$4" "$5"
	#
	# Setup the inotify watchers
	echo "Attempting to setup inotifywait watch for $1 for files matching $2 -- on detection will set owner $3, mode $4 & attributes $5."
	inotifywait -qmre attrib,create,moved_to,close_write "$1" |
		while
			read -r i
		do
			dirchk "$1" "$2" "$3" "$4" "$5"
		done
}






#
# Monitoring
#
# Monitor & revert changes to identity management
filemon '/etc' '^passwd$' root 644 ia &
filemon '/etc' '^g?shadow$' root none ia &
#
# Lockdown all history files
filemon '/home' 'history' root 620 a &
filemon '/root' 'history' root 620 a &
#
# Lockdown bash rc/logout/profile files
filemon '/home' '^\..*(rc|logout|profile)$' root 640 ia &
filemon '/root' '^\..*(rc|logout|profile)$' root 640 ia &
#
# Keep the script active until all children processes exit
wait