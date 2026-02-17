#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
#
# The Height of the Ceiling (Limits/Anti-DDoS)
#
# Kill duplicate sessions from the same user
pgrep -f "$0" -u "$USER" | grep -v "^$$\$" | xargs kill -9 2>/dev/null
#
# Resource limits
ulimit -u 1000		# No fork bombs!
ulimit -n 64		# Limit file descriptors
ulimit -f 10000		# Stop disk stress
ulimit -m 50000		# Don't stress the RAM!!!
ulimit -t 30		# Don't stress the CPU!!!





#
# The Way the Cog Spins (Configuration)
#
# Password hashes to pass their respective numbered layers (up to 3 layers; only as many layers active as there are hashes)
declare -r passHashes=(
	'e5b98bb4f21fd6a3ab4fe9c6928734f960501ab9217f7f22905804d9a1c0e11a0575b9c79930e3f7ab818d98fcfa93dd4424560afbb8232c7a318689885513a0'
	'c9edc4de9de21784f2e86f2dd087fa8b1670a9442ce614eb2eb1b3358052dd3996b09c3262912fcec67d8ab2d9e4f2fa12e72acb0548cad63ec1af15f9951f17'
	'6899eb9d96ef8fb19d9c09efa879281b453ca4f7339b3a553111ab12a2c3dfcdd9be236712519894d0490032b047dcc49af050554e8037f9332262f362fdd786'
)
declare -r mfaLayers=${#passHashes[@]}
#
# General configuration
declare -r maxIn=256 # How big (in bytes) is a response allowed to be parsed
declare -r hashRounds=2500 # How many times to hash inputs
declare -r readTimeout=30 # How many seconds before timing out for inactivity
declare -r maxCounts=3 # The max amount of login attempts before all inputs silently fail
declare -r secureCloak=y # Use custom secure bashrc? (y/n)
declare -r fakeRoot=y # Fake a root shell? (y/n)
declare -r fakeDelay=y # Should every single command have a small delay to annoy the attackers? (y/n)
declare -r fakeDelayTime="0.$((RANDOM % 3 + 1))" # How long should the delay be? (in seconds)
declare -r annoyanceType=0 # What kind of annoyance on a wrong password shall await them? (0 = off/none)
mfaAt=1 # What layer of the MFA to start at
counts=0 # The amount of login attempts to start with
goAway="n" # Whether the script stops checking for the password (y/n)
bsfsHeader="\n\n\e[1;33m$USER/$UID with EUID $EUID has entered the decoy filesystem at $(date +%s) from $userIP on $TTY\e[0m\n\n" # The header to print at the top of every bsfs log




#
# Set the Stage! -- Error Handling & Configuration Interpretation
#
# Integrity measures
declare -rx HISTCONTROL='' HISTIGNORE=''
declare -rx USER
declare -rx HOSTNAME="${HOSTNAME%%.*}"
declare -rx TTY="$(tty | awk -F'/dev/' '{ print $2 }')"
declare -rx TMOUT=1
#
# Dependency location definition
declare -r ldPreloadPath='/opt/chaos-chaos.so'
declare -rx secureCloakPath='/opt/securecloak.sh'
declare -rx bsfsDir='/opt/bsfs'
#
# Logging locations/identifiers
declare -rx bsfsLog="/var/tmp/$USER-$UID-bsfs-$(date +%s).log"
declare -rx logFile='/var/tmp/shell.log'
declare -rx mfaLog='sshd-internal'
declare -rx allLog='sshd-all'
#
# The prompt to show on each new line
declare -x PS1="[$USER@$HOSTNAME ~]$ "
[[ "$fakeRoot" == "y" ]] && declare -x PS1="[root@$HOSTNAME ~]# "
#
# Dynamic handling for SSH_CONNECTION/userIP
userIP="Local Console"
[[ -n "$SSH_CONNECTION" ]] && userIP=${SSH_CONNECTION%% *}
declare -rx userIP SSH_CONNECTION
#
# Log everything
PROMPT_COMMAND='
	lastHist=$(history 1)
	lastCmd=$(echo "$lastHist" | sed "s/^[ ]*[0-9]*[ ]*//")
	if [[ -n "$lastCmd" ]]; then
		printf "EUID: %s | User: %s | IP: %s | TTY: %s | Cmd: %q\n"\
			"$EUID" "$USER" "$userIP" "$TTY" "$lastCmd"\
			| tee -a "$logFile" | systemd-cat -t "$allLog" -p 5
	fi
'
#
# Return the user's terminal's echo if the connection drops
trap 'stty echo' EXIT





#
# The Bricks of the Lego Set (Helper Functions)
#
# Send identifiers to a log file
warn() {
	local input=$(printf "%q" "$*")
	case "$1" in
		1)
			shift 1
			local msg="⚠️ MFA layer $mfaAt failed | User: $USER/$UID | IP: $userIP | TTY: $TTY | Input with EUID $EUID: $input"
			echo "$msg" | tee -a "$logFile" | systemd-cat -t "$mfaLog" -p 4
		;;
		2)
			local msg="✅ MFA layer $mfaAt passed | User: $USER/$UID | IP: $userIP | TTY: $TTY | EUID: $EUID"
			echo "$msg" | tee -a "$logFile" | systemd-cat -t "$mfaLog" -p 5
		;;
		3)
			local msg="✅ Passed into the REAL SYSTEM TERMINAL | User: $USER/$UID | IP: $userIP | TTY: $TTY | EUID: $EUID"
			echo "$msg" | tee -a "$logFile" | systemd-cat -t "$mfaLog" -p 3
		;;
		*)
			echo '❌: The warn function was called with a non-existent warning type.'
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
	# Flash black and white really fast for a few seconds
	case "$annoyanceType" in
		1)
			for i in {1..500}; do
				printf '\e[?5h'
				sleep 0.0001
				printf '\e[?5l'
				sleep 0.0001
			done
		;;
		2)
			for i in {1..7}; do
				sleep 1.5
				[[ $(( RANDOM % 100 > 80 )) -eq 1 ]] && head -c 512 /dev/urandom
			done
			printf "\n%s" "$PS1"
		;;
		3)
			# Hide the cursor
			tput civis
			#
			# Get current screen dimensions
			rows=$(tput lines)
			cols=$(tput cols)
			#
			# The SPAM
			for i in {1..500}; do
				# Find a random position within the current window size
				r=$((RANDOM % rows + 1))
				c=$((RANDOM % cols + 1))
				#
				# Print a random character at the aforementioned position
				printf "\e[%d;%dH%s" "$r" "$c" "$(head -c 1 /dev/urandom | tr -d '\0')"
				#
				# Trigger bell sound just as an extra (may not work on some systems/terminals)
				printf '\a'
			done
			#
			# Move cursor to the bottom and show your cursor again
			printf "\e[%d;1H$PS1" "$rows"
			tput cnorm
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
	# Remove sig traps
	trap - INT TERM TSTP QUIT HUP EXIT
	#
	# Clean up environment
	stty echo
	declare -x PS1='[\u@\h \w]\$ '
	#
	# Apply secure cloak rc file if configured.
	if [[ "$secureCloak" == "y" ]]; then
		builtin exec /usr/bin/env -i\
			logFile="$logFile" mfaLog="$mfaLog" allLog="$allLog" TTY="$TTY" PS1="$PS1" HOME="$HOME" TERM="xterm-256color" userIP="$userIP" SSH_CONNECTION="$SSH_CONNECTION" PATH="$PATH" USER="$USER" PROMPT_COMMAND="$PROMPT_COMMAND" HISTCONTROL="$HISTCONTROL" HISTIGNORE="$HISTIGNORE" LD_PRELOAD="$LD_PRELOAD"\
			/usr/bin/bash --rcfile "$secureCloakPath" -i
	else
		builtin exec /usr/bin/env -i\
			logFile="$logFile" mfaLog="$mfaLog" allLog="$allLog" TTY="$TTY" PS1="$PS1" HOME="$HOME" TERM="xterm-256color" userIP="$userIP" SSH_CONNECTION="$SSH_CONNECTION" PATH="$PATH" USER="$USER" PROMPT_COMMAND="$PROMPT_COMMAND" HISTCONTROL="$HISTCONTROL" HISTIGNORE="$HISTIGNORE" LD_PRELOAD="$LD_PRELOAD"\
			/usr/bin/bash -i
	fi
}
#
# Function to hash input
hash() {
	# Variable scoping/isolation
	local input="$input"
	local PS1="$PS1"
	local mfaAt="$mfaAt"
	local counts="$counts"
	#
	# Hash the input
	printf -- "%s" "$input" | python3 -c "import hashlib, sys; h = sys.stdin.read().encode(); exec('for _ in range($hashRounds):\n    h = hashlib.sha512(h).hexdigest().encode()'); print(h.decode())"
}
#
# Function to check input
pwdChk() {
	(( counts++ ))
	local input="$input"
	local inputHashed=""
	local targetHash="${passHashes[$((mfaAt - 1))]}"
	local cmd="${input%% *}"
	local currentTarget="passHash$mfaAt"
	[[ "$mfaAt" -eq 1 ]] && history -s "$input" # Update history (L1 exclusive)
	[[ "$fakeDelay" == "y" ]] && sleep "$fakeDelayTime" # Simulate a fake delay (if configured)
	[[ "$counts" -gt "$maxCounts" && "$goAway" != "y" ]] && readonly goAway="y" # Silently lock out after maxCounts
	[[ "$goAway" == "n" ]] && inputHashed="$(hash)" || inputHashed="" # Generate hash only if not locked out
	#
	# Handle common inputs
	if [[ "${#input}" -gt $maxIn ]]; then
		# Flush stdin
		while read -t 0.0001 -n 10000 _; do
			:
		done
		#
		# Print a fake error and exit
		printf "\nrbash: fork: cannot allocate memory\n"
		exit 255
	elif [[ -z "$input" ]]; then
		# Do nothing on empty input
		:
	elif [[ "$mfaAt" -eq 1 ]]; then
		# Mimic rbash restrictions and errors (L1 exclusive)
		if [[ "$cmd" == *"/"* ]]; then
			echo "rbash: $cmd: cannot specify '/' in command names" 1>&2
		elif [[ "$cmd" == "exit" || "$cmd" == "logout" ]]; then
			exit 1
		elif [[ "$cmd" == "sudo" ]]; then
			sudo echo "$USER is not in the sudoers file.  This incident will be reported." 1>&2
		elif type -t "$cmd" &>/dev/null; then
			echo "rbash: $cmd: Permission denied" 1>&2
		else
			echo "rbash: $cmd: command not found" 1>&2
		fi
		annoyance &
	fi
	#
	# Check for current layers' password
	if [[ "$goAway" == "n" && -n "$input" && "$inputHashed" == "$targetHash" ]]; then
		warn 2 # Log success for this layer
		counts=0
		return 0
	fi
	#
	# Log failure
	warn 1 "$input"
	return 1
}





