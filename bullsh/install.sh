#!/usr/bin/env bash
#
# Install Mini-BullSH
#
# TODO: EXPAND.
# Ask for locations to replace
echo $'(Enter nothing to finish)\nEnter the absolute paths to install mini-bull.sh at: '
while true; do
	read -rp '> ' path
	[[ -z "${path}" ]] && break
	install -o 0 -g 0 -m 755 link.sh "${path}"
done