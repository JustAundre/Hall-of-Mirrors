#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
#
# Environment Setup
#
declare -rx PATH
declare -rx INTERPRET_NONINTERACTIVE
#
# Track events by Audit ID to prevent interleaving issues
declare -A event_cache
#
# Function to decode hex strings
dehex() {
	local val="$1"
	#
	# i: AuditD hex-encoded strings never start with a quote!
	# If strings starts with quotes
	if [[ "$val" != \"* ]]; then
		# Decode
		echo "$val" | xxd -rp 2>/dev/null
	else
		# Strip the quotes
		echo "${val//\"/}"
	fi
}





#
# Main Logic
#
# Start piping the log into the parser
tail -F /var/log/audit/audit.log 2>/dev/null | grep --line-buffered -E "^type=(EXECVE|SYSCALL)" | while read -r line; do
	# Clear variables to prevent variable bleeds
	unset AUID auid _EUID euid pid ppid relation tty success i dirtyCmd cleanCmd val ID id lp lpp
	#
	# Extract the Audit ID to pair related records
	[[ "$line" =~ audit\(([0-9]+\.[0-9]+:[0-9]+)\) ]] && id="${BASH_REMATCH[1]}"
	[[ -z "$id" ]] && continue
	#
	# If it's a failure, throw it away and reset
	[[ "$line" == *' exit=-'* ]] && {
		unset "event_cache[$id]"
		continue
	}
	#
	# Handle SYSCALL records (the first half)
	if [[ "$line" == "type=SYSCALL"* ]]; then
		# Check if the process or parent process is this script
		[[ "$line" =~ pid=([0-9]+) ]] && lp="${BASH_REMATCH[1]}"
		[[ "$line" =~ ppid=([0-9]+) ]] && lpp="${BASH_REMATCH[1]}"
		#
		# If we triggered the audit, ignore it to prevent the infinite loop
		[[ "$lp" == "$$$" || "$lpp" == "$$$" ]] && continue
		#
		# Store in cache and wait for EXECVE
		event_cache["$id"]="$line"
	elif [[ "$line" == "type=EXECVE"* ]]; then
		# Handle EXECVE records (the second half)
		# Retrieve the matching SYSCALL record from cache
		syscall_line="${event_cache["$id"]}"
		[[ -z "$syscall_line" ]] && continue
		#
		# Merge the two halves
		merged="${syscall_line} ${line}"
		#
		# Clear the cache entry to keep memory usage low
		unset "event_cache[$id]"
		#
		# Hope you can read RegEx!
		# Grab command information and executor identifiers
		[[ "$merged" =~ AUID=\"([^\"]+) ]] && AUID="${BASH_REMATCH[1]}"
		[[ "$merged" =~ auid=([^ ]+) ]] && auid="${BASH_REMATCH[1]}"
		[[ "$auid" == '4294967295' || "$auid" == 'unset' ]] && continue
		[[ "$merged" =~ EUID=\"([^\"]+) ]] && _EUID="${BASH_REMATCH[1]}"
		[[ "$merged" =~ euid=([^ ]+) ]] && euid="${BASH_REMATCH[1]}"
		[[ "$merged" =~ pid=([^ ]+) ]] && pid="${BASH_REMATCH[1]}"
		[[ "$pid" == "$$" ]] && continue
		[[ "$merged" =~ ppid=([^ ]+) ]] && ppid="${BASH_REMATCH[1]}"
		[[ "$pid" == "$ppid" ]] && relation="by process $pid" || relation="by child $pid of parent $ppid"
		[[ "$merged" =~ tty=([^ ]+) ]] && tty="${BASH_REMATCH[1]}"
		if [[ "$tty" == '(none)' ]]; then
			[[ -n "$INTERPRET_NONINTERACTIVE" ]] || continue
			tty='non-interactively'
		fi
		tty="on $tty"
		[[ "$merged" =~ success=([^ ]+) ]] && success="${BASH_REMATCH[1]}"
		[[ "$success" == 'yes' ]] && i='successfully' || i='unsuccessfully'
		[[ "$merged" =~ argc=[0-9]+[[:space:]](.*) ]] && dirtyCmd="${BASH_REMATCH[1]}"
		cleanCmd=()
		while [[ "$dirtyCmd" =~ a[0-9]+=([^[:space:]]+) ]]; do
			val="${BASH_REMATCH[1]}"
			cleanCmd+=("$(dehex $val)")
			#
			# Remove matched part to find the next arg
			dirtyCmd="${dirtyCmd#*${BASH_REMATCH[0]}}"
		done
		[[ "$AUID/$auid" == "$_EUID/$euid" ]] && ID="$AUID/$auid" || ID="$AUID/$auid with $_EUID/$euid"
		#
		# Echo the log
		echo "$ID $relation ran $i $tty: ${cleanCmd[*]}"
	fi
done