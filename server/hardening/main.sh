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





#
# Exit
#
# Fetch log files
# Clear the screen
# Print the summary
mapfile -t log_files < <(timeout 5 find . -maxdepth 1 -type f -name "*${session_id}.log")
clear
printf '%b' "$(
	cat <<-EOF
		  ---{=========}###[@]###{===========}---
		        WINDOWS AT LOSS AT THE
		           AGAPE FREEDOM OF LINUX
		  ---{=========}###[@]###{===========}---
		
		      Cybersecurity is great; though,
		    people often have their priorities
		       mixed up. Make sure you have
		        good password hygiene and
		         a good password manager.

		-----<============>{x}<============>-----

		Here are the log files from this session:
		$(if [[ -n "${log_files[*]}" ]]; then for path in "${log_files[@]}"; do echo "${path}"; done
		else log w 'No logs found.'
		fi)
	EOF
)"
exit 0