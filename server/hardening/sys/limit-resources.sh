#!/usr/bin/env bash
### Uses SystemD slices & /etc/security/limits.conf in tandem to help prevent 1 user from using too many system resources.
#
# Modify/Verify
#
# Heads up!
echo $'Review and edit the files you\'re about to be shown as needed.'
pause
#
# Edit/validify slices
(while
	systemd-analyze verify cnf/rsc-caps/slice-individual.slice 2>&1 | grep invalid ||
	systemd-analyze verify cnf/rsc-caps/slice-shared.slice 2>&1 | grep invalid
do
	if [[ -z "${ran}" ]]; then
		ran=true
	else
		log w 'SystemD found issue(s) with your configuration.'
		log i $'After you resume, you\'ll be made to revise your configurations again.'
		pause
	fi
	"${EDITOR}" cnf/rsc-caps/slice-individual.slice cnf/rsc-caps/slice-shared.conf cnf/rsc-caps/limits.slice
done)
#
# Edit/validify limits.conf
until [[ "${pass}" == true ]]; do
	"${EDITOR}" cnf/rsc-caps/limits.conf
	while read -r 'field[0]' 'field[1]' 'field[2]' 'field[3]' 'field[4]'; do
		# Validate the identifier field
		if [[ "${field[0]}" =~ ^@[0-9]+(:[0-9]+)?$ || "${field[0]}" =~ ^[0-9]+(:[0-9]+)?$ || "${field[0]}" == '*' ]]; then :
		elif [[ "${field[0]}" =~ ^[@%]([a-zA-Z_-.]{1,32})$ ]] && getent group "${BASH_REMATCH[1]}" &>/dev/null; then :
		elif [[ "${field[0]}" =~ ^([a-zA-Z_-.]{1,32})$ ]] && getent passwd "${BASH_REMATCH[1]}" &>/dev/null; then :
		else
			pass=false
			break
		fi
	done < <(grep -Ev '^\s*(#|$)' cnf/rsc-caps/limits.conf)
	if [[ "${pass}" == false ]]; then
		log w 'There was a syntax error in your limits.conf.'
		pause
	else
		pass=true
	fi
done





#
# Installation
#
# Install the restrictions
install -m 640 -o 0 -g 0 cnf/rsc-caps/slice-individual.slice /etc/systemd/system/user.slice.d/override.conf
install -m 640 -o 0 -g 0 cnf/rsc-caps/slice-shared.slice /etc/systemd/system/user-.slice.d/override.conf
install -m 644 -o 0 -g 0 cnf/rsc-caps/limits.conf /etc/security/limits.conf
install -m 644 -o 0 -g 0 cnf/profile.d/secure-env.sh /etc/profile.d/secure-env.sh
#
# Reload SystemD
systemctl daemon-reload