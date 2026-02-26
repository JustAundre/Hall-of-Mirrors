#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
#
# Environment Setup
#
# Service configuration
declare -rx INTERPRET_NONINTERACTIVE OUT_WHERE OUT_TYPE=json
#
# Track events by Audit id to prevent interleaving issues
declare -A event_cache
#
# Function to decode hex strings
dehex() {
	local hex="$1"
	if [[ ! "$hex" =~ ^[0-9A-Fa-f]+$ ]]; then
		echo "${hex//\"/}"
		return
	fi
	local decoded=""
	for (( i=0; i<${#hex}; i+=2 )); do
		local char="0x${hex:i:2}"
		if (( char >= 32 && char <= 126 )); then
			printf -v val "\\x${hex:i:2}"
			decoded+="$val"
		fi
	done
	echo "$decoded"
}





#
# Main Logic
#
# Start piping the log into the parser
# | sudo ausearch -if /dev/stdin --line-buffered -i
tail -F /var/log/audit/audit.log | while read -r line; do
	#
	# Extract the Audit id to pair related records
	[[ "$line" =~ audit\(([0-9]+\.[0-9]+:[0-9]+)\) ]] && id="${BASH_REMATCH[1]}"
	[[ -z "$id" ]] && continue
	#
	# Anti-log bomb
	if [[ "$line" =~ pid=([0-9]+) || "$line" =~ ppid=([0-9]+) ]]; then
		if [[ "${BASH_REMATCH[1]}" == "$$" || "${BASH_REMATCH[1]}" == "$BASHPID" ]]; then
			continue
		fi
	fi
	#
	# Flush Logic
	if [[ -n "${!event_cache[@]}" && -z "${event_cache[$id]}" ]]; then
		for old_id in "${!event_cache[@]}"; do
			merged="${event_cache[$old_id]}"
			#
			# Pull variables
			unset actual_user actual_uid effective_user effective_uid pid ppid relation relation disp_id tty success tag status cleanCmd
			[[ "$merged" =~ AUID=\"([^\"]+) ]] && actual_user="${BASH_REMATCH[1]}"
			[[ "$merged" =~ auid=([^ ]+) ]] && actual_uid="${BASH_REMATCH[1]}"
			[[ "$merged" =~ EUID=\"([^\"]+) ]] && effective_user="${BASH_REMATCH[1]}"
			[[ "$merged" =~ euid=([^ ]+) ]] && effective_uid="${BASH_REMATCH[1]}"
			[[ "$merged" =~ pid=([^ ]+) ]] && pid="${BASH_REMATCH[1]}"
			[[ "$merged" =~ ppid=([^ ]+) ]] && ppid="${BASH_REMATCH[1]}"
			[[ "$merged" =~ tty=([^ ]+) ]] && tty="${BASH_REMATCH[1]}"
			[[ "$merged" =~ success=([^ ]+) ]] && success="${BASH_REMATCH[1]}"
			[[ "$merged" =~ key=\"([^\"]+) ]] && tag="${BASH_REMATCH[1]}"
			[[ -z "$tag" ]] && tag='no_tag'
			#
			# Filter unsets
			if [[ "$actual_uid" == '4294967295' || "$actual_uid" == 'unset' || -z "$actual_uid" ]]; then
				unset "event_cache[$old_id]"
				continue
			fi
			#
			# Filter non-interactive commands
			if [[ -z "$INTERPRET_NONINTERACTIVE" && "$tty" == '(none)' ]]; then
				unset "event_cache[$old_id]"
				continue
			fi
			#
			# Extract EXECVE specific arguments
			cleanCmd=()
			if [[ "$merged" =~ type=EXECVE[[:space:]].*argc=[0-9]+[[:space:]](.*) ]]; then
				execve_args="${BASH_REMATCH[1]}"
				while [[ "$execve_args" =~ a([0-9]+)=([^[:space:]]+) ]]; do
					arg_val="${BASH_REMATCH[2]//\"/}"
					decoded_arg="$(dehex "$arg_val")"
					[[ -n "$decoded_arg" ]] && cleanCmd+=("$decoded_arg")
					execve_args="${execve_args#*${BASH_REMATCH[0]}}"
				done
			fi
			#
			# Output
			if [[ ${#cleanCmd[@]} -gt 0 && -n "$actual_user" ]]; then
				if [[ "$OUT_TYPE" == 'human' ]]; then
					[[ "$tty" == '(none)' || -z "$tty" ]] && tty='non-interactive'
					[[ "$success" == 'yes' ]] && status='successfully' || status='unsuccessfully'
					[[ "$actual_user/$actual_uid" == "$effective_user/$effective_uid" ]] && disp_id="$actual_user/$actual_uid" || disp_id="$actual_user/$actual_uid by $effective_user/$effective_uid"
					[[ "$pid" == "$ppid" ]] && relation="process $pid" || relation="child $pid of parent $ppid"
					echo "$tag: $disp_id $relation ran $status on $tty: ${cleanCmd[*]}"
				elif [[ "$OUT_TYPE" == 'json' ]]; then
					cat <<-EOF
						{"actual_user": "$actual_user", "actual_uid": $actual_uid, "effective_user": "$effective_user", "effective_uid": $effective_uid, "pid": $pid, "ppid": $ppid, "tty": "$tty", "success": "$success", "tag": "$tag", "command": "${cleanCmd[*]}"}
					EOF
				fi
			fi
			#
			# Clear memory
			unset "event_cache[$old_id]"
		done
	fi
	#
	# Append
	event_cache["$id"]+="$line "
done