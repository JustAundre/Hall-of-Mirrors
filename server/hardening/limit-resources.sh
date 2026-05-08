#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
#
# Pause and warn
echo $'Review and edit the files you\'re about to be shown as needed.'
pause
#
# Verify the files
while
	systemd-analyze verify general-confs/slice-individual.slice 2>&1 | grep -q invalid ||
	systemd-analyze verify general-confs/slice-shared.slice 2>&1 | grep -q invalid
do
	if [[ -z "${ran}" ]]
	then ran=true
	else echo 'W: SystemD found issue(s) with your configuration.'
	fi
	echo $'i: After you resume, you\'ll be made to review your configurations again.'
	pause
	"${EDITOR}" general-confs/slice-individual.conf general-confs/slice-shared.conf general-confs/limits.conf
done
#
# Install the limits
install -m 640 -o root -g root general-confs/slice-individual.slice /etc/systemd/system/user.slice.d/override.conf
install -m 640 -o root -g root general-confs/slice-shared.slice /etc/systemd/system/user-.slice.d/override.conf
install -m 644 -o root -g root general-confs/limits.conf /etc/security/limits.conf
#
# Reload SystemD
systemctl daemon-reload