#!/usr/bin/env bash
### Lets you review active kernel modules, keep unloaded kernel modules unloaded, and installs highly hardened sysctl.d profiles.
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
echo 'i: You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'





#
# Inactive Module Management
#
# Block all currently inactive modules from ever loading.
confirm 'Prevent currently unused kernel modules from ever being loaded' && while IFS= read -r mod; do
	echo "install ${mod} /bin/false" >>/etc/modprobe.d/hardening.conf
#
# uniq -u: If a line occurs more than once, all instances of that line are removed.
done < <(sort | uniq -u < <(
	# Combine results from active modules and ALL modules.
	find /lib/modules/"$(uname -r)" -type f -name '*.ko*' -print0 | xargs -0n1 basename | cut -d. -f1
	cat /proc/modules | grep -Eo '^[^ ]+'
))
echo 'i: You can find blocked kernel modules @ "/etc/modprobe.d/hardening.conf"'





#
# Kernel Parameters
#
(
# Snapshot sysctl params pre-application
before="$(sysctl -a)"
#
# Load general sysctl hardening profile
[[ -f /etc/sysctl.d/99-security.conf ]] ||
	install -m 640 -o 0 -g 0 cnf/sysctl/kernel.conf /etc/sysctl.d/99-security.conf
#
# Load Anti-IPv6 sysctl profile
[[ -f /etc/sysctl.d/99-disable-ipv6.conf ]] || confirm 'Disable IPv6 @ kernel level' &&
	install -m 640 -o 0 -g 0 cnf/sysctl/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
#
# Install service to disable mutability of kernel modules 10 seconds after boot.
confirm 'Disable the loading or unloading of kernel modules 10 seconds after boot' &&
	install -m 600 -o 0 -g 0 cnf/sysctl/immutable-modules.service /etc/systemd/system/immutable-modules.service &&
	systemctl enable --now
#
# Apply changes
sysctl --system >/dev/null
#
# Snapshot sysctl params post-application
after="$(sysctl -a)"
#
# Check for changes
diff -u <(echo -- "${before}") <(echo -- "${after}") &&
	echo 'i: Nothing has changed, meaning your sysctl is likely already sufficiently hardened.'
)