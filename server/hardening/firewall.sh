#!/usr/bin/env bash
#
# Environment Setup
#
# Source helper functions & variables
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Base Ruleset
#
# Sets default rules based on the installed firewall
if hash firewall-cmd; then
	# (--permanent: Modifies on-disk configuration, not in-memory configuration.)
	# Start the firewall
	systemctl unmask firewalld
	systemctl enable --now firewalld
	#
	# Reset the firewall
	firewall-cmd --reset-to-defaults
	firewall-cmd --set-default-zone public
	#
	# Deny all incoming, allow all outgoing.
	firewall-cmd --permanent --load-zone-defaults public
	#
	# Block ICMP echo requests & timestamp requests/replies
	firewall-cmd --permanent --add-icmp-block echo-request
	firewall-cmd --permanent --add-icmp-block timestamp-reply
	firewall-cmd --permanent --add-icmp-block timestamp-request
	#
	# Push on-disk configuration into in-memory configuration
	firewall-cmd --reload
elif hash ufw; then
	# Start the firewall
	systemctl unmask ufw
	systemctl enable --now ufw
	ufw --force enable
	#
	# Reset the firewall
	ufw reset
	#
	# Deny all incoming, allow all outgoing.
	ufw default deny incoming
	ufw default allow outgoing
else
	echo 'E: This script requires either UFW or FirewallD installed.'
	exit 1
fi





#
# TUI Firewall Configuration
#
# WIP