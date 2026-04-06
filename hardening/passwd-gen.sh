#!/bin/bash
#
# Environment Setup
#
# File name/location of dictionary file
dict_location='en_US-dict.txt'
dict_url='https://www.mit.edu/~ecprice/wordlist.10000'
#
# Helper function to pull a random word
word_pull() {
	# Pull a word within length constraints
	local word kill
	while [[ ${#word} -lt "$min" || ${#word} -gt "$max" ]]; do
		if [[ "$kill" -gt 100 ]]; then
			# Error out if failed to find a word matching set constraints for more than 100 cycles
			echo 'E: Script took too long to find a word within constraints, stopping to avoid system stress...' >&2
			return 3
		fi
		word=$(
			if ! shuf -n1 "$dict_location"; then
				# Error out if failed to fetch a word
				echo 'E: Failed to fetch word from dictionary.' >&2
				return 2
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
	return
}
#
# Parse CLI arguments
while getopts 's:m:M:c:a:p:h' flag; do
	case "${flag}" in
		s)
			separator="${OPTARG}"
		;;
		m)
			min="${OPTARG}"
		;;
		M)
			max="${OPTARG}"
		;;
		c)
			capitals="${OPTARG}"
		;;
		a)
			password_amount="${OPTARG}"
		;;
		p)
			pattern="${OPTARG}"
		;;
		h)
			cat <<-'EOF'
				About:
				    A very customizable and automatible password generator
				
				    Missing CLI arguments will be prompted for interactively if possible
				    Pre-determined defaults will substitute invalid arguments

				Flags:
				    -s: Requires an argument (Any string)
				        Defines the separator used in password generation

				    -m: Requires an argument (Numbers only, musn't be more than argument for -M)
				        Defines the minimum amount of characters a word must contain

				    -M: Requires an argument (Numbers only, musn't be less than argument for -m)
				        Defines the maximum amount of characters a word may contain

				    -c: Requires an argument (yes/no)
				        Use of this flag enables capitalized first letters for words in password generation

				    -a: Requires an argument (Numbers only).
				        Determines the amount of passwords that will be generated with the provided pattern

				    -p: Requires an argument (Any string is technically allowed but characters other than w/W/n/N/s/S are ignored in operation)
				        Determines the arrangement of the password

				    -h: Requires NO argument
				        Displays this information screen
				
				Demonstration:
				    ./passwd-gen.sh -s '-|-' -m 1 -M 5 -c yes -a 2 -p wnsnw
					
				    Will generate something akin to:

				    Generated password(s):
				    Rip1-|-1Dozen
				    Fotos6-|-0Clara
				
				Scripter's Notes:
				    The script may be used in tandem with other scripts with-
				    less friction as the "Generated password(s):" text is-
				    printed to stderr.
			EOF
			exit 0
		;;
		*)
			echo 'W: An invalid option was ignored.' >&2
		;;
	esac
done





#
# Generation Tuning
#
# Prompts for tuning
if [[ -z "$separator" ]]; then
	read -rp 'Enter a separator (Default is -): ' separator
fi
if [[ -z "$min" ]]; then
	read -rp 'Minimum word length (Default is 4): ' min
fi
if [[ -z "$max" ]]; then
	read -rp 'Max word length (Default is 8): ' max
fi
if [[ -z "$capitals" ]]; then
	read -rp 'Capitalize first letters? [y/n] (Default is yes): ' capitals
fi
if [[ -z "$password_amount" ]]; then
	read -rp 'Amount of passwords (Default is 1): ' password_amount
fi
if [[ -z "$pattern" ]]; then
	cat <<-'EOF'
		w = Random word
		n = Random number
		s = Provided separator
	EOF
	read -rp 'Enter your generation pattern (Default is wnswnswn): ' pattern
fi
#
# Validate inputs
if [[ -z "$separator" ]]; then
	echo 'i: No separator given; defaulting to a hyphen (-)' >&2
	separator='-'
fi
if [[ ! "$min" =~ ^[0-9]+$ ]]; then
	echo 'i: Invalid/missing minimum length; defaulting to 4.' >&2
	min=4
fi
if [[ ! "$max" =~ ^[0-9]+$ ]]; then
	echo 'i: Invalid/missing maximum length; defaulting to 8.' >&2
	max=8
fi
if (( "$min" > "$max" )); then
	echo "W: Minimum ($min) is greater than maximum ($max); setting min/max to default values of 4 & 8 respectively and proceeding..." >&2
	min=4
	max=8
fi
capitals="${capitals:0:1}"
if [[ ! "$capitals" =~ ^[yYnN]$ ]]; then
	echo 'i: Invalid/missing response; defaulting to [Y]es.' >&2
	capitals='Y'
fi
if [[ -z "$pattern" ]]; then
	echo 'i: Invalid/missing response; defaulting to wnswnswn.' >&2
	pattern='wnswnswn'
fi
if [[ "$password_amount" -lt 1 ]]; then
	echo 'i: Invalid/missing response; defaulting to 1.' >&2
	password_amount=1
fi





#
# Password generation
#
# Download dictionary if not already present
if [[ ! -f "$dict_location" ]]; then
	echo "W: Dictionary does not exist. Downloading a dictionary from '$dict_url' (aprox. ~76kb of data)..." >&2
	if ! curl -s "$dict_url" --connect-timeout 5 > "$dict_location"; then
		if [[ -f "$dict_location" ]]; then
			rm "$dict_location"
		fi
		exit 1
	fi
fi
#
# Generate password(s)
echo 'Generated password(s):' >&2
for (( x=0; x < password_amount; x++ )); do
	result=
	for (( y=0; y < ${#pattern}; y++ )); do
		char="${pattern:$y:1}"
		case "$char" in
			w|W)
				# Parse w/W into a random word
				word=$(word_pull) || exit "$?"
				result+="$word"
			;;
			n|N)
				# Parse n/N into a random number [0-9]
				result+="$(( RANDOM % 10 ))"
			;;
			s|S)
				# Parse s/S into the given separator
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