#
# Gorilla Glue (The Main Logic)
#
# Check for non-interactive commands
if [[ -n "$SSH_ORIGINAL_COMMAND" ]]; then
	warn 1 "$SSH_ORIGINAL_COMMAND -- via non-interactive SSH execution"
	exit 10
fi
#
# Prevent changing of core logic
declare -rf warn annoyance handover fakeSuccess hash pwdChk
#
# Fake terminal loop
while true; do
	case "$mfaAt" in
		1)
			# L1 -- False Terminal
			read -t "$readTimeout" -rep "$PS1" -n $(( $maxIn + 1 )) input || exit 1
			if pwdChk; then
				[[ "$mfaLayers" -gt 1 ]] || handover
				#
				# L2 Setup -- Time to go mute!
				stty -echo
				trap '' INT TERM TSTP
				echo "This account is currently not available." 1>&2
				(( mfaAt++ ))
			fi
		;;
		2)
			# L2 -- Silence
			read -t "$readTimeout" -ren $(( $maxIn + 1 )) input || exit 1
			if pwdChk; then
				[[ "$mfaLayers" -gt 2 ]] || handover
				(( mfaAt++ ))
			fi
		;;
		3)
			# L3 -- Silence (The Sequel)
			read -t "$readTimeout" -ren $(( $maxIn + 1 )) input || exit 1
			pwdChk && handover
		;;
		*)
			# Fallback for unexpected mfaAt values
			mfaAt=1
		;;
	esac
done