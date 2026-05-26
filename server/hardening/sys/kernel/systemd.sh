#
# SystemD Configuration
#
# Disable core dumping
(
	declare -x target_file=/etc/systemd/coredump.conf delimiter=\=
	reconfig Storage none
	reconfig ProcessSizeMax 0
)