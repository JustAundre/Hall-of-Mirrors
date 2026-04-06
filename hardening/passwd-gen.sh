#!/usr/bin/env -ivS /bin/bash --noprofile --norc
#
# Environment Setup
#
# File name/location of dictionary file
dict_location='en_US-dict.txt'
dict_url='https://www.mit.edu/~ecprice/wordlist.10000'
#
# Download dictionary if not found
if [[ ! -f "$dict_location" ]]; then
	echo "W: Dictionary does not exist. Downloading a dictionary from '$dict_url'..." >&2
	if ! curl -s "$dict_url" > "$dict_location"; then
		echo 'E: Dictionary does not exist and cannot be downloaded.' >&2
		exit 1
	fi
fi
#
# Helper function to pull a random word
word_pull() {
	# Pull a word within length constraints
	local word kill
	while [[ ${#word} -lt "$min" || ${#word} -gt "$max" ]]; do
		if [[ "$kill" -gt 10 ]]; then
			echo 'E: Script took too long to find a word within constraints, quitting...' >&2
			exit 3
		fi
		word=$(
			if ! shuf -n1 "$dict_location"; then
				echo 'E: Failed to fetch word from dictionary.' >&2
				exit 2
			fi
		)
		(( kill++ ))
	done
	#
	# Capitalize beginning of word as needed, then print result.
	if [[ "$capitals" =~ ^[yY]$ ]]; then
		printf "${word^}"
	else
		printf "$word"
	fi
}





#
# Generation Tuning
#
# Prompts for tuning
read -rp 'Enter a separator (Default is -): ' separator
read -rp 'Minimum word length (Default is 4): ' min
read -rp 'Max word length (Default is 8): ' max
read -rp 'Capitalize first letters? [y/n] (Default is yes): ' capitals
read -rp 'Amount of passwords (Default is 1): ' password_amount
cat <<-'EOF'
	w = Random word
	n = Random number
	s = Provided separator
EOF
read -rp 'Enter your generation pattern (Default is wnswnswn): ' pattern
#
# Validate inputs
if [[ -z "$separator" ]]; then
	echo 'W: No separator given; defaulting to a hyphen (-)' >&2
	separator='-'
fi
if [[ ! "$min" =~ ^[0-9]+$ ]]; then
	echo 'W: Invalid minimum length; defaulting to 4.' >&2
	min=4
fi
if [[ ! "$max" =~ ^[0-9]+$ ]]; then
	echo 'W: Invalid maximum length; defaulting to 8.' >&2
	max=8
fi
if (( "$min" > "$max" )); then
	echo "W: Minimum ($min) is greater than maximum ($max); setting min/max to default values of 4 & 8 respectively and proceeding..." >&2
	min=4
	max=8
fi
capitals="${capitals:0:1}"
if [[ ! "$capitals" =~ ^[yYnN]$ ]]; then
	echo 'W: Invalid response; defaulting to [Y]es.' >&2
	capitals='Y'
fi
if [[ -z "$pattern" ]]; then
	echo 'W: Invalid pattern; defaulting to wnswnswn.' >&2
	pattern='wnswnswn'
fi
if [[ "$password_amount" -lt 1 ]]; then
	echo 'W: Invalid amount; defaulting to 1.' >&2
	password_amount=1
fi





#
# Password generation
#
echo 'Generated password(s):'
for (( x=0; x < password_amount; x++ )); do
	result=
	for (( y=0; y < ${#pattern}; y++ )); do
		char="${pattern:$y:1}"
		case "$char" in
			w|W)
				word=$(word_pull)
				result+="$word"
			;;
			n|N)
				result+="$(( RANDOM % 10 ))"
			;;
			s|S)
				result+="$separator"
			;;
			*)
				# More input validation
				echo "W: Unrecognized character '$char' in pattern at line 1, column $y. Ignoring..." >&2
			;;
		esac
	done
	#
	# Return password
	echo "$result"
done