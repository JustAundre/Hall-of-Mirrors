#!/usr/bin/env bash
#
# Environment Setup
#
# Source configuration
. /opt/.bullshrc





#
# The Shell
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
	annoying=
	return
}
#
# Function to check input
passwd_check() {
	local input="${input}"
	local target_hash="${hashes[$((layer_at - 1))]}"
	local cmd="${input%% *}"
	#
	# Update history
	# Simulate a fake delay (if configured)
	history -s "${input}"
	[[ "${config[fake_latency]}" == y ]] && sleep "${config[fake_latency]}"
	#
	# Input Parsing
	# Print a fake error & exit if the input is too big
	if [[ "${#input}" -gt "${config[stdin_cap]}" ]]; then
		printf "\nrbash: fork: cannot allocate memory\n"
		exit 255
	#
	# Do nothing on empty input
	elif [[ -z "${input}" ]]; then return 1
	#
	# Mimic rbash restrictions & errors
	elif [[ "${cmd}" == */* ]]; then
		echo "rbash: ${cmd}: cannot specify '/' in command names"
	elif [[ "${cmd}" =~ ^(exit|logout)$ ]]; then
		exit 1
	elif [[ "${cmd}" == sudo ]]; then
		if [[ "${config[fake_root]}" == true ]]
		then echo 'root is not in the sudoers file.  This incident will be reported.'
		else echo "${USER} is not in the sudoers file.  This incident will be reported."
		fi
	elif [[ "${cmd}" == printf ]]; then
		printf -- %s "${input/'printf '//}"
	elif [[ "${cmd}" == echo ]]; then
		printf -- %s "${input/'echo '//}\n"
	elif [[ "${cmd}" =~ ^([a-zA-Z0-9_-]+)= ]]; then
		echo "rbash: ${BASH_REMATCH[1]}: readonly variable"
	elif type -t "${cmd}" &>/dev/null; then
		echo "rbash: ${cmd}: Permission denied"
	else
		echo "rbash: ${cmd}: command not found"
	fi
	#
	# Just maybe don't try this on epileptic people...
	# Although maybe don't connect to a server via SSH,
	# that can send your terminal anything, if you're epileptic.
	[[ "${config[annoyance_index]}" != 0 ]] && annoyance &
}





#
# The Honey
#
# Fake terminal loop
trap 'echo "${PS1}"' 2
while true; do
	read -t "${config[read_tmout]}" -erp "${PS1}" -n "$(( max_stdin + 1 ))" input || exit 1
	passwd_check
done