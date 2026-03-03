#!/usr/bin/env -iS /usr/bin/bash --noprofile --norc
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
		if [[ "$port" =~ $numberCheck ]]; then
			wpscan --url "http://127.0.0.1:$port" --enumerate p |
				tee -a "$log_dir/wordpress-vulns-$suffix"
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
	grep -v '127.0.0.1' |
	tee -a "$log_dir/open-ports-$suffix"
#
# Scan for Malicious PAM Hooks
grep -r pam_exec.so /etc/pam.d/ |
	tee -a "$log_dir/possible-pam-hooks-$suffix"




#
# File Permission & Content Auditing
#
# Log world-writable files and directories which lack a sticky-bit and aren't one of the 3 usual directories
if confirm 'Search for world-writable paths'; then
	find / -xdev -perm ! -type l -o+w -not -path /tmp -not -path /var/tmp -not -path /dev/shm/ |
		tee -a "$log_dir/world-writables-$suffix"
fi
#
# Log world-readable files
if confirm 'Search for world-readable paths'; then
	find / -xdev -perm ! -type l -o+r -not -path /tmp/ -not -path /var/tmp/ -not -path /dev/shm/ |
		tee -a "$log_dir/world-readables-$suffix"
fi
#
# Scan for media files in home directories
if confirm 'Search for media in home directories'; then
	find /home -xdev -type f -exec file --mime-type {} + |
		grep -iE '(audio|video|image)/' |
		tee -a "$log_dir/found-media-$suffix"
fi
#
# Log SUID binaries
if confirm 'Search for SUID binaries'; then
	find / -xdev -type f -perm -4000 -ls |
		tee -a "$log_dir/suid-binaries-$suffix"
fi
#
# Log SGID binaries
if confirm 'Scan for SGID binaries'; then
	find / -xdev -type f -perm -2000 -ls |
		tee -a "$log_dir/sgid-binaries-$suffix"
fi
#
# Scans files for keywords indicative of exfiltration or malicious intent
if confirm 'Scan for suspicious scripts'; then
	find / -xdev -type f -print0 |
		xargs -0 file |
		grep -E '(shell script|python)' |
		cut -d: -f1 |
		xargs grep -lE "$suspicious_filter" |
		tee -a "$log_dir/flagged-scripts-$suffix"
fi





#
# Filesystem Integrity Auditing
#
if confirm 'Check for unrecognized and suspicious programs and files (additional program installation may be required)';
	# ClamAV malware scan
	if confirm 'Use ClamAV to scan for viruses (CPU intensive)'; then
		(
			set -e
			secure_install clamav clamav-daemon clamdscan
			systemctl unmask clamav-daemon
			systemctl enable --now clamav-daemon
			clamdscan / --multiscan --fdpass --exclude-dir=/sys --exclude-dir=/proc --exclude-dir=/dev -il "$log_dir/clamscan-audit-$suffix"
		)
	fi
	#
	# Chkrootkit rootkit scan
	if confirm 'Search for rootkits with chkrootkit'; then
		(
			set -e
			secure_install chkrootkit
			chkrootkit |
				tee -a "$log_dir/chkrootkit-audit-$suffix"
		)
	fi
	#
	# DebSums binary integrity check
	if confirm 'Confirm the integrity of binaries using debsums'; then
		(
			set -e
			secure_install debsums
			debsums -s |
				tee -a "$log_dir/integrity-fails-$suffix"
		)
	fi
	#
	# Unidentified binary finder
	if confirm 'Search for binaries unrecognized by DPKG'; then
		(
			read -ra PATHS <<< "$(printf "$PATH" | tr ',' ' ')"
			for dir in "${PATHS[@]}"; do
				binaries=($(find "$dir" -type f -executable -exec file --mime-type {} + | grep 'application/x' | cut -d: -f1))
				for binary in "${binaries[@]}"; do
					if [[ -f "$binary" ]]; then
						dpkg-query -S "$binary" ||
							echo "$binary" >> "$log_dir/foreign-binaries-$suffix"
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
				tee -a "$log_dir/lynis-audit-$suffix"
		)
	fi
fi