#!/usr/bin/env bash
### Uses SystemD slices & /etc/security/limits.conf in tandem to help prevent 1 user from using too many system resources.
#
# Verify and Review
#
# Pause and warn
echo $'Review and edit the files you\'re about to be shown as needed.'
pause
#
# Verify the files
while
	systemd-analyze verify cnf/rsc-caps/slice-individual.slice 2>&1 | grep -q invalid ||
	systemd-analyze verify cnf/rsc-caps/slice-shared.slice 2>&1 | grep -q invalid
do
	[[ -z "${ran}" ]] && ran=true || echo 'W: SystemD found issue(s) with your configuration.'
	echo $'i: After you resume, you\'ll be made to review your configurations again.' && pause
	"${EDITOR}" cnf/rsc-caps/slice-individual.conf cnf/rsc-caps/slice-shared.conf cnf/rsc-caps/limits.conf
done





#
# Installation
#
# Install the limits
install -m 640 -o root -g root cnf/rsc-caps/slice-individual.slice /etc/systemd/system/user.slice.d/override.conf
install -m 640 -o root -g root cnf/rsc-caps/slice-shared.slice /etc/systemd/system/user-.slice.d/override.conf
install -m 644 -o root -g root cnf/rsc-caps/limits.conf /etc/security/limits.conf
#
# Reload SystemD
systemctl daemon-reload