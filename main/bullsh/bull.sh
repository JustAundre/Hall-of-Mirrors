#!/usr/bin/env bash
# Curly brackets to stop output of staging commands
{
	#
	# The Height of the Ceiling (Limits/Anti-DDoS)
	#
	# Stop terminal feedback
	stty -echo
	#
	# Kill duplicate sessions from the same user
	pgrep -f "$0" -u "${USER}" |
		grep -v "^$$\$" |
		xargs kill -9





	#
	# The Way the Cog Spins (Configuration)
	#
	# Password hashes to pass their respective numbered layers (up to 3 layers; only as many layers active as there are hashes)
	declare -r passwd_hashes=(
		'e5b98bb4f21fd6a3ab4fe9c6928734f960501ab9217f7f22905804d9a1c0e11a0575b9c79930e3f7ab818d98fcfa93dd4424560afbb8232c7a318689885513a0'
		'c9edc4de9de21784f2e86f2dd087fa8b1670a9442ce614eb2eb1b3358052dd3996b09c3262912fcec67d8ab2d9e4f2fa12e72acb0548cad63ec1af15f9951f17'
		'6899eb9d96ef8fb19d9c09efa879281b453ca4f7339b3a553111ab12a2c3dfcdd9be236712519894d0490032b047dcc49af050554e8037f9332262f362fdd786'
	)
	declare -r auth_layers="${#passwd_hashes[@]}"
	#
	# General configuration
	declare -r max_stdin=256 # How big (in bytes) is a response allowed to be parsed
	declare -r hash_rounds=2500 # How many times to hash inputs
	declare -r read_tmout=30 # How many seconds before timing out for inactivity
	declare -r max_tries=3 # The max amount of login attempts before all inputs silently fail
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
	# Logging locations/identifiers
	declare -r log_file='/var/tmp/shell.log'
	declare -r bullsh_auth_log=bullsh-mfa
	declare -r bullsh_cmd_log=bullsh-cmds
	#
	# What layer of the MFA to start at
	layer_at=1
	#
	# The amount of login attempts to start with
	counts=0
	#
	# Whether the script stops checking for the password (y/n)
	stop_hash="n"
	#
	# The prompt to show on each new line
	declare -x PS1="[${USER}@${HOSTNAME} ~]$ "
	[[ "${fake_root}" == y ]] &&
		declare -x PS1="[root@${HOSTNAME} ~]# "
	#
	# Dynamic handling for SSH_CONNECTION/ip_from
	[[ -z "${SSH_CLIENT}" ]] &&
		SSH_CLIENT=local_tty
	#
	# Log everything
	IFS='' read -rd '' PROMPT_COMMAND <<-'EOF'
		history -a
		last_cmd=$(echo "$(history 1)" | sed 's/^[ ]*[0-9]*[ ]*//')
		if
			[[ -n "$last_cmd" ]]
		then
			printf 'EUID: %s | UID: %s | User: %s | IP: %s | TTY: %s | Cmd: %q\n'\
				"$EUID" "$UID" "$USER" "${SSH_CLIENT%% *}" "$SSH_TTY" "$last_cmd" |
				tee -a "$log_file" | systemd-cat -p5 -t "$bullsh_cmd_log"
		fi
	EOF
	#
	# Python logic to use for quick hashing
	declare -r python_hashing_logic="import hashlib, sys; h = sys.stdin.read().encode(); exec('for _ in range(${hash_rounds}):\n    h = hashlib.sha512(h).hexdigest().encode()'); print(h.decode())"





	#
	# The Shell
	#
	# Send identifiers to a log file
	warn() {
		local input="$(printf "%q" "$*")"
		case "$1" in
			1)
				shift 1
				local msg="W: MFA layer ${layer_at} failed | User: ${USER}/${UID} | IP: ${SSH_CLIENT%% *} | TTY: ${TTY} | Input with EUID ${EUID}: ${input}"
				printf -- '%s' "${msg}" |
					tee -a "${log_file}" |
					systemd-cat -p4t "${bullsh_auth_log}"
			;;
			2)
				local msg="OK: MFA layer ${layer_at} passed | User: ${USER}/${UID} | IP: ${SSH_CLIENT%% *} | TTY: ${TTY} | EUID: ${EUID}"
				printf -- '%s' "${msg}" |
					tee -a "${log_file}" |
					systemd-cat -p5t "${bullsh_auth_log}"
			;;
			3)
				local msg="OK: Passed into the REAL SYSTEM TERMINAL | User: ${USER}/${UID} | IP: ${SSH_CLIENT%% *} | TTY: ${TTY} | EUID: ${EUID}"
				printf -- '%s' "${msg}" |
					tee -a "${log_file}" |
					systemd-cat -p3t "${bullsh_auth_log}"
			;;
			*)
				echo 'E: The warn function was called with a non-existent warning type.'
				exit 9
			;;
		esac
	}
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
	# Function to pass into the real shell
	handover() {
		# Log the successful attempt
		warn 3
		#
		# Clean up environment
		trap - INT TERM TSTP EXIT
		stty echo
		#
		# Enter into logger script if exists
		if
			[[ -x /opt/logger.sh ]]
		then
			builtin exec /usr/bin/env -i SSH_CONNECTION="${SSH_CONNECTION}" SSH_CLIENT="${SSH_CLIENT}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/bash -il
		else
			builtin exec /usr/bin/env -i SSH_CONNECTION="${SSH_CONNECTION}" SSH_CLIENT="${SSH_CLIENT}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/bash -ilc 'sudo /opt/logger.sh'
		fi
	}
	#
	# Function to hash input
	hash() {
		# Variable scoping/isolation
		local input="${input}"
		local PS1="${PS1}"
		local layer_at="${layer_at}"
		local counts="${counts}"
		#
		# Hash the input
		printf -- '%s' "${input}" |
			python3 -c "${python_hashing_logic}"
	}
	#
	# Function to check input
	passwd_check() {
		(( counts++ ))
		local input="${input}"
		local target_hash="${passwd_hashes[$((layer_at - 1))]}"
		local cmd="${input%% *}"
		#
		# Update history (L1 exclusive)
		# Simulate a fake delay (if configured)
		# Silently lock out after max_tries
		# Generate hash only if not locked out
		[[ "${layer_at}" -eq 1 ]] &&
			history -s "${input}"
		[[ "${fake_delay}" == y ]] &&
			sleep "${fake_delay_amount}"
		[[
			"${counts}" -gt "${max_tries}" &&
			"${stop_hash}" != y
		]] &&
			readonly stop_hash=y
		[[ "${stop_hash}" == n ]] &&
			local in_hashed="$(hash)"
		#
		# Handle common inputs
		if
			[[ "${#input}" -gt "${max_stdin}" ]]
		then
			# Print a fake error & exit
			printf "\nrbash: fork: cannot allocate memory\n"
			exit 255
		elif
			[[ -z "${input}" ]]
		then
			# Do nothing on empty input
			:
		elif
			[[ "${layer_at}" -eq 1 ]]
		then
			# Mimic rbash restrictions & errors (L1 exclusive)
			if
				[[ "${cmd}" == */* ]]
			then
				echo "rbash: ${cmd}: cannot specify '/' in command names" 1>&2
			elif 
				[[
					"${cmd}" == exit ||
					"${cmd}" == logout
				]]
			then
				exit 1
			elif
				[[ "${cmd}" == sudo ]]
			then
				sudo echo "${USER} is not in the sudoers file.  This incident will be reported." 1>&2
			elif
				[[ "${cmd}" == printf ]]
			then
				input="${input/'printf '//}"
				printf -- %s "${input}"
			elif
				[[ "${cmd}" == echo ]]
			then
				input="${input/'echo '//}"
				printf -- %s "${input}\n"
			elif
				[[ "${cmd}" =~ ^([a-zA-Z0-9_-]+)= ]]
			then
				echo "rbash: ${BASH_REMATCH[1]}: readonly variable"
			elif
				type -t "${cmd}" &>/dev/null
			then
				echo "rbash: ${cmd}: Permission denied" 1>&2
			else
				echo "rbash: ${cmd}: command not found" 1>&2
			fi
			annoyance &
		fi
		#
		# Check for current layers' password
		if
			[[
				"${stop_hash}" == "n" &&
				-n "${input}" &&
				"${in_hashed}" == "${target_hash}"
			]]
		then
			# Log success
			warn 2
			#
			# Return success & reset fail counter
			counts=0
			return 0
		fi
		#
		# Log failure
		warn 1 "${input}"
		return 1
	}
	#
	# Prevent changing of core logic
	declare -rf warn annoyance handover false_enter hash passwd_check
} &>/dev/null





#
# The Honey
#
# Check for non-interactive commands
if
	[[ -n "${SSH_ORIGINAL_COMMAND}" ]]
then
	warn 1 "${SSH_ORIGINAL_COMMAND} -- via non-interactive SSH execution"
	exit 10
fi
#
# Fake terminal loop
while
	true
do
	case "${layer_at}" in
		1)
			# L1 -- False Terminal
			read -t "${read_tmout}" -erp "${PS1}" -n "$(( max_stdin + 1 ))" input ||
				exit 1
			if
				passwd_check
			then
				[[ "${auth_layers}" -gt 1 ]] ||
					handover
				#
				# L2 Setup -- Time to go mute!
				stty -echo
				trap '' INT TERM TSTP
				echo 'This account is currently not available.' 1>&2
				(( layer_at++ ))
			fi
		;;
		2)
			# L2 -- Silence
			read -t "${read_tmout}" -ern "$(( max_stdin + 1 ))" input ||
				exit 1
			if
				passwd_check
			then
				[[ "${auth_layers}" -gt 2 ]] ||
					handover
				(( layer_at++ ))
			fi
		;;
		3)
			# L3 -- Silence (The Sequel)
			read -t "${read_tmout}" -ern "$(( max_stdin + 1 ))" input ||
				exit 1
			if
				passwd_check
			then
				[[ "${auth_layers}" -gt 3 ]] ||
					handover
				(( layer_at++ ))
			fi
		;;
		*)
			# Fallback for unexpected layer_at values
			layer_at=1
		;;
	esac
done