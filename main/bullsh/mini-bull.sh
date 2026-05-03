#!/usr/bin/env bash
# Curly brackets to stop output of staging commands
{
	#
	# The Height of the Ceiling (Limits/Anti-DDoS)
	#
	# Kill duplicate sessions from the same user
	pgrep -f "$0" -u "${USER}" |
		grep -v "^$$\$" |
		xargs kill -9





	#
	# The Way the Cog Spins (Configuration)
	#
	# General configuration
	declare -r max_stdin=256 # How big (in bytes) is a response allowed to be
	declare -r hash_rounds=2500 # How many times to hash inputs
	declare -r read_tmout=60 # How many seconds before timing out for inactivity
	declare -r fake_root=y # Fake a root shell? (y/n)
	declare -r fake_delay=y # Should every single command have a small delay to annoy the attackers? (y/n)
	declare -r fake_delay_amount="0.$((RANDOM % 3 + 1))" # How long should the delay be? (in seconds)
	declare -r annoy_type=0 # What kind of annoyance on a wrong password shall await them? (0 = off/none)





	#
	# Set the Stage! -- Error Handling & Configuration Interpretation
	#
	# Integrity measures
	declare -rx TMOUT=1
	#
	# The prompt to show on each new line
	declare -x PS1="[${USER}@${HOSTNAME%%.*} ~]$ "
	[[ "${fake_root}" == y ]] &&
		declare -x PS1="[root@${HOSTNAME%%.*} ~]# "





	#
	# The Shell
	#
	# Function to send an annoyance to the terminal which got the password wrong
	annoyance() {
		# Stop ongoing annoyances to prevent stacking of this CPU-intensive operation
		pkill -P "$$"
		#
		# Check annoyance type
		case "${annoy_type}" in
			1)
				# Flash black & white really fast for a few seconds
				for i in {1..250}
				do
					printf '\e[?5h'
					sleep .01
					printf '\e[?5l'
					sleep .01
				done
			;;
			2)
				# Splat out 512 bytes from /dev/urandom onto the screen
				for i in {1..7}
				do
					sleep 2
					[[ $(( RANDOM % 100 > 80 )) -eq 1 ]] &&
						head -c 512 /dev/urandom
				done
				printf '\n%s' "${PS1}"
			;;
			3)
				# Splat out a random character from /dev/urandom onto a random positon on the screen 500 times at high speeds
				# Hide the cursor
				tput civis
				#
				# Get current screen dimensions
				local rows="$(tput lines)" cols="$(tput cols)"
				#
				# The SPAM
				for i in {1..500}
				do
					# Find a random position within the current window size
					local y="$((RANDOM % rows + 1))"
					local x="$((RANDOM % cols + 1))"
					#
					# Print a random character at the aforementioned position
					printf "\e[%d;%dH%s" "${y}" "${x}" "$(
						head -c 1 /dev/urandom |
							tr -d '\0'
					)"
					#
					# Trigger bell sound just as an extra (may not work on some systems/terminals)
					printf '\a'
				done
				#
				# Move cursor to the bottom & show your cursor again
				printf "\e[%d;1H${PS1}" "${rows}"
				tput cnorm
			;;
			4)
				# For ~1 minute, have a minor chance every 150 milliseconds to 'drop' their input briefly
				for i in {1..400}
				do
					[[ "$(( RANDOM % 100 > 80 ))" -eq 1 ]] &&
						stty -echo
					sleep .15
					stty echo
				done
			;;
			*)
				return 1
			;;
		esac
		return 0
	}
	#
	# Function to check input
	passwd_check() {
		local input="${input}"
		local cmd="${input%% *}"
		#
		# Update history
		# Simulate a fake delay (if configured)
		history -s "${input}"
		[[ "${fake_delay}" == y ]] && sleep "${fake_delay_amount}"
		#
		# Handle common inputs
		if [[ "${#input}" -gt "${max_stdin}" ]]; then
			# Print a fake error & exit
			printf "\nrbash: fork: cannot allocate memory\n"
			exit 255
		#
		# Do nothing on empty input
		elif [[ -z "${input}" ]]; then
			return 1
		elif [[ "${cmd}" == */* ]]; then echo "rbash: ${cmd}: cannot specify '/' in command names" 1>&2
		elif [[
			"${cmd}" == exit ||
			"${cmd}" == logout
		]]; then exit 1
		elif [[ "${cmd}" == sudo ]]; then sudo echo "${USER} is not in the sudoers file.  This incident will be reported." 1>&2
		elif [[ "${cmd}" == printf ]]; then printf -- '%s' "${input/'printf '/}"
		elif [[ "${cmd}" == echo ]]; then printf -- '%s\n' "${input/'echo '/}"
		elif [[ "${cmd}" =~ ^([a-zA-Z0-9_-]+)= ]]; then echo "rbash: ${BASH_REMATCH[1]}: readonly variable"
		elif type -t "${cmd}" &>/dev/null; then echo "rbash: ${cmd}: Permission denied" 1>&2
		else echo "rbash: ${cmd}: command not found" 1>&2
		fi
		annoyance &
	}
} &>/dev/null





#
# The Honey
#
# Fake terminal loop
trap '' 2
while true; do
	read -t "${read_tmout}" -erp "${PS1}" -n "$(( max_stdin + 1 ))" input || exit 1
done