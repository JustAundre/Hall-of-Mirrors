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
# WIP