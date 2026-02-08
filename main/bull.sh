#!/usr/bin/bash
#
# Anti-DDoSing
#
# Kill duplicate sessions from the same user
pgrep -f "$0" -u "$USER" | grep -v "^$$\$" | xargs kill -9 2>/dev/null
#
# In the event the fake shell is escaped, near-immediately kick them.
declare -x TMOUT=1
#
# Resource limits
ulimit -u 1000		# No fork bombs!
ulimit -n 10		# Stop disk stress
ulimit -f 1000		# Stop disk stress
ulimit -m 50000		# Don't stress the RAM!!!
ulimit -t 60		# Don't stress the CPU!!!





#
# Environment
#
# Configuration
declare -rx PKGLOG='/var/tmp/install.log' # The location to send warnings to
declare -r passHash1='f02016bf576c54bc5f3160ae1a682b74d00f3d69be709a31dc20a43114627becd08ea97fb203c00492db42526208e4d92ce949f4ad99012500307dd27ecdf3dc' # Password hash for the 1st MFA layer
declare -r passHash2='f02016bf576c54bc5f3160ae1a682b74d00f3d69be709a31dc20a43114627becd08ea97fb203c00492db42526208e4d92ce949f4ad99012500307dd27ecdf3dc' # Password hash for the 2nd MFA layer
declare -r hashRounds=2500 # How many times to hash inputs
declare -r readTimeout=20 # How many seconds before timing out for inactivity
declare -r maxCounts=3 # The max amount of login attempts before all inputs silently fail
declare -r mfaLayers=2 # How many layers of MFA do you want? (Max 2)
declare -r secureCloak='y' # Use custom secure bashrc? (y/n)
declare -r fakeRoot='y' # Fake a root shell? (y/n)
declare -r annoyanceType=0 # What kind of annoyance on a wrong password shall await them? (0 = off/none)
declare -r bullshitDelay='y' # Should every single command have a small delay to annoy the attackers? (y/n)
declare -r bullshitDelayTime='.15' # How long should the bullshit delay be? (in seconds)
declare -r secureCloakPath='/opt/securecloak.sh' # Usually shouldn't need to change this unless you installed it to a custom location
LD_PRELOAD='/opt/chaos-chaos.so' # Usually shouldn't need to change this unless you installed it to a custom location
#
# Staging (Modification of these is ill-advised)
declare -rx HISTCONTROL='' HISTIGNORE='' # By default some commands can be exempted from history with a leading space; this disables that.
declare -rx USER # Anti-spoofing for the USER variable
declare -rx HOSTNAME="$(hostname | awk -F'.' '{ print $1 }')" # Hostname of the machine up to the first dot (exclusive of first dot)
declare -rx PROMPT_COMMAND='echo "User $USER with UID $UID coming from $userIP ran: $(history 1 | sed s/^[ ]*[0-9]*[ ]*//)" | tee -a "$PKGLOG" &>/dev/null | systemd-cat -t "sshd-internal" -p 3' # Log all commands
declare -rx TTY="$(tty | awk -F'/dev/' '{ print $2 }')"
[[ -f "$LD_PRELOAD" ]] && declare -rx LD_PRELOAD || LD_PRELOAD=''
PS1="$USER@$HOSTNAME ~ $ " && [ "$fakeRoot" == "y" ] && PS1="root@$HOSTNAME ~ # " # The prompt to show on each new line
mfaAt=1 # What layer of the MFA to start at
counts=0 # The amount of login attempts to start with
fuckOff="n" # Whether the script stops checking for the password (y/n)
userIP="Local Console" ; [ -n "$SSH_CONNECTION" ] && userIP=$(printf "$SSH_CONNECTION" | awk '{ print $1 }') ; declare -rx userIP SSH_CONNECTION # Grab the SSH IP (with fallback)
#
# Handle various termination signals
trap 'pkill -P $$; exit 1' HUP TERM TSTP QUIT EXIT





