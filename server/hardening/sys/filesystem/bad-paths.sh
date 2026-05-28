log i 'Scanning for filepaths allowed by the Linux kernel but which may cause unexpected behavior...'
log i 'The recommended method of viewing generated log files is using the "less -R" command or "cat -A".'
#
# Review non-ascii paths
mapfile -td '' naps < <(
	find / -mindepth 1 ! -iregex '^[\x00-\x7F\n]+$' -print0 |
		tee "non-ascii-paths-${session_id}.log"
)
[[ -s "non-ascii-paths-${session_id}.log" ]] && log w 'There are paths on your system which contain non-ASCII characters or a newline.'
#
# Review hyphen-initiated paths
mapfile -td '' hips < <(
	find / -mindepth 1 -name '-*' -print0 |
		tee "hyphen-initiated-paths-${session_id}.log"
)
[[ -s "hyphen-initiated-paths-${session_id}.log" ]] && log w 'There are paths on your system which begin with 1 or more hyphens.'