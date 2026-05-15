#!/usr/bin/env bash
#
# Environment Setup
#
# CD into the script's parent directory;
# Source global functions and variables.
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc





#
# Discovery
#
# Locate all scripts and fetch their descriptions.
declare -A options
while read -r script; do
	options["$(basename "${script}"): $(grep '^### ' "${script}" | sed 's/### //')"]="${script}"
done < <(find . -name '*.sh' ! -name 'main.sh')
#
# List them off--select 1.
# shellcheck disable=SC1090
. "${options["$(checklist "Choose a script to run." radiolist "${!options[@]}")"]}"