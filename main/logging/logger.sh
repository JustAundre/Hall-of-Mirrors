#!/usr/bin/env -S /usr/bin/bash --noprofile --norc
#
# Environment Setup
#
[[ -n "$LOG" ]] && exit 252
declare -rx LUID="$(cat /proc/self/loginuid)"
declare -rx LOGNAME="$(getent passwd $LUID | cut -d: -f1)"
declare -rx HOME="$(getent passwd $LUID | cut -d: -f6)"
declare -r LTIME="$(date +%Y-%m-%d-%H-%M-%S)"
logFile="/var/log/sessions/$LOGNAME-at-$LTIME"





#
# Edge-case handling
#
[[ -z "$LOGNAME" ]] && exit 253
[[ -z "$LUID" ]] && exit 254
count=1
while [[ -f "$logFile" ]]; do
	logFile="$logFile-dupe-$count"
done
unset count
declare -r logFile="$logFile.log"





#
# Main Logic
#
if [[ ! -t 0 ]]; then
	[[ -n "$SSH_ORIGINAL_COMMAND" ]] && cmd="with command $SSH_ORIGINAL_COMMAND"
	echo "$LOGNAME/$LUID from $SSH_CLIENT attempted to open non-interactive session $cmd" | systemd-cat -p3 -t logger
	exit 255
fi
exec -c env -i\
	TERM="$TERM"\
	USER="$LOGNAME"\
	LOGNAME="$LOGNAME"\
	LUID="$LUID"\
	SSH_CLIENT="$SSH_CLIENT"\
	SSH_CONNECTION="$SSH_CONNECTION"\
	SSH_TTY="$SSH_TTY"\
	SSH_ORIGINAL_COMMAND="$SSH_ORIGINAL_COMMAND"\
	LOG='y'\
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\
	/usr/bin/script "$logFile" -afqc "su -p $LOGNAME -s /bin/bash"