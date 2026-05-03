#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
#
# Pause and warn
echo "Review and edit the files you're about to be shown as needed."
pause
#
# Review the files
check() {
	command "${EDITOR}" general-confs/slice-individual.conf general-confs/slice-shared.conf general-confs/limits.conf
}
review
#
# Verify the files
while
	! systemd-analyze verify general-confs/slice-individual.conf ||
	! systemd-analyze verify general-confs/slice-shared.conf;
do
	cat <<-'EOF'
		W: SystemD found issue(s) with your configuration.
		i: After you resume, you'll be made to review your configurations again.
	EOF
	pause
	review
done
#
# Install the limits
install -m 640 -o root -g root general-confs/slice-individual.conf /etc/systemd/system/user.slice.d/override.conf
install -m 640 -o root -g root general-confs/slice-shared.conf /etc/systemd/system/user-.slice.d/override.conf
install -m 644 -o root -g root general-confs/limits.conf /etc/security/limits.conf
#
# Reload SystemD
systemctl daemon-reload