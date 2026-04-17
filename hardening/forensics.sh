#!/usr/bin/env bash
#
# Environment Setup
#
# Source secure environment
cd "$(dirname "${BASH_ARGV0[*]}")"
. .allrc
#
# Packages used to build wpscan (wordpress-scan)
wpscan_deps=(
	ruby-full
	build-essential
	libcurl4-openssl-dev
)
#
# Audits which can be performed
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
# Questionaire
#
# Ask what scans to run
mapfile -t selected_audits < <(checklist 'Select scans to perform' checklist "${available_audits[@]}")
#
# Associative array to act on selections
declare -A audit_lookup
for audit in "${selected_audits[@]}"; do
	audit_lookup["$audit"]=y
done
#
#
[[ -n "${audit_lookup["${available_audits[0]}"]}" ]] &&
	while [[ ! "$port" =~ $num_chk ]]; do
		read -rp 'Which port is the webserver with Wordpress on? (port number only): ' port
	done





#
# Scanning
#
# Wordpress Scanning
if [[ -n "${audit_lookup["${available_audits[0]}"]}" ]]; then
	# Install make dependencies
	(
		set -e
		secure_install "${wpscan_deps[@]}"
		#
		# Build wpscan
		gem install wpscan
		#
		# Run the scan
		wpscan --url "http://127.0.0.1:$port" --enumerate p >>"wordpress-vulns-$i.log"
	)
	#
	# Remove make dependencies
	apt-get autoremove --purge -y "${wpscan_deps[@]}"
fi
#
# Log open ports
[[ -n "${audit_lookup["${available_audits[1]}"]}" ]] &&
	ss -tulpn |
	grep 0.0.0.0 >>"open-ports-$i.log"
#
# Scan for Malicious PAM Hooks
[[ -n "${audit_lookup["${available_audits[2]}"]}" ]] &&
	grep -r pam_exec.so /etc/pam.d/ >>"possible-pam-hooks-$i.log"
#
# Scan for world-writable files/directories which lack a sticky-bit
# (Excluding the temporary data directories)
[[ -n "${audit_lookup["${available_audits[3]}"]}" ]] &&
	find / -xdev ! -type l -perm -o+w -not -path /tmp -not -path /var/tmp -not -path /dev/shm >>"world-writables-$i.log"
#
# Scan for world-readable files
[[ -n "${audit_lookup["${available_audits[4]}"]}" ]] &&
	find / -xdev ! -type l -perm -o+r -not -path /tmp -not -path /var/tmp -not -path /dev/shm >>"world-readables-$i.log"
#
# Scan for SUID binaries
[[ -n "${audit_lookup["${available_audits[5]}"]}" ]] &&
	find / -xdev -type f -perm -4000 >>"suid-binaries-$i.log"
#
# Scan for SGID binaries
[[ -n "${audit_lookup["${available_audits[6]}"]}" ]] &&
	find / -xdev -type f -perm -2000 >>"sgid-binaries-$i.log"
#
# Scan for media files in home directories
[[ -n "${audit_lookup["${available_audits[7]}"]}" ]] &&
	find /home -xdev -type f -exec file --mime-type {} + |
	grep -iE '(audio|video|image)/' >>"media-files-$i.log"
#
# ClamAV malware scan
[[ -n "${audit_lookup["${available_audits[8]}"]}" ]] && (
	set -e
	secure_install clamav clamav-daemon clamdscan
	systemctl unmask clamav-daemon
	systemctl enable --now clamav-daemon
	clamdscan / --multiscan --fdpass --exclude-dir=/sys --exclude-dir=/proc --exclude-dir=/dev -i >>"clamscan-audit-$i.log"
)
#
# Chkrootkit rootkit scan
[[ -n "${audit_lookup["${available_audits[9]}"]}" ]] && (
	set -e
	secure_install chkrootkit
	chkrootkit >>"chkrootkit-audit-$i.log"
)
#
# DebSums binary integrity check
[[ -n "${audit_lookup["${available_audits[10]}"]}" ]] && (
	set -e
	secure_install debsums
	debsums -s >>"integrity-fails-$i.log"
)
#
# Finds unidentified binaries by 
if [[ -n "${audit_lookup["${available_audits[11]}"]}" ]]; then
	for binary in "${binaries[@]}"; do
		[[ -f "$binary" ]] &&
			dpkg-query -S "$binary" ||
			echo "$binary" >>"foreign-binaries-$i.log"
	done
fi
#
# Lynis audit
[[ -n "${audit_lookup["${available_audits[12]}"]}" ]] && (
	set -e
	secure_install lynis
	lynis audit system >>"lynis-audit-$i.log"
)





#
# Exit
#
# Exit & print success banner
# and the logs from this session.
alt_exit 0