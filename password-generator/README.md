# Password Generator

A very customizable & automatible password generator

Missing CLI arguments will be prompted for interactively if possible
Pre-determined defaults will substitute invalid arguments

## Opts

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

## Demonstration

The below command:

```bash
./passwd-gen.sh -s '-|-' -m 1 -M 5 -c yes -a 2 -p wnsnw
```

Will generate the following output:

```txt
Generated password(s):
Rip1-|-1Dozen
Fotos6-|-0Clara
```

## Miscellaneous Notes

The script may be used in tandem with other scripts with less friction as the "Generated password(s):" text is printed to stderr.