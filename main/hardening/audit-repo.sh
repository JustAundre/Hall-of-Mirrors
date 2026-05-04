#!/usr/bin/env bash
#
# Environment Setup
#
cd "$(dirname "${BASH_SOURCE[0]}")"
. .allrc
#
# Regex to isolate uncommented URLs
url_chk='^[^#]*https?://'
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
# Exp. Warning
cat <<-'EOF'
	## ! ### ! ### ! ### ! ### ! ##
	         Experimental
	      May contain issues
	## ! ### ! ### ! ### ! ### ! ##
EOF
pause
#
# Loop over all repository files
while read -r repo_file; do
	# Loop over every line in every repository file
	while read -r line; do
		# For each line, check for a URL
		[[ "${line}" =~ (https?://[^/ ]+) ]]
		repo_url="${BASH_REMATCH[1]}"
		#
		# Compare the domains of the newly found URL with the URL from the /etc/os-release file.
		# If the domains match, just log it.
		(
		if domain_compare "${repo_url}" "${os_info[HOME_URL]}"; then
			echo "i: URL '${repo_url}' was identified."
		#
		# If they don't match and the "newly found URL" actually exists, flag it.
		elif [[ -n "${repo_url}" ]]; then
			echo "W: URL with foreign domain '${repo_url}' found in ${repo_file}."
			confirm 'Audit the file containing the foreign URL' &&
				"${EDITOR}" "${repo_file}" &&
				rm -vi "${repo_file}"
		fi
		) | tee -a "flagged-pkg-repos-${i}.log"
	done < <(grep -E "${url_chk}" "${repo_file}")
done < <(
	find /etc/yum.repos.d/ -mindepth 1 ! -type d
	find /etc/apt/sources.list.d/ -mindepth 1 ! -type d
	echo /etc/apt/sources.list
)