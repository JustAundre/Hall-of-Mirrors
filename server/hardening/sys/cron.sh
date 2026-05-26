#!/usr/bin/env bash
### A script to comprehensively review many types of scheduled tasks.
#
# Opening Heads Up
#
log i <<-'EOF'
	You'll be put into a text editor to review/edit scheduled tasks;
	    You'll be prompted to delete the file or not.
EOF
pause





#
# (Ana)Cron files
#
# Check /etc/cron* files
hash crond && find /etc/cron* /var/spool/anacron/cron* /etc/anacrontab -type f \
	-exec log i 'Reviewing cron file "{}"...' \; \
	-exec sleep 2.5 \; \
	-exec "${EDITOR}" {} \; \
	-exec rm -vi {} \; \
	</dev/tty





#
# Crontabs
#
# Prompt to review/edit the crontab of each user
# Prompt to delete the crontab of each user
hash crontab && for u in "${all_users[@]}"; do
	log i "Reviewing the crontab for user \"${u}\"..."
	sleep 2.5
	crontab -eu "${u}"
	crontab -riu "${u}"
done





#
# AtD Jobs
#
# AtD does not have a standardized directory where
# it stores Atd jobs, so you have to dig deep into its binary for it.
if hash atd; then
	while read -r path; do
		[[ -d "${path}" && -x "${path}" ]] && atd_dir="${path}" || break
		find "${atd_dir}" ! -name '.SEQ' -type f \
			-exec sleep 2.5 \; \
			-exec "${EDITOR}" {} \; \
			-exec rm -vi {} \; \
			</dev/tty
		break
	done < <(strings "$(which atd)" | grep -Eo '/var/spool/.+')
	[[ -z "${atd_dir}" ]] && log w $'AtD is installed, but the directory where AtD jobs are stored couldn\'t be located.'
fi





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
for trigger in "${triggers[@]}"; do
	"${EDITOR}" "${trigger}" &&
		confirm "Delete ${trigger}" &&
		systemctl disable --now "${trigger}" &&
		rm -v "${trigger}"
done
#
# Pushes changes into SystemD
systemctl daemon-reload