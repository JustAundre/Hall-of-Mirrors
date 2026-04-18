#!/usr/bin/env bash
#
# Environment Setup
#
# Curly brackets to silence errors
{
	# Environment variables/checks
	[[ -n "${LOG}" ]] &&
		exit 253
	declare -rx AUID="$(</proc/self/loginuid)"
	declare -rx LOGNAME="$(
		getent passwd "${AUID}" |
			cut -d: -f1
	)"
	declare -rx HOME="$(
		getent passwd "${AUID}" |
			cut -d: -f6
	)"
	declare -r timestamp="$(date +%Y-%m-%d-%H-%M-%S)"
	log_file="/var/log/sessions/${LOGNAME}-at-${timestamp}"





	#
	# Edge-case handling
	#
	# Handle unexpected/rare errors
	[[ -z "${LOGNAME}" ]] &&
		exit 254
	#
	# Find an unused file name
	count=1
	while [[ -f "${log_file}" ]]; do
		log_file="${log_file}-dupe-${count}"
	done
	declare -r log_file="${log_file}.log"
} &>/dev/null





#
# Main Logic
#
# Stop & log non-interactive sessions
if [[ ! -t 0 ]]; then
	# ...plus any commands
	if [[ -n "${SSH_ORIGINAL_COMMAND}" ]]; then
		cmd="with command ${SSH_ORIGINAL_COMMAND}"
	fi
	echo "${LOGNAME}/${UID} from ${SSH_CLIENT} attempted to run non-interactive command: (${cmd})" |
		systemd-cat -p3 -t logger
	exit 255
else
	# Start logging
	exec -c env -i TERM="${TERM}" SSH_CLIENT="${SSH_CLIENT}" SSH_CONNECTION="${SSH_CONNECTION}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/script "${log_file}" -afqc "su -p ${LOGNAME} -s /bin/bash -l"
fi