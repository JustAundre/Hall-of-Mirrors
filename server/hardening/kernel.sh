#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Active Module Management
#
# Fetch loaded kernel modules'...
while IFS= read -r mod; do
	# Descriptions
	desc="$(modinfo -d "${mod}" | tr -d '\n')"
	[[ -z "${desc}" ]] && desc='No description.'
	#
	# Dependencies
	deps="$(modinfo "${mod}" -F depends)"
	[[ "${deps}" =~ ^\w+$ ]] && deps=nothing.
	#
	# Combine.
	echo 'i: Compiling selections for a checklist...'
	readable+=("${mod}: ${desc} - Depends on ${deps}")
done < <(cat /proc/modules | grep -Eo '^[^ ]+' | sort)
#
# Prompt for ones to disable.
mapfile -t mods_disable < <(checklist 'These are active kernel modules; select those to unload and disable.' checklist "${readable[@]}" | cut -d: -f1)
#
# Unload 'em.
modprobe -r "${mods_disable[@]}"
#
# Disable 'em.
perm_fix -m 644 -o 0 -g 0 /dev/null /etc/modprobe.d/hardening.conf
for mod in "${mods_disable[@]}"; do
	echo "install ${mod} /bin/false" >>/etc/modprobe.d/hardening.conf
done





#
# Inactive Module Management
#
# Block unloaded modules from being loaded ever
confirm 'Prevent currently unused kernel modules from ever being loaded' && while IFS= read -r mod; do
	echo "install ${mod} /bin/false" >>/etc/modprobe.d/hardening.conf
done < <(find /lib/modules/"$(uname -r)" -type f -name '*.ko*' -print0 | xargs -0n1 basename | cut -d. -f1 | sort)





#
# Kernel Parameters
#
(
# Snapshot sysctl params pre-application
before="$(sysctl -a)"
#
# Load general sysctl hardening profile
# Load Anti-IPv6 sysctl profile
install -m 640 -o 0 -g 0 general-confs/kernel.conf /etc/sysctl.d/99-security.conf
install -m 640 -o 0 -g 0 general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
#
# Apply changes
sysctl --system
#
# Snapshot sysctl params post-application
after="$(sysctl -a)"
#
# Check for changes
diff -u <(echo -- "${before}") <(echo -- "${after}") && echo 'i: Your sysctl parameters already meet best practice security standards; nothing has changed.'
)





#
# Exit
#
# Print success message
echo 'i: You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'
pause
success