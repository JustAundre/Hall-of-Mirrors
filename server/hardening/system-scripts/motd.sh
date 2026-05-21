#!/usr/bin/env bash
### Pretty simple; just gives you a premade MOTD file to install.
#
# Environment Setup
#
# Primary MOTD file
motd=/etc/issue
#
# MOTD locations
motds=(
	/etc/issue.net
	/etc/motd
)





#
# Install MOTDs
#
# Install the original to "${motd}"
# (Most common MOTD location)
log i <<-EOF
	You'll be put into a text editor to review a MOTD file template."
	    Revise it as needed, then it'll be installed to the following files:
	    ${motd} ${motds[*]}
EOF
pause
install -m 640 -o 0 -g 0 -D cnf/motd/motd "${motd}"
#
# Hardlink to other likely MOTD file locations
for path in "${motds[@]}"; do link "${motd}" "${path}"; done
#
# Delete /etc/update-motd.d/?
cat <<-EOF
	Files in "/etc/update-motd.d/" may leak information;
	    Here's all the files found in the directory:
	    $(find /etc/update-motd.d/ | xargs -n1 printf '    %s\n')
EOF
confirm 'Delete /etc/update-motd.d/ and its contents' && rm -rfv /etc/update-motd.d/