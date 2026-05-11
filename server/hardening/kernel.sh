#!/usr/bin/env bash
#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Kernel Parameters
#
# General hardening
install -m 640 -o root -g root -D general-confs/kernel.conf /etc/sysctl.d/99-security.conf
sysctl -f /etc/sysctl.d/99-security.conf
#
# Disable IPv6
install -m 640 -o root -g root -D general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
sysctl -f /etc/sysctl.d/99-disable-ipv6.conf
sysctl --system





#
# Module Management
#
# Grab loaded kernel modules
# Grab descriptions for loaded kernel modukes
# Combine both
# Prompt for ones to disable.
mapfile -t mods_id < <(cat /proc/modules | grep -Eo '^[^ ]+')
mapfile -t mods_desc < <(modinfo "${mods_id[@]}" | grep -E '^description:' | sed 's/^[^ ]* *//')
for (( x=0; x < "${#mods_id[@]}"; x++ )); do
	mods_id_desc+=("${mods_id[${x}]}: ${mods_desc[${x}]}")
done
mapfile -t mods_disable < <(checklist 'Select kernel modules to disable.' checklist "${mods_id_desc[@]}" | cut -d: -f1)