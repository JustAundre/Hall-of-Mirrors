#!/usr/bin/env bash
#
# Environment Setup
#
# Environment variables/checks
[[ -n "${LOG}" ]] && exit 253
declare -rx AUID="$(</proc/self/loginuid)"
declare -rx LOGNAME="$(getent passwd "${AUID}" | cut -d: -f1)"
declare -rx HOME="$(getent passwd "${AUID}" | cut -d: -f6)"
#
# Handle edge-cases
[[ -z "${LOGNAME}" ]] && exit 254
#
# Find an unoccupied file location
count=0
while [[ -f "${log_file}" || -z "${log_file}" ]]; do
	(( count++ ))
	log_file="/var/log/sessions/${LOGNAME}-${count}.log"
done
declare -r log_file="${log_file}"





#
# Main Logic
#
# Stop & log non-interactive sessions
if [[ ! -t 0 ]]; then
	# ...plus any commands
	[[ -n "${SSH_ORIGINAL_COMMAND}" ]] && cmd="with command ${SSH_ORIGINAL_COMMAND}"
	echo "${LOGNAME}/${UID} from ${SSH_CLIENT} attempted to run non-interactive command: (${cmd})" | systemd-cat -p3 -t logger
	exit 255
else
	# Start logging
	[[ -x /opt/bull.sh ]] && exec -c env -i TERM="${TERM}" SSH_CLIENT="${SSH_CLIENT}" SSH_CONNECTION="${SSH_CONNECTION}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/script "${log_file}" -afqc "su -p ${LOGNAME} -s /bin/bash -lc /opt/bull.sh"
	exec -c env -i TERM="${TERM}" SSH_CLIENT="${SSH_CLIENT}" SSH_CONNECTION="${SSH_CONNECTION}" SSH_TTY="${SSH_TTY}" SSH_ORIGINAL_COMMAND="${SSH_ORIGINAL_COMMAND}" /usr/bin/script "${log_file}" -afqc "su -p ${LOGNAME} -s /bin/bash -l"
fi