#!/usr/bin/env bash
### Runs updates, flags risky packages, and baselines/audits SystemD services.
#
# Software Updates
#
# Run updates for all major package distrobuters.
apt-get update
apt-get full-upgrade --no-install-recommends -y
hash flatpak && flatpak update -y
hash snap && snap refresh





#
# Service Audit
#
# Baseline /etc/systemd/system/ from /lib/systemd/system/
log i 'Baselining "/etc/systemd/system/" from "/lib/systemd/system/"...'
while read -r svc_path; do
	# Handle symlinks
	if [[ -h "${svc_path}" ]]; then
		# Handle broken symlinks
		[[ ! -e "${svc_path}" ]] && confirm "${svc_path} is a broken symlink. Remove" && unlink "${svc_path}"
		#
		# Checks if a service is a symlink to a file in...
		# .../lib/systemd/system/ or /usr/lib/systemd/system/.
		real_path="$(readlink "${svc_path}")"
		if [[
			"${real_path}" == /lib/systemd/system/* ||
			"${real_path}" == /usr/lib/systemd/system/*
		]]; then
			# Generally most services fall under the above condition.
			log i "${svc_path} is likely a vendor provided service that has been enabled."
		elif [[ "${real_path}" == /dev/null ]]; then
			log i "${svc_path} is a masked service pointing to /dev/null."
		else
			# Never actually seen this happen,
			# which makes it all the more suspicious if it does occur.
			if confirm "Unusual symlink; ${svc_path} points to ${real_path}. Review"; then
				"${EDITOR}" "${real_path}"
				confirm "Delete the symlink pointing from ${svc_path} to ${real_path}" && unlink "${svc_path}"
				confirm "Delete the source file @ ${real_path}" && rm -vi "${real_path}"
			fi
		fi
	#
	# Handle directories
	# Delete the directory if it is empty.
	elif [[ -d "${svc_path}" ]]; then
		if [[ "${svc_path}" == *.d ]]; then log i "${svc_path} is just an overrides directory."
		else confirm "${svc_path} doesn't end in .d; review its contents" && find "${svc_path}" -type f -exec "${EDITOR}" {} \; -exec rm -vi {} \;
		fi
		[[ -z "$(find "${svc_path}" -mindepth 1)" ]] && rm -vdi "${svc_path}"
	#
	# Prompt to audit files
	# If yes; audit files, then ask whether to delete the file.
	elif [[ -f "${svc_path}" ]] && confirm "${svc_path} is a real file located in /etc/systemd/system/—may be a custom service. Review"; then
		"${EDITOR}" "${svc_path}"
		rm -vi "${svc_path}"
	fi
done < <(find /etc/systemd/system -maxdepth 1 -mindepth 1)
#
# Enumerate services
# Check for services to remove
mapfile -t services < <(TERM=dumb systemctl list-unit-files --type=service --no-legend --plain | awk '{ print $1 }')
mapfile -t flagged_services < <(checklist 'Select services to REMOVE' checklist "${services[@]}")
#
# Remove selected services
for flagged_service in "${flagged_services[@]}"; do
	# Attempt to remove package behind service
	# Will just decommission service file if cannot locate resposible package.
	apt-get remove --purge -y "$(dpkg -S "/etc/systemd/system/${flagged_service}.service" | cut -d: -f1)" ||
	decommission "${flagged_service}"
done
#
# Audit /etc/init.d/
[[ -d /etc/init.d/ ]] &&
	confirm 'It is concerning that /etc/init.d/ is present. Review its contents' &&
	find /etc/init.d/ -type f -exec "${EDITOR}" {} \; -exec rm -vi {} \;
[[ -z "$(find /etc/init.d/ -type f)" ]] && confirm '/etc/init.d/ is now empty. Remove it' && rm -vdi /etc/init.d/
#
# Reload SystemD
systemctl daemon-reload