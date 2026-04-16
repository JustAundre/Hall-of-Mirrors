#!/usr/bin/env bash
#
# Environment Setup
#
# Source secure environment
. .allrc
#
# The ReGex to compare against for potential suspicious scripts
suspicious_filter="\b(curl|wget|base64|chpasswd|netcat|ln|nc)\b"
#
# Packages used to build wpscan (wordpress-scan)
wpscan_deps=(
	ruby-full
	build-essential
	libcurl4-openssl-dev
)





#
# Software Vulnerabilities
#
# Wordpress Scanning
if confirm 'Is there a webserver which uses Wordpress'; then
	(
		# Install make dependencies
		set -e
		secure_install "${wpscan_deps[@]}"
		#
		# Build wpscan
		gem install wpscan
		#
		# Run the scan
		read -rp 'What port is the webserver with Wordpress on (port number only)?: ' port
		if [[ "$port" =~ $num_chk ]]; then
			wpscan --url "http://127.0.0.1:$port" --enumerate p |
				tee -a "wordpress-vulns-$suffix.log"
		fi
	)
	#
	# Remove make dependencies
	set -e
	apt-get remove --purge -y "${wpscan_deps[@]}"
	apt-get autoremove --purge
fi
#
# Log open ports
ss -tulpn |
	grep '0.0.0.0' |
	tee -a "open-ports-$suffix.log"
#
# Scan for Malicious PAM Hooks
grep -r 'pam_exec.so' /etc/pam.d/ |
	tee -a "possible-pam-hooks-$suffix.log"




#
# File Permission & Content Auditing
#
# Log world-writable files & directories which lack a sticky-bit & aren't one of the 3 usual directories
if confirm 'Search for world-writable paths'; then
	find / -xdev ! -type l -perm -o+w -not -path /tmp -not -path /var/tmp -not -path /dev/shm |
		tee -a "world-writables-$suffix.log"
fi
#
# Log world-readable files
if confirm 'Search for world-readable paths'; then
	find / -xdev ! -type l -perm -o+r -not -path /tmp/ -not -path /var/tmp -not -path /dev/shm |
		tee -a "world-readables-$suffix.log"
fi
#
# Scan for media files in home directories
if confirm 'Search for media in home directories'; then
	find /home -xdev -type f -exec file --mime-type {} + |
		grep -iE '(audio|video|image)/' |
		tee -a "found-media-$suffix.log"
fi
#
# Log SUID binaries
if confirm 'Search for SUID binaries'; then
	find / -xdev -type f -perm -4000 -ls |
		tee -a "suid-binaries-$suffix.log"
fi
#
# Log SGID binaries
if confirm 'Scan for SGID binaries'; then
	find / -xdev -type f -perm -2000 -ls |
		tee -a "sgid-binaries-$suffix.log"
fi
#
# Scans files for keywords indicative of exfiltration or malicious intent
if confirm 'Scan for suspicious scripts'; then
	find / -xdev -type f -print0 |
		xargs -0 file |
		grep -E '(shell script|python)' |
		cut -d: -f1 |
		xargs grep -lE "$suspicious_filter" |
		tee -a "flagged-scripts-$suffix.log"
fi





#
# Filesystem Integrity Auditing
#
if confirm 'Check for unrecognized/suspicious programs/files (Additional software needed)'; then
	# ClamAV malware scan
	if confirm 'Use ClamAV to scan for viruses (CPU intensive)'; then
		(
			set -e
			secure_install clamav clamav-daemon clamdscan
			systemctl unmask clamav-daemon
			systemctl enable --now clamav-daemon
			clamdscan / --multiscan --fdpass --exclude-dir=/sys --exclude-dir=/proc --exclude-dir=/dev -il "clamscan-audit-$suffix.log"
		)
	fi
	#
	# Chkrootkit rootkit scan
	if confirm 'Search for rootkits with chkrootkit'; then
		(
			set -e
			secure_install chkrootkit
			chkrootkit |
				tee -a "chkrootkit-audit-$suffix.log"
		)
	fi
	#
	# DebSums binary integrity check
	if confirm 'Confirm the integrity of binaries using debsums'; then
		(
			set -e
			secure_install debsums
			debsums -s |
				tee -a "integrity-fails-$suffix.log"
		)
	fi
	#
	# Unidentified binary finder
	if confirm 'Search for binaries unrecognized by DPKG'; then
		(
			set -e
			mapfile -t paths <(
				printf '%s' "$PATH" |
					tr ':' ' '
			)
			for dir in "${paths[@]}"; do
				mapfile -t binaries <(
					find "$dir" -type f -executable -exec file --mime-type {} + |
						grep 'application/x' |
						cut -d: -f1
				)
				for binary in "${binaries[@]}"; do
					if [[ -f "$binary" ]]; then
						dpkg-query -S "$binary" ||
							echo "$binary" >>"foreign-binaries-$suffix.log"
					fi
				done
			done
		)
	fi
	#
	# Lynis System Audit
	if confirm 'Run general-purpose hardening scan with Lynis'; then
		(
			set -e
			secure_install lynis
			lynis audit system |
				tee -a "lynis-audit-$suffix.log"
		)
	fi
fi