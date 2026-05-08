#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Cron* files
#
# Check /etc/cron* files
cat <<-'EOF'
	i: You'll be put into a text editor to review/edit crontab files;
	i: You'll be prompted to delete the file or not.
EOF
pause
find /etc/cron* -maxdepth 2 -type f -exec "${EDITOR}" {} \; -exec rm -vi {} \;





#
# Crontabs
#
# Enumerates all users on the system
mapfile -t all_usernames < <(
	cat /etc/passwd |
		cut -d: -f1
)
#
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
for u in "${all_usernames[@]}"
do
	crontab -eu "${u}"
	crontab -riu "${u}"
done





#
# SystemD .timers & .paths
#
# Map out the .timers/.paths
mapfile -t triggers < <(
	systemctl list-units --all --plain --no-legend |
		awk '{print $1}' |
		xargs systemctl show -p FragmentPath --value -- |
		xargs grep -E '\.(timer|path)$'
)
#
# Audit them & act accordingly.
cat <<-'EOF'
	i: You'll be put into a text editor to review/edit SystemD .timer/.path files;
	i: You'll be prompted to delete the file or not.
EOF
pause
for trigger in "${triggers[@]}"; do
	"${EDITOR}" "${trigger}"
	confirm "Delete ${trigger}" &&
		systemctl disable --now "${trigger}" &&
		rm -v "${trigger}"
done
#
# Render the changes effective
systemctl daemon-reload