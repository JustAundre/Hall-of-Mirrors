#!/usr/bin/env bash
#
# Environment Setup
#
# Source configuration
. /opt/.bullshrc || exit 1





#
# The Shell
#
# Send identifiers to a log file
warn() {
	local input="$(printf "%q" "$*")"
	case "$1" in
		fail)
			shift 1
			local msg="W: ${USER}/${UID}@${SSH_CLIENT%% *} with EUID ${EUID} on ${TTY} failed ${layer_at} with input: ${input}"
			printf '%s' "${msg}" | tee -a "${config[log_file]}" | systemd-cat -t "${config[log_tag]}"
		;;
		pass)
			local msg="OK: ${USER}/${UID}@${SSH_CLIENT%% *} on ${TTY} passed onto ${layer_at}"
			printf '%s' "${msg}" | tee -a "${config[log_file]}" | systemd-cat -t "${config[log_tag]}"
		;;
		enter)
			local msg="OK: ${USER}/${UID}@${SSH_CLIENT%% *} on ${TTY} passed into a real terminal."
			printf '%s' "${msg}" | tee -a "${config[log_file]}" | systemd-cat -t "${config[log_tag]}"
		;;
		*)
			echo 'E: The warn function was called with a non-existent warning type.'
			return 1
		;;
	esac
}
#
# Function to send an annoyance to the terminal which got the password wrong
annoyance() {
	# Prevent intensive resource consumption
	[[ -z "${annoying}" ]] && annoying=placeholder || return 1
	#
	# Check annoyance type
	case "${config[annoyance_index]}" in
		1)
			# Flash black & white really fast for a few seconds
			for i in {1..250}; do
				printf '\e[?5h'
				sleep 0.01
				printf '\e[?5l'
				sleep 0.01
			done
		;;
		2)
			# Splat out 512 bytes from /dev/urandom onto the screen every 2 seconds for 14 seconds.
			for i in {1..7}; do
				sleep 2
				[[ "$(( RANDOM % 100 > 80 ))" -eq 1 ]] && head -c 512 /dev/urandom
			done
			printf '\n%s' "${PS1}"
		;;
		3)
			# Splat out a random character from /dev/urandom onto a random positon on the screen 500 times at high speeds
			# Hide the cursor
			tput civis
			#
			# Print 500 random characters @ random positions on the screen
			local rows="$(tput lines)" cols="$(tput cols)"
			for i in {1..500}; do
				# Find a random position within the current window size and...
				# ...print a random character at the aforementioned position (plus an extra bell as shown by \a)
				local y="$((RANDOM % rows + 1))" x="$((RANDOM % cols + 1))"
				printf "\a\e[%d;%dH%s" "${y}" "${x}" "$(head -c 1 /dev/urandom | tr -d '\0')"
			done
			#
			# Move cursor to the bottom & show your cursor again
			printf "\e[%d;1H${PS1}" "${rows}"
			tput cnorm
		;;
		4)
			# For ~1 minute, have a minor chance every...
			# 150 milliseconds to visually drop input
			for i in {1..400}; do
				[[ "$(( RANDOM % 100 > 80 ))" -eq 1 ]] && stty -echo
				sleep .15
				stty echo
			done
		;;
	esac
	#
	# Mark the end of the function
	unset annoying
	return
}
#
# Function to pass into the real shell
handover() {
	# Log the successful attempt & pass into a real shell.
	warn enter
	builtin exec /usr/bin/env -i SSH_CONNECTION="${SSH_CONNECTION}" SSH_CLIENT="${SSH_CLIENT}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/bash -il
}
#
# Function to hash input
hash() {
	# Variable scoping/isolation
	# Hash the input
	local input="${input}"
	local PS1="${PS1}"
	local layer_at="${layer_at}"
	local counts="${counts}"
	printf '%s' "${input}" | python3 -c "${python_hashing_logic}"
}
#
# Function to check input
passwd_check() {
	(( counts++ ))
	local counts="${counts}"
	local input="${input}"
	local target_hash="${hashes[$((layer_at - 1))]}"
	local cmd="${input%% *}"
	#
	# Update history (L1 exclusive)
	# Simulate a fake delay (if configured)
	# Silently lock out after max_tries
	# Generate hash only if not locked out
	[[ "${layer_at}" -eq 1 ]] && history -s "${input}"
	[[ "${config[fake_latency]}" == y ]] && sleep "${config[fake_latency]}"
	[[ "${counts}" -gt "${config[retry_cap]}" && "${stop_hash}" != true ]] && declare -r stop_hash=true
	[[ "${stop_hash}" == n ]] && local in_hashed="$(hash)"
	#
	# Input Parsing
	# Print a fake error & exit if the input is too big
	if [[ "${#input}" -gt "${config[stdin_cap]}" ]]; then
		printf "\nrbash: fork: cannot allocate memory\n"
		exit 255
	#
	# Do nothing on empty input
	elif [[ -z "${input}" ]]; then return
	#
	# Mimic rbash restrictions & errors (L1 exclusive)
	elif [[ "${layer_at}" -eq 1 ]]; then
		if [[ "${cmd}" == */* ]]; then
			echo "rbash: ${cmd}: cannot specify \"/\" in command names"
		elif [[ "${cmd}" =~ ^(exit|logout)$ ]]; then
			exit 1
		elif [[ "${cmd}" == sudo ]]; then
			if [[ "${config[fake_root]}" == true ]]
			then sudo echo 'root is not in the sudoers file.  This incident will be reported.'
			else sudo echo "${USER} is not in the sudoers file.  This incident will be reported."
			fi
		elif [[ "${cmd}" == printf ]]; then
			printf '%s' "${input/'printf '//}"
		elif [[ "${cmd}" == echo ]]; then
			printf '%s' "${input/'echo '//}\n"
		elif [[ "${cmd}" =~ ^([a-zA-Z0-9_-]+)= ]]; then
			echo "rbash: ${BASH_REMATCH[1]}: readonly variable"
		elif type -t "${cmd}" &>/dev/null; then
			echo "rbash: ${cmd}: Permission denied"
		fi
		#
		# Just maybe don't try this on epileptic people...
		# Although maybe don't connect to a server via SSH,
		# that can send your terminal anything, if you're epileptic.
		[[ "${config[annoyance_index]}" != 0 ]] && annoyance &
	fi
	#
	# Check for current layers' password
	if [[
		"${stop_hash}" == n &&
		-n "${input}" &&
		"${in_hashed}" == "${target_hash}"
	]]; then
		# Log success
		# Reset fail counter & return success.
		warn pass
		counts=0
		return
	fi
	#
	# Log failure
	warn fail "${input}"
	echo "rbash: ${cmd}: command not found"
	return 1
}
#
# Prevent changing of core logic
declare -rf warn annoyance handover hash passwd_check





#
# The Honey
#
# Check for non-interactive commands
if [[ -n "${SSH_ORIGINAL_COMMAND}" ]]; then
	warn fail "${SSH_ORIGINAL_COMMAND} -- via non-interactive SSH execution"
	exit 10
fi
#
# Fake terminal loop
while true; do
	case "${layer_at}" in
		1)
			# L1 -- False Terminal
			read -t "${config[read_tmout]}" -erp "${PS1}" -n "$(( max_stdin + 1 ))" input || exit 1
			#
			# Check the input & move into next layer if correct.
			passwd_check || break
			[[ "${#passwd_hashes[@]}" -gt 1 ]] || handover
			#
			# Check the input & move into next layer...
			# Or pass into real shell if no more layers.
			# Time to go mute!
			stty -echo
			trap '' INT TERM TSTP
			echo 'This account is currently not available.'
			(( layer_at++ ))
		;;
		2)
			# L2 -- Silence
			read -t "${config[read_tmout]}" -ern "$(( max_stdin + 1 ))" input || exit 1
			#
			# Check the input & move into next layer...
			# Or pass into real shell if no more layers.
			passwd_check || break
			[[ "${#passwd_hashes[@]}" -gt 2 ]] || handover
			(( layer_at++ ))
		;;
		3)
			# L3 -- Silence (Again)
			read -t "${config[read_tmout]}" -ern "$(( max_stdin + 1 ))" input || exit 1
			#
			# Check the input & move into next layer...
			# Or pass into real shell if no more layers.
			passwd_check || break
			[[ "${#passwd_hashes[@]}" -gt 3 ]] || handover
			(( layer_at++ ))
		;;
		*)
			# Fallback for unexpected layer_at values
			layer_at=1
		;;
	esac
done