#!/usr/bin/env bash
### Checks your package repositories for URLs to repositories which don't match the domain of your distribution's main page.
#
# Environment Setup
#
# Regex to isolate uncommented URLs
url_chk='https?://[^/ ]+'
#
# Function to check for URLs sharing a domain.
domain_compare() {
	# URL Simplification
	# URL to compare
	local repo_url="${1#*://}"
	repo_url="${repo_url%%/*}"
	repo_url="${repo_url%:*}"
	repo_url="${repo_url#www.}"
	#
	# URL to compare against.
	local official_url="${2#*://}"
	official_url="${official_url%%/*}"
	official_url="${official_url%:*}"
	official_url="${official_url#www.}"
	#
	# Check whether the domains match
	# official_url: the source of truth
	[[ -n "${repo_url}" && "${repo_url}" =~ ^(.+\."${official_url}"|"${official_url}")$ ]]
}





#
# Repository URL Checks
#
# Loop over all repository files
while read -r repo_file; do
	# Loop over every line URL in the repositories file
	while read -r repo_url; do
		# Compare the domains of the newly found URL with the URL from the /etc/os-release file.
		# If the domains match, just log it.
		# If they don't match and the "newly found URL" actually exists, flag it.
		if domain_compare "${repo_url}" "${os_info[HOME_URL]}"; then log i "URL \"${repo_url}\" was identified."
		elif [[ -n "${repo_url}" ]]; then log w "URL with foreign domain \"${repo_url}\" found in \"${repo_file}\"."
		fi
	done < <(grep -oE "${url_chk}" "${repo_file}" | sort -ux)
done < <(
	find /etc/yum.repos.d/ -mindepth 1 ! -type d
	find /etc/apt/sources.list.d/ -mindepth 1 ! -type d
	echo /etc/apt/sources.list
)