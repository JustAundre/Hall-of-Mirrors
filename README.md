# Hall of Mirrors

> [!IMPORTANT]
> Certain tools here depend on the active security of your system to be safely deployed.
\
> [!CAUTION]
> This is a highly experimental and fluid project, I am ***not*** responsible for data loss.
> Better pull up a zfs/btrfs/VM/Proxmox/Timeshift snapshot,
> cause if you aren't using those and trying to use hardening scripts...
> ***It's no-one's fault but your own.***

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

Basically everything here will also depend on the installation of `/server/general-conf/secure-env.sh`

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
find . -type f -name '*.sh' -exec shellcheck -x {} +
```

## Roadmap

1. Scripts in `service-scripts/` need serious refactoring, reorganization & rescripting.
