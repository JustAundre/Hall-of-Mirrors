# Hall of Mirrors

## Download

Clone the repository
```bash
git clone https://github.com/JustAundre/Hall-of-Mirrors.git
```

## Global Dependencies

Must be running Linux
- MacOS doesn't count.

Must have/use
- `GNU Coreutils`
- `inotify-tools`

Required in-use shell: `Bash 5.0+`

Required in-use Init. System: `SystemD`

Basically everything here will also depend on the installation of `main/general-conf/secure-env.sh`

## Installation

Refer to the respective `README.md`s for each of the subdirectories in this root directory.

## Repository Development

Formatting checks
- Run the below & implement formatting suggestions/fixes as needed.
```bash
shfmt -d .
```

Error & best practices checks
- Run the below & implement fixes to oversights & best practices as needed.
```bash
find . -type f -name '*.sh' |
    xargs shellcheck -x
```

## Notices

Everything here depends on the integrity of your system.

Basically everything here should be manually reviewed & configured if you want it to work your way.

Don't come to me if you lose data—not gonna do anything about it except *try* to fix the issue that caused it, you've been warned.

## Next up:

1. Scripts in `hardening/service-scripts/` need serious refactoring, reorganization and rescripting.

2. I need to implement a backup system for scripts in `hardening/` which:
- Does not need to be manually hardcoded into scripts
- Is opt-in
- Has a consistent backup pattern

## Credits

Special thanks to Benct Philip Jonsson and Albert Krewinkel for their creation of `pagebreak.lua`.