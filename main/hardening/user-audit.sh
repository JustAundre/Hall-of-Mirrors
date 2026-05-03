#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
#
# Prompt for users to ...
# Delete, remove password, lock, reshell, reUID & regroup.
for user in "${all_users[@]}"; do
	id -a
done
mapfile -t users_del < <(checklist 'Select users to delete' checklist "${all_users[@]}")





#
# Main Logic
#
# Delete users flagged as to be deleted
for u in "${users_del[@]}"; do userdel -rf "${u}"; done
#
# Delete passwords of users flagged to have their password removed
for u in "${users_nullpass[@]}"; do passwd "${u}" -d; done
#
# Lock users flagged to be locked
for u in "${users_lock[@]}"; do passwd "${u}" -l; done
#
# Prompt to change the shell for users flagged to be reshelled
for u in "${users_reshell[@]}"; do
	while [[ ! -x "${shell}" ]]; do read -erp 'Enter the path to the new shell: ' shell; done
	usermod -s "${shell}" "${u}"
done
#
# Prompt to change the UID of users flagged to be reUIDed
for u in "${users_reuid[@]}"; do
	while
		[[ "${uid}" =~ ^[0-9]+$ ]] &&
		grep -qE "^[^:]+:[^:]+:${uid}" /etc/passwd
	do
		read -erp 'Enter the new UID: ' uid
	done
	usermod -s "${uid}" "${u}"
done
#
# Change the primary & supplementary groups
for u in "${users_regroup[@]}"; do
	# Prompt for the new primary group
	while
		[[ -z "${primary_group}" ]] ||
		! grep -qE "^[^:]+:[^:]+:${primary_group}" /etc/group
	do
		read -erp 'Enter new primary group: ' primary_group
	done
	#
	# Prompt for the new supplementary groups
	while [[ -z "${stop}" ]]; do
		read -erp 'Enter new supplemental groups (space-separated): ' -a supplemental_groups
		stop=i
		for group in "${supplemental_groups[@]}"; do
			grep -qE "^[^:]+:[^:]+:${primary_group}" /etc/group || stop=
		done
	done
	#
	# Change the groups
	usermod -g "${primary_group}" "${u}"
	usermod -G "${supplemental_groups[*]// /,}" "${u}"
done
#
# Secures root user
# (L)ocks user (root) & (d)eletes their password
confirm 'Lock & remove password for user (root)' && passwd root -ld