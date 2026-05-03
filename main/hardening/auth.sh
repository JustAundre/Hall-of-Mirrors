#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# PAM Configuration
#
# RHEL-like distros
if hash authselect && [[
	-d /etc/authselect/ &&
	-d /usr/share/authselect/default/
]]; then
	# Configure PAM /w secure defaults enabled & further configure password QA
	authselect select sssd with-faillock with-pamaccess with-pwhistory with-pwquality with-mkhomedir with-sudo without-nullok --force
	install -m 640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
	#
	# Regenerate PAM configurations /w previous configuration
	authselect apply-changes
#
# Debian-like distros
elif
	hash pam-auth-update &&
	[[ -d /usr/share/pam-configs/ ]]
then
	# Insert password QA configuration
	install -m 640 -o root -g root -D general-confs/pwquality /usr/share/pam-configs/pwquality
	install -m 640 -o root -g root -D general-confs/pwquality.conf /etc/security/pwquality.conf
	#
	# Insert faillock configuration
	install -m 640 -o root -g root -D general-confs/faillock /usr/share/pam-configs/faillock
	install -m 640 -o root -g root -D general-confs/faillock_reset /usr/share/pam-configs/faillock_reset
	install -m 640 -o root -g root -D general-confs/faillock_notify /usr/share/pam-configs/faillock_notify
	#
	# Reject logins for users with no password
	sed -i 's/[[:space:]]*nullok//g' /usr/share/pam-configs/unix
	#
	# Update PAM configurations
	pam-auth-update --force --package
else echo 'E: Your PAM configuration setup is unsupported.'
fi
#
# Enforce password age policies (to users w/ UID 1000=<)
mapfile -t nonsys_users < <(awk -F: '$3 >= 1000 { print $1 }' /etc/passwd)
for u in "${nonsys_users[@]}"; do
	# Skips the iterated user if they're the user running the script
	# Apply the password age restrictions to the user
	# Sets the date they last changed their password to current date to avoid accidental lockouts
	[[ "${u}" != "${SUDO_USER}" ]] &&
		chage -m 7 -M 90 -W 14 "${u}" &&
		chage -d "$(date +%Y-%m-%d)" "${u}"
done





#
# Login.defs
#
# Define the settings to update
login_defs=(
	'PASS_MAX_DAYS 90'
	'PASS_MIN_DAYS 7'
	'PASS_WARN_AGE 14'
	'ENCRYPT_METHOD YESCRYPT'
	'UMASK 077'
	'CREATE_HOME yes'
	'USERGROUPS_ENAB yes'
)
#
# Apply global defaults via login.defs
for entry in "${login_def_configs[@]}"; do
	safe_add "${entry}" /etc/login.defs
done





#
# Password & Shadow Files
#
# Check for discrepencies between /etc/passwd and /etc/group.
pwck
#
# Migrate stray hashes from passwd to shadow & from group to gshadow
# The pwconv/grpconv don't say anything helpful if there's nothing wrong or if they changed something...
# ...so I had to make my own verbose output.
# (subshell to easily reset the IFS, and for variable isolation)
(
[[ -f /etc/shadow ]] && shadow_old="$(</etc/shadow)"
[[ -f /etc/gshadow ]] && gshadow_old="$(</etc/gshadow)"
pwconv
grpconv
#
# Check for differences between the old and new shadow file
# Hint: diff returns an exit code of 1 when changes are found and 2 when there's an issue, and...
# ...0 when there was no changes made, which makes things much easier here.
if [[ -z "${shadow_old}" ]]; then echo 'i: No shadow file prior to pwconv so no discrepencies to note.'
elif diff -u <(echo "${shadow_old}") /etc/shadow; then echo 'i: Nothing changed between the old /etc/shadow file.'
fi
#
# Check for differences between the old and new gshadow file
if [[ -z "${gshadow_old}" ]]; then echo 'i: No gshadow file prior to grpconv so no discrepencies to note.'
elif diff -u <(echo "${gshadow_old}") /etc/gshadow; then echo 'i: Nothing changed between the old /etc/gshadow file.'
fi
)





#
# Display Manager
#
# Disable guest and automatic logins
if [[ -f /etc/lightdm/lightdm.conf ]]; then
	safe_add 'allow-guest false' /etc/lightdm/lightdm.conf
	safe_add 'AutomaticLogin false' /etc/lightdm/lightdm.conf
fi