# Aundre's Shell Script Suite

> [!IMPORTANT]
> Certain tools here depend on the active integrity/security of your system to be confidently deployed without fail and or external manipulation.

> [!CAUTION]
> Experimental project; data loss may occur and the project owner does not claim liability in such occurances.

> [!WARNING]
> Documentation needs to be written and/or rewritten.

## Download

Clone the repository

```bash
git clone https://github.com/JustAundre/Hall-of-Mirrors.git
```

Update/download submodules

```bash
git submodule update --init --recursive
```

## Global Dependencies

Must be running *`Linux`

- *`MacOS` doesn't count.

Must have/use:

- `GNU Coreutils`
- `inotify-tools`

Required active shell

- `Bash 5.0+`

Required in-use Init. System

- `SystemD`

Basically everything here will also depend on the installation of `/server/general-conf/secure-env.sh`

## Installation

Refer to the respective `README.md`s for each of the subdirectories here for usage and installation instructions.

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

## Transparency

While AIs/LLMs were utilized in the process of making the code contained in this repository, such AI/LLMs ***did not directly write any of the code present.*** The AI/LLMs only were utilized in my learning process and were not prompted to directly provide a fix to an issue or write new functionality; only put enlighten me on why something wasn't working.
