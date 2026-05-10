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
# TUI FirewallD
#
# Confirmation
hash firewall-cmd && confirm 'Configure FirewallD /w TUI' && until [[ -n "${exit}" ]]; do
	# Get persistence state
	persistences=(
		'On-disk'
		'In-memory'
		'On-disk & in-memory'
	)
	if hash firewall-cmd; then persistence="$(checklist 'Where should this rule go?' radiolist "${persistences[@]}")"
	else persistence='On-disk & in-memory'
	fi
	#
	# Check for the exit signal
	[[ -n "${exit}" ]] && continue
	#
	# Gather the IP version, source/destination IPs and ports, the protocol, and the action.
	# (Subshell for variable clearing again.)
	(
		[[ "${persistence,,}" =~ 'on-disk' ]] && firewall_cmd_args+=('--permanent')
		echo 'Start typing to edit. Backspace to delete, [ENTER] for next field.'
		input=(
			'ipv4' # IP version
			'192.168.1.255' # Source IP
			'3000' # Source port
			'127.0.0.0/8' # Destination IP
			'6000' # Destination port
			'tcp' # Protocol
			'drop' # Action
		)
		target=0
		while true; do
			# Show the composition of the rule live
			clear
			rich_rule=$'--add-rich-rule=\''
			[[ -n "${input[0]}" ]] && rich_rule+="rule family=\"${input[0]}\" "
			[[ -n "${input[1]}" ]] && rich_rule+="source address=\"${input[1]}\" "
			[[ -n "${input[2]}" ]] && rich_rule+="source-port port=\"${input[2]}\" "
			[[ -n "${input[3]}" ]] && rich_rule+="destination address=\"${input[3]}\" "
			[[ -n "${input[4]}" ]] && rich_rule+="port port=\"${input[4]}\" "
			[[ -n "${input[5]}" ]] && rich_rule+="protocol=\"${input[5]}\" "
			[[ -n "${input[6]}" ]] && rich_rule+="${input[6]}"
			rich_rule+=\'
			echo "${rich_rule}"
			for x in "${!input[@]}"; do
				# Print current working field in emboldened green
				[[ "${x}" -eq "${target}" ]] && echo -e "\e[1;32m> ${input["${x}"]}\e[0m"
			done
			#
			# Read input character by character
			# Backspace works as backspace.
			# Change fields with [ENTER].
			IFS= read -rn1 char
			if [[ "${char}" == $'\x7f' || "${char}" == $'\b' ]]; then input["${target}"]="${input[${target}]%?}"
			elif [[ -z "${char}" ]]; then (( target++ ))
			else input["${target}"]+="${char}"
			fi
			#
			# Exit once all fields are filled
			[[ "${target}" -ge "${#input[@]}" ]] && break
		done
		firewall_cmd_args+=("${rich_rule}")
		echo "firewall-cmd ${firewall_cmd_args[*]}"
		confirm 'Is this correct' || exit 255
		firewall-cmd "${firewall_cmd_args[@]}"
		[[ "${persistence,,}" =~ 'in-memory' && "${persistence,,}" =~ 'on-disk' ]] && firewall-cmd --reload
	)
	#
	# Is it time to exit?
	confirm 'Make another rule' || break
done




#
# Exit
#
# Display success message and exit.
success