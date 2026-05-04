#!/usr/bin/env bash
#
# Install Mini-BullSH
#
# Ask for locations to replace
echo $'(Enter nothing once you\'re done)'
echo 'Enter the absolute paths of files to replace with mini-bull.sh: '
while true; do
	read -rp '> ' path
	[[ -z "${path}" ]] && break
	staged+=("${path}")
done
#
# Install Mini-BullSH
install -o root -g root -m 755 mini-bull.sh /opt/mini-bull.sh
#
# Replace said locations
for path in "${staged[@]}"; do
	install -o root -g root -m 755 link.sh "${path}"
done