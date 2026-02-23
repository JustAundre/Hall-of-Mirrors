# Session Logging

Persistent, secure and readable full session logs; because logs aren't any good if you can bypass them, can change them, can't read them or don't get the full picture.

## Dependencies

Must have/use the below:
- SSH

## Installation

Automatible installation
```bash
# CD into the session-logging directory
cd ./Hall-of-Mirrors/main/session-logging

# Install the logging directory
sudo mkdir -p /var/log/sessions
sudo chown root:root /var/log/sessions
sudo chmod 000 /var/log/sessions

# Install ./logger.sh to /opt/logger.sh
sudo install -m 755 -o root -g root ./logger.sh /opt/logger.sh
sudo tee -a /etc/sudoers << 'EOF'
ALL	ALL=(ALL)	SETENV: NOPASSWD: /opt/logger.sh
EOF

# Allow passing of necessary variables through sudo
sudo tee -a /etc/sudoers << 'EOF'
Defaults	env_keep += "SSH_CLIENT SSH_CONNECTION SSH_TTY SSH_ORIGINAL_COMMAND"
EOF

# Install the log-locker service
sudo install -m 600 -o root -g root ./log-locker/log-locker.service /etc/systemd/system/log-locker.service
sudo install -m 600 -o root -g root ./log-locker/log-locker.timer /etc/systemd/system/log-locker.path
sudo install -m 700 -o root -g root ./log-locker/log-locker.sh /opt/log-locker.sh
sudo systemctl enable --now log-locker.path

# Install the hist-locker service
sudo install -m 600 -o root -g root ./hist-locker/hist-locker.service /etc/systemd/system/hist-locker.service
sudo install -m 600 -o root -g root ./hist-locker/hist-locker.timer /etc/systemd/system/hist-locker.timer
sudo install -m 700 -o root -g root ./hist-locker/hist-locker.sh /opt/hist-locker.sh
sudo systemctl enable --now hist-locker.timer

# Enable the session logger
printf '\nForceCommand sudo /opt/logger.sh' | sudo tee -a /etc/ssh/sshd_config
sudo systemctl restart sshd
```

Installation step requires manual intervention.
To exclude a user, replace `PLACEHOLDER` with user you would like to exclude and run; repeat as needed if multiple users need to be excluded.
```bash
sudo tee -a /etc/ssh/sshd_config <<'EOF'
Match User PLACEHOLDER
	ForceCommand sudo /opt/logger.sh
EOF
```

## Feature Set

1. Full session logging to text files
- Includes `stdin`, `stdout` and `stderr`!
- Append-only while live
- Immutable when session closes
- Logs are done by root not the user; the user can't kill the logging
- If the logging dies, the shell dies; simple!
2. Bash history files cannot be deleted; only new entries may be added!
3. Username on the file stays consistent across commands such as `sudo -i`, `sudo su`, `sudo bash`, etc.

```bash
# Directory where all full session logs are stored
sudo ls /var/log/sessions/

# To view individual session logs
sudo less -R "[LOG FILE PATH]"

# Queue up all session logs.
sudo bash -c 'ls -1t /var/log/sessions/* | xargs less -R'

## Type `:n` to go to the next log
## Type `:p` for the previous log
## Starts at the latest log, descends to oldest.
```