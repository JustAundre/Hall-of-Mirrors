#!/bin/bash
[[ "$EUID" != 0 ]] || exit 1
declare -r PID=$(machinectl show jail -p Leader --value 2>/dev/null) || exit 2
[[ -z "$PID" || "$PID" == "0" ]] && exit 3
logDir="/var/log/jail-audits"
mkdir -p /var/log/jail-audits && chmod 700 /var/log/jail-audits
logFile="$logDir/$(date +%s).log"

exec /usr/bin/script -qf -c "
	/usr/bin/nsenter -t $PID -m -u -i -n -p\
	/usr/bin/env -i\
	HOME=/root\
	TERM=xterm-256color\
	PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin\
	/bin/bash -c 'exec -a \"[kworker/u2:1-ev]\" /bin/bash'
" "$logFile"