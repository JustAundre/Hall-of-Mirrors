#!/usr/bin/env bash
#
# Anti-DDoS
#
# Kill extra sessions of the script from the same user
pgrep -f "${0}" -u "${USER}" | grep -v "^$$\$" | xargs kill -9





#
# Configuration
#
# Configure hashes used for authentication (SHA-256).
declare -r hashes=(
	e5b98bb4f21fd6a3ab4fe9c6928734f960501ab9217f7f22905804d9a1c0e11a0575b9c79930e3f7ab818d98fcfa93dd4424560afbb8232c7a318689885513a0
	c9edc4de9de21784f2e86f2dd087fa8b1670a9442ce614eb2eb1b3358052dd3996b09c3262912fcec67d8ab2d9e4f2fa12e72acb0548cad63ec1af15f9951f17
	6899eb9d96ef8fb19d9c09efa879281b453ca4f7339b3a553111ab12a2c3dfcdd9be236712519894d0490032b047dcc49af050554e8037f9332262f362fdd786
)
#
# General BullSH configurations
declare -Ar config=(
	# Configure where to log to
	# Set log_file to /dev/null to disable to-file logging.
	# JournalCTL logging is required right now.
	[log_file]=/var/tmp/shell.log
	[log_tag]=bullsh
	#
	# Limitations
	# stdin_cap limits how many characters can be parsed.
	# stdin_cap can parse up to its value + 1 due to the way it is scripted.
	# timeout determines how long a user has to press enter before being forced out.
	# retry_cap determines how many times BullSH will attempt to hash the user's inputs for the password before quitting hashing.
	[stdin_cap]=256
	[timeout]=30
	[retry_cap]=5
	#
	# Extra Flare
	# fake_root determines whether the PS1 variable will display 'root' as the user. Takes a boolean of y/n, T/F, or 1/0.
	# fake_latency determines how much delay there is between each [ENTER].
	# annoyance_index determines what kind of fate awaits the user when their input is not the password.
	[fake_root]=true
	[fake_latency]="0.$((RANDOM % 3 + 1))"
	[annoyance_index]=0
	#
	# Advanced Options
	# hashing_rounds determines for how many rounds will input be hashed
	[hashing_rounds]=2500
)





#
# Safety Nets/Dynamic Variables
#
# TMOUT kills *real* shells after 1 second of inactivity. Acts as a safety net in the event of a command injection vuln.
# Python logic to use for quick hashing
declare -rx TMOUT=1
declare -r python_hashing_logic="import hashlib, sys; h = sys.stdin.read().encode(); exec('for _ in range(${config[hashing_rounds]}):\n    h = hashlib.sha512(h).hexdigest().encode()'); print(h.decode())"
#
# What layer of the MFA to start at
# Whether the script stops checking for the password (y/n)
# The amount of login attempts to start with
layer_at=1
stop_hash=true
counts=0
#
# The prompt to show on each new line
[[ "${config[fake_root]}" == true ]] &&
	declare -x PS1="[root@${HOSTNAME%%.*} ~]# " ||
	declare -x PS1="[${USER}@${HOSTNAME%%.*} ~]$ "
#
# Log everything
IFS= read -rd '' PROMPT_COMMAND <<-EOF
	history -a
	last_cmd=\$(sed 's/^[ ]*[0-9]*[ ]*//' <<<"\$(history 1)")
	[[ -n "\$last_cmd" ]] &&
		echo "EUID: \${EUID} | UID: ${UID} | User: ${USER} | IP: ${SSH_CLIENT%% *} | TTY: ${SSH_TTY} | Cmd: \${last_cmd}" |
		tee -a "${config[log_file]}" | systemd-cat -t "${config[log_tag]}"
EOF
declare -r PROMPT_COMMAND
#
# Dynamic handling for SSH_CONNECTION/ip_from
[[ -z "${SSH_CLIENT}" ]] && SSH_CLIENT=Local