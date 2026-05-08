# Hall of Mirrors

> [!CAUTION]
> This is a highly experimental and fluid project, I am ***not*** responsible for data loss.
> *Certain tools here depend on the active security of your system to be safely deployed.*

## Download

Clone the repository
```bash
git clone https://github.com/JustAundre/Hall-of-Mirrors.git
```

## Global Dependencies

Must be running `Linux`
- `MacOS` doesn't count.

Must have/use
- `GNU Coreutils`
- `inotify-tools`

Required active shell
- `Bash 5.0+`

Required in-use Init. System
- `SystemD`

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


## Next up:

1. Scripts in `hardening/service-scripts/` need serious refactoring, reorganization & rescripting.

2. I need to implement a backup system for scripts in `hardening/` which:
- Does not need to be manually hardcoded into scripts
- Is opt-in
- Has a consistent backup pattern