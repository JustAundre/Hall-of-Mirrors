#!/usr/bin/env bash
#
# Environment Setup
#
# File name/location of dictionary file
dict_location="$(find /usr/share/dict -type f,l -readable | head -n1)"
dict_url='https://www.mit.edu/~ecprice/wordlist.10000'
#
# Duplicate stderr from FD 2 to FD 3, FD 3 will be used as "stdver" (standard verbose)
exec 3>&2
#
# Duplicate stderr from FD 2 to FD 4, FD 4 will be used as "stdwrn" (standard warning)
exec 4>&2
#
# Helper function to pull a random word
word_pull() {
	# Pull a word within length constraints
	local word kill
	while [[
			${#word} -lt "$min" ||
				${#word} -gt "$max"
		]]; do
		#
		# Verbose output: print scrapped words
		if [[
				-n "$verbose" &&
				-n "$word"
			]];
		then
			echo "i: Hit an unfit word '$word'" >&3
		fi
		#
		# Error out if failed to find a word matching set constraints for more than 250 cycles
		if [[ "$kill" -gt 250 ]]; then
			echo 'E: Script took too long to find a word within constraints, stopping to avoid system stress...' >&4
			return 4
		fi
		#
		# Shuffle the dictionary & pull 1 word
		word="$(shuf -n1 $dict_location)"
		if [[ -z "$word" ]]; then
			echo 'E: Failed to fetch word from the dictionary.' >&4
			return 2
		fi
		#
		# Increase cycle count
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
while getopts 's:m:M:c:a:p:hv' flag; do
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
		v)
			verbose='y'
		;;
		h|*)
			cat >&4 <<-'EOF'
				You're looking at: The Help Menu
				Either you used a non-existent option or asked to be directed here by way of -h.

				About:
				    A very customizable & automatible password generator
				
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

				    -v: Requires NO argument
				        Displays verbose output

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
	esac
done





#
# Generation Tuning
#
# Prompts for tuning
if [[
		-z "$separator" &&
		-t 0
	]];
then
	read -erp 'Enter a separator (Default is -): ' separator >&4
fi
if [[
		-z "$min" &&
		-t 0
	]];
then
	read -erp 'Minimum word length (Default is 4): ' min >&4
fi
if [[
		-z "$max" &&
		-t 0
	]];
then
	read -erp 'Max word length (Default is 8): ' max >&4
fi
if [[
		-z "$capitals" &&
		-t 0
	]];
then
	read -erp 'Capitalize first letters? [Y/n]: ' capitals >&4
fi
if [[
		-z "$password_amount" &&
		-t 0
	]];
then
	read -erp 'Amount of passwords (Default is 1): ' password_amount >&4
fi
if [[
		-z "$pattern" &&
		-t 0
	]];
then
	cat >&4 <<-'EOF'
		w = Random word
		n = Random number
		s = Provided separator
	EOF
	read -erp 'Enter your generation pattern (Default is wnswnswn): ' pattern >&4
fi
#
# Validate inputs
if [[ -z "$separator" ]]; then
	echo 'i: No separator given; defaulting to a hyphen (-)' >&4
	separator='-'
fi
if [[ ! "$min" =~ ^[0-9]+$ ]]; then
	echo 'i: Invalid/missing minimum length; defaulting to 4.' >&4
	min=4
fi
if [[ ! "$max" =~ ^[0-9]+$ ]]; then
	echo 'i: Invalid/missing maximum length; defaulting to 8.' >&4
	max=8
fi
if (( "$min" > "$max" )); then
	cat >&4 <<-EOF
		W: Minimum ($min) is greater than maximum ($max) is an unfufilable condition;
		i: Swapping the values of min/max from $min/$max to $max/$min to fix contradiction & proceeding...
	EOF
	read max min <<< "$(echo $min $max)"
fi
capitals="${capitals:0:1}"
if [[ ! "$capitals" =~ ^[yYnN]$ ]]; then
	echo 'i: Invalid/missing response; defaulting to [Y]es.' >&4
	capitals='Y'
fi
if [[ -z "$pattern" ]]; then
	echo 'i: Invalid/missing response; defaulting to wnswnswn.' >&4
	pattern='wnswnswn'
fi
if [[ "$password_amount" -lt 1 ]]; then
	echo 'i: Invalid/missing response; defaulting to 1.' >&4
	password_amount=1
fi





#
# Password generation
#
# If no dictionary is present...
if [[
		! -f "$dict_location" &&
		! -f 'en_US-dict.txt'
	]];
then
	# Attempt to download one (with consent)...
	echo "W: A pre-existing dictionary couldn't be located in '$dict_location'."
	dict_location='en_US-dict.txt'
	#
	# if there's a terminal.
	if [[ -t 0 ]]; then
		read -erp "Download a dictionary from '$dict_url' to '$(pwd)/$dict_location? (aprox. ~76kb of characters, 10k words) [y/N]: '" download >&4
	else
		cat >&4 <<-'EOF'
			E: As this is non-interactive,
			    a prompt won't be shown for downloading an external dictionary,
			    the dictionary won't be downloaded
			    & the script will now close.
		EOF
		exit 4
	fi
	#
	# Start the download (if consented)
	if [[ "$download" =~ ^[yY] ]]; then
		echo 'i: Downloading...' >&4
		#
		# Will timeout if download takes too long.
		if ! curl -s "$dict_url" --connect-timeout 5 > "$dict_location"; then
			# Alert user of the error
			cat >&4 <<-'EOF'
				E: Failed to download dictionary;
				    deleting possible remnant file(s) & quitting...
			EOF
			#
			# Remove remnant empty file
			[[ -f "$dict_location" ]] &&
				rm "$dict_location"
			exit 1
		fi
	fi
fi
#
# Generate password(s)
echo 'Generated password(s):' >&4
for (( x=0; x < password_amount; x++ )); do
	result=
	for (( y=0; y < ${#pattern}; y++ )); do
		char="${pattern:$y:1}"
		case "$char" in
			w|W)
				# Parse w/W into a random word
				word=$(word_pull) ||
					exit "$?"
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
				echo "W: Unrecognized character '$char' in pattern at line 1, column $y. Ignoring..." >&4
			;;
		esac
	done
	#
	# Return password
	echo "$result"
done