#
# Helper Functions
#
# Send identifiers to a log file
warn() {
	echo "⚠️ MFA layer $mfaAt failed by $USER, UID $EUID -- originating from $userIP. Input was: $*\n" | tee -a "$PKGLOG" &>/dev/null | systemd-cat -t "sshd-internal" -p 4
	return
}
#
# Function to send an annoyance to the terminal which got the password wrong
annoyance() {
	# Stop previously triggered annoyances to prevent stacking and spiked CPU usage
	pkill -P "$$"
	#
	# Flash black and white really fast for a few seconds
	if [[ "$annoyanceType" -eq 1 ]]; then
		for i in {1..500}; do
			printf "\e[?5h"
			sleep .0001
			printf "\e[?5l"
			sleep .0001
		done
	# Throw a wall of random bullshit at the terminal
	elif [ "$annoyanceType" -eq 2 ]; then
		for i in {1..7}; do
			if [[ $(echo "($RANDOM / 1100) > 20" | bc -l) -eq 1 ]]; then
				sleep 1
				head -c 512 /dev/urandom
			fi
		done
		printf "\n$PS1"
	# Splatter random bullshit onto the terminal
	elif [[ "$annoyanceType" -eq 3 ]]; then
		# Hide the cursor
		tput civis
		#
		# Get current screen dimensions
		rows=$(tput lines)
		cols=$(tput cols)
		#
		# The SPAM
		for i in {1..500}; do
			# Generate random coordinates within the current window size
			r=$((RANDOM % rows + 1))
			c=$((RANDOM % cols + 1))
			#
			# Print it at the aforementioned coordinates
			printf "\e[%d;%dH%s" "$r" "$c" "$(head -c 2 /dev/urandom | tr -d '\0')"
		done
		#
		# Move cursor to the bottom and show your cursor again
		printf "\e[%d;1H$PS1" "$rows"
		tput cnorm
	else
		return 1
	fi
	return 0
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
	printf -- "%s" "$*" | python3 -c "import hashlib, sys; h = sys.stdin.read().encode(); exec('for _ in range($hashRounds):\n    h = hashlib.sha512(h).hexdigest().encode()'); print(h.decode())"
}
#
# Function to pass into the real shell
passOff() {
	# Log the successful attempt
	echo "✅ MFA layer $mfaAt passed by $USER, UID $EUID -- originating from $userIP." | systemd-cat -t "sshd-internal" -p 5
	#
	# Remove sig traps
	trap - INT TERM TSTP QUIT HUP EXIT
	#
	# Clean up variables
	unset userIP counts fuckOff mfaCounts HISTFILE HISTSIZE TMOUT PS1
	declare -x PS1='\u@\h \w \$ '
	#
	# Apply secure cloak rc file if configured.
	if [[ "$secureCloak" == "y" ]]; then
		builtin exec /usr/bin/env -i\
			TTY="$TTY" PS1="$PS1" HOME="$HOME" TERM="xterm-256color" userIP="$userIP" SSH_CONNECTION="$SSH_CONNECTION" PATH="$PATH" USER="$USER" PKGLOG="$PKGLOG" PROMPT_COMMAND="$PROMPT_COMMAND" HISTCONTROL="$HISTCONTROL" HISTIGNORE="$HISTIGNORE" LD_PRELOAD="$LD_PRELOAD"\
			/usr/bin/bash --rcfile "$secureCloakPath" -i
	else
		builtin exec /usr/bin/env -i\
			TTY="$TTY" PS1="$PS1" HOME="$HOME" TERM="xterm-256color" userIP="$userIP" SSH_CONNECTION="$SSH_CONNECTION" PATH="$PATH" USER="$USER" PKGLOG="$PKGLOG" PROMPT_COMMAND="$PROMPT_COMMAND" HISTCONTROL="$HISTCONTROL" HISTIGNORE="$HISTIGNORE" LD_PRELOAD="$LD_PRELOAD"\
			/usr/bin/bash -i
	fi
}
#
# Function to check input
inputCheck() {
	# Variable scoping/isolation
	local input="$input"
	local PS1="$PS1"
	local mfaAt="$mfaAt"
	local counts="$counts"
	#
	# Add command to history
	history -s "$input"
	#
	# Increase the amount of login attempts by 1
	(( counts++ ))
	#
	# If failed attempts exceed 3, stop checking for the correct password.
	[[ "$counts" -gt 3 && "$fuckOff" != "y" ]] && readonly fuckOff="y"
	#
	# Parse the input into its base command
	local cmd="${input%% *}"
	#
	# Insert bullshit network congestion (if configured)
	[[ "$bullshitDelay" == "y" ]] && sleep "$bullshitDelayTime"
	#
	# Check the input
	if [[ -z "$input" ]]; then
		return 1
	elif [[ "$input" == *"/"* ]]; then
		# Send a warning
		warn "$input"
		#
		# Check each argument of the input and see if it has a forward slash
		read -ra args <<< "$input"
		for i in "$args"; do
			if [[ "$i" == *"/"* ]]; then
				echo "rbash: $i: cannot specify '/' in command names" 1>&2
				break
			fi
		done
		#
		# Fail the attempt
		return 1
	elif [[ "$cmd" == "exit" || "$cmd" == "logout" ]]; then
		exit 1
	elif type -t "$cmd" &>/dev/null; then
		# Send a warning
		warn "$input"
		#
		# If the input is a builtin or command in the $PATH, give a permission denied error.
		echo "rbash: $cmd: Permission denied" 1>&2
		#
		# Fail the attempt
		return 1
	elif [[ "$fuckOff" == "n" && "$mfaAt" -eq 1 && "$(hash $input)" == "$passHash1" ]]; then
		# If the input is the password pass the attempt and reset the counter
		counts=0
		return 0
	elif [[ "$fuckOff" == "n" && "$mfaAt" -eq 2 && "$(hash $input)" == "$passHash2" ]]; then
		# If the input is the password pass the attempt and reset the counter
		counts=0
		return 0
	else
		# Send a warning
		warn "$input"
		#
		# If the input is not the password, a recognizable keyword or command, give a not found error.
		echo "rbash: $cmd: command not found" 1>&2
		#
		# Make some NOISE!!!
		annoyance &
		#
		# Fail the attempt
		return 1
	fi
}





#
# The Backbone
#
# Trap user in a while loop over a fake terminal
while true; do
	# Take user input
	[ "$mfaAt" -eq 1 ] && read -t "$readTimeout" -rep "$PS1" input || exit 1
	#
	# Check input
	if [ "$mfaLayers" -gt 1 ]; then
		if inputCheck; then
			(( mfaAt++ ))
		else
			continue
		fi
		echo "This account is currently not available." 1>&2
		while true; do
			read -t "$readTimeout" -re input || exit 1
			inputCheck && passOff
		done
	else
		inputCheck && passOff
	fi
done