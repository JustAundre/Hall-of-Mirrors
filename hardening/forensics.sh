#!/usr/bin/env bash
#
# Environment Setup
#
# Source secure environment
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
#
# Packages used to build wpscan (wordpress-scan)
wpscan_deps=(
	ruby-full
	build-essential
	libcurl4-openssl-dev
)





#
# Questionaire
#
# Define the audits available
available_audits=(
	'Wordpress vulnerability scan'
	'Enumerate ports in use'
	'pam_exec.so usages'
	'World-writable scan'
	'World-readable scan'
	'SUID scan'
	'SGID scan'
	'Media file scan (home directories)'
	'ClamAV scan'
	'chkrootkit scan'
	'DebSums integrity check'
	'dpkg-query binary check'
	'Lynis scan'
)
#
# Ask what scans to run
mapfile -t selected_audits < <(checklist 'Select scans to perform' checklist "${available_audits[@]}")
#
# Associative array to act on selections
declare -A audit_lookup
for audit in "${selected_audits[@]}"
do
	audit_lookup["${audit}"]=y
done
#
#
[[ -n "${audit_lookup["${available_audits[0]}"]}" ]] &&
	while
		[[ ! "${port}" =~ ${num_chk} ]]
	do
		read -rp 'Which port is the webserver with Wordpress on? (port number only): ' port
	done





#
# Scanning
#
# Wordpress Scanning
[[ -n "${audit_lookup["${available_audits[0]}"]}" ]] && (
	set -e
	#
	# Install make dependencies
	secure_install "${wpscan_deps[@]}"
	#
	# Build wpscan
	gem install wpscan
	#
	# Remove make dependencies
	apt-get autoremove --purge -y "${wpscan_deps[@]}"
	#
	# Run the scan (in the bg)
	wpscan --url "http://127.0.0.1:${port}" --enumerate p &>"wordpress-vulns-${i}.log"
) &
#
# Log open ports (in the bg)
[[ -n "${audit_lookup["${available_audits[1]}"]}" ]] && (
	ss -tulpn |
		grep -vE '^127.' &>"open-ports-${i}.log"
) &
#
# Scan for Malicious PAM Hooks (in the bg)
[[ -n "${audit_lookup["${available_audits[2]}"]}" ]] && (
	grep -r pam_exec.so /etc/pam.d/ &>"possible-pam-hooks-${i}.log"
) &
#
# Scan for world-writable files/directories
# (Excluding the temporary data directories)
# (in the bg)
[[ -n "${audit_lookup["${available_audits[3]}"]}" ]] && (
	find / -xdev ! -type l -perm -o+w -not -path /tmp -not -path /var/tmp -not -path /dev/shm &>"world-writables-${i}.log"
) &
#
# Scan for world-readable files/directories
# (Excluding the temporary data directories)
# (in the bg)
[[ -n "${audit_lookup["${available_audits[4]}"]}" ]] && (
	find / -xdev ! -type l -perm -o+r -not -path /tmp -not -path /var/tmp -not -path /dev/shm &>"world-readables-${i}.log"
) &
#
# Scan for SUID binaries (in the bg)
[[ -n "${audit_lookup["${available_audits[5]}"]}" ]] && (
	find / -xdev -type f -perm -4000 &>"suid-binaries-${i}.log"
) &
#
# Scan for SGID binaries (in the bg)
[[ -n "${audit_lookup["${available_audits[6]}"]}" ]] && (
	find / -xdev -type f -perm -2000 &>"sgid-binaries-${i}.log"
) &
#
# Scan for media files in home directories (in the bg)
[[ -n "${audit_lookup["${available_audits[7]}"]}" ]] && (
	find /home -xdev -type f -exec file --mime-type {} + |
		grep -iE '(audio|video|image)/' &>"media-files-${i}.log"
) &
#
# ClamAV malware scan (in the bg)
[[ -n "${audit_lookup["${available_audits[8]}"]}" ]] && (
	set -e
	secure_install clamav clamav-daemon clamdscan
	systemctl unmask clamav-daemon
	systemctl enable --now clamav-daemon
	clamdscan / --multiscan --fdpass --exclude-dir=/sys --exclude-dir=/proc --exclude-dir=/dev -i &>"clamscan-audit-${i}.log"
	systemctl disable --now clamav-daemon
) &
#
# Chkrootkit rootkit scan (in the bg)
[[ -n "${audit_lookup["${available_audits[9]}"]}" ]] && (
	set -e
	secure_install chkrootkit
	chkrootkit &>"chkrootkit-audit-${i}.log"
) &
#
# DebSums binary integrity check (in the bg)
[[ -n "${audit_lookup["${available_audits[10]}"]}" ]] && (
	set -e
	secure_install debsums
	debsums -s &>"integrity-fails-${i}.log"
) &
#
# Finds unidentified binaries
# by querying for its corresponding package.
# (no corresponding package = foreign binary)
# (in the bg)
[[ -n "${audit_lookup["${available_audits[11]}"]}" ]] && (
	for binary in "${binaries[@]}"
	do
		[[ -f "${binary}" ]] &&
			dpkg-query -S "${binary}" ||
			echo "${binary}" &>"foreign-binaries-${i}.log"
	done
) &
#
# Lynis audit (in the background)
[[ -n "${audit_lookup["${available_audits[12]}"]}" ]] && (
	set -e
	secure_install lynis
	lynis audit system &>"lynis-audit-${i}.log"
) &





#
# Exit
#
# Wait for all children to exit
echo 'i: Started all audits, this may take a while depending on your selections...'
wait
#
# Exit & print success banner
# and the logs from this session.
success