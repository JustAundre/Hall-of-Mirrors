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
# (this while true; is too small to warrant indentation)
confirm 'Enter TUI firewall configuration' && until [[ -n "${exit}" ]]; do
# A way to exit the loop
trap $'
	exit=true
	echo "W: You\'ve hit [CTRL] + C or sent SIGINT; closing after this run finishes..."
' SIGINT
echo 'i: Hit [CTRL] + C/send SIGINT on your last run to exit TUI firewall configuration.'
#
# Available options:
# Persistence state
# Action types (FirewallD can block ICMP-type requests)
persistences=(
	'On-disk'
	'In-memory'
	'On-disk & in-memory'
)
directions=(
	'Incoming traffic'
	'Outgoing traffic'
)
action_types=(
	'Allow'
	'Drop'
	'Reject'
)
classes=(
	'ICMP type'
	'IP'
	'Port'
	'IP:port'
)
hash firewall-cmd && action_types+=('Disallow ICMP type')
#
# Get the persistence type of the rule
# FirewallD has options
# ...and UFW doesn't.
if hash firewall-cmd; then persistence="$(checklist 'Where should this rule go?' radiolist "${persistences[@]}")"
else persistence='On-disk & in-memory'
fi
#
# Get the direction of the rule
direction="$(checklist 'Set a rule for...' radiolist "${directions[@]}")"
#
# Get the type of the rule
action_type="$(checklist 'Do what with captured requests?' radiolist "${action_types[@]}")"
#
# Get the class of the target requests
class="$(checklist "What are we ${action_type,,}ing?" radiolist "${classes[@]}")"
#
# Check for the exit signal
[[ -n "${exit}" ]] && continue
#
# Assemble the command
if hash firewall-cmd; then
	echo "${persistence}" | grep -q 'on-disk' && args+=('--permanent')
	# WIP
	echo "${persistence}" | grep -q 'in-memory' && firewall-cmd --reload
elif hash ufw; then
	args+=('ufw')
fi
done




#
# Exit
#
# Display success message and exit.
success