
# Session logging logic
if [ -n "$PS1" ] && [ -z "$logging" ]; then
	logDir="/var/tmp"
	prefix="$USER-on-$(\logname)-"
	count=1
	#
	# Determine the final log file path
	while [ -f "${logDir}/${prefix}${count}.raw" ]; do
		count=$((count + 1))
	done
	log="${logDir}/${prefix}${count}.log"
	#
	# Ensure the variables are read-only
	readonly logDir prefix log count
	#
	# Cleanup the logs when shell exits
	cleanup_log() {
		sed -E 's/\x1B\[\??[0-9;]*[a-zA-Z]//g; s/\x1B\(B//g; s/\x08+//g; s/\r//g' "$log" 2>/dev/null | tee "$log" 
	}
	trap cleanup_log EXIT
	#
	# Start logging
	export logging=1
	exec script -qf "$log"
fi