#!/usr/bin/env bash
# shellcheck disable=SC2034
# shellcheck disable=SC2154
#
# Environment Setup
#
# CD into the script's parent directory;
# Source global functions and variables.
cd "$(dirname "${BASH_SOURCE[0]}")"
#
# Add custom commands to PATH
# Secure UMASK
declare -rx PATH="$(pwd)/lib:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin"
umask 077
#
# Find a valid file name for the log file
# Log to master a log file
session_id=1
while compgen -G "*-${session_id}.log" >/dev/null; do (( session_id++ )) done
exec &> >(tee -a "$(basename "$0")-master-${session_id}.log")
#
# Include hidden directories when globbing
# Trying to avoid errors when globbing results in nothing, & set case insensitivity for responses.
# Unset aliases & disable alias expansion
# Make a pipeline's exit code the exit code of the last failed command of the pipelines
shopt -s dotglob nullglob nocasematch
shopt -u expand_aliases
unalias -a
set -o pipefail







#
# Helper Variables
#
# Regex to compare against to verify user input is a number
num_chk='^[0-9]+$'
#
# Load the PATH variable into an array
# Load all executables in the PATH into an array
mapfile -t paths < <(printf '%s' "${PATH}" | tr ':' '\n')
mapfile -t binaries < <(find "${paths[@]}" -maxdepth 1 -type f -executable)
#
# Load all interactive users into an array
# Load all non-interactvie users into an array
# Load all users into an array
mapfile -t int_users < <(
	grep -vE '/(nologin|false|true)$' /etc/passwd |
	awk -F: '$3 >= 1000 { print $1 }'
)
mapfile -t nonint_users < <(
	grep -E '/(nologin|false|true)$' /etc/passwd |
	awk -F: '$3 < 1000 { print $1 }'
)
mapfile -t all_users < <(cut -d: -f1 </etc/passwd)
#
# Store OS details in an associative array.
declare -A os_info
while IFS=\= read -r key value; do
	value="${value%\"}"
	value="${value#\"}"
	os_info["${key}"]="${value}"
done < /etc/os-release
#
# The variable which decides what delimitates a key/value pair when using the reconfig library command.
declare -x divider=' '





#
# Environment Check
#
# Alert the user of the checks to avoid an invisible hang
echo 'Running environment checks...'
#
# Start the check
# 1. Is this running in Bash & NOT sourced?
# 2. Does this script have root permissions?
# 3. Is the active init. system SystemD?
# 4. Is the output a terminal?
if [[ -z "${BASH_SOURCE[0]}" ]]; then errors+=('Script must be ran by Bash intepreter & must NOT be sourced.')
elif [[ "${EUID}" -ne 0 ]]; then errors+=("Must run as root. Try (sudo bash $0).")
elif [[ "$(</proc/1/comm)" != systemd ]]; then errors+=('System is not using SystemD which is the only system daemon supported by this script.')
elif [[ ! -t 0 ]]; then errors+=('All scripts here require an interactive terminal.')
fi
#
# If the exit variable is set, exit.
if [[ -n "${errors[*]}" ]]; then
	for error in "${errors[@]}"; do log e "${error}"; done
	log w 'One or more startup checks failed.'
	confirm 'Continue' || exit 1
else
	log i "No errors!"
fi





#
# Discovery & Execution
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