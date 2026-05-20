#!/usr/bin/env bash
### A script to comprehensively review many types of scheduled tasks.
#
# Cron files
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
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
for u in "${all_users[@]}"; do
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
	confirm "Delete ${trigger}" && systemctl disable --now "${trigger}" && rm -v "${trigger}"
done
#
# Render the changes effective
systemctl daemon-reload