# Logging

Persistent, secure & readable full session logs; because logs aren't any good if you can bypass them, can change them, can't read them or don't get the full picture.

## Dependencies

Must have/use the below:
- SSH

## Installation

Change directory into this directory & run the installation script
```bash
cd Hall-of-Mirrors/main/logging
./install.sh
```

## Feature Set

1. Full session logging to text files
- Includes `stdin`, `stdout` & `stderr`
- Append-only while live
- Immutable when session closes
- Logs are done by root not the user; the user can't kill the logging
- If the logging dies, the shell dies; simple!
2. Bash history files cannot be deleted; only new entries may be added!
3. Username on the file stays consistent, even across commands such as `sudo -i`, `sudo su` & `sudo bash`.

```bash
# Directory where all full session logs are stored
sudo ls /var/log/sessions/

# To view individual session logs
sudo less -R '[LOG FILE PATH]'

# Queue up all session logs.
sudo bash -c 'ls -1t /var/log/sessions/* | xargs less -R'

## Type `:n` to go to the next log
## Type `:p` for the previous log
## Starts at the latest log, descends to oldest.

# To view attempted non-interactive sessions/commands
journalctl -p3 -t logger
```

# Roadmap

Hopefully will be able to add an easy way to review logs in a way where once reviewed, do not need to review again & is moved to a different directory.