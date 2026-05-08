#!/usr/bin/env bash
install -m 640 -o root -g root -D general-confs/kernel.conf /etc/sysctl.d/99-security.conf
sysctl -f /etc/sysctl.d/99-security.conf

install -m 640 -o root -g root -D general-confs/kernel-no-ipv6.conf /etc/sysctl.d/99-disable-ipv6.conf
sysctl -f /etc/sysctl.d/99-disable-ipv6.conf
sysctl --system