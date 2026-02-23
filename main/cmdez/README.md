# CmDEZ

Command logging and auditing via AuditD made readable.

## Dependencies

AuditD -- The logging daemon this service interprets the logs of
xxd -- To de-hexify arguments from AuditD

## Installation

```bash
# CD into the CmDEZ directory
cd ./Hall-of-Mirrors/main/cmdez

# Install the service
sudo install -m 600 -o root -g root ./cmdez.service /etc/systemd/system/log-locker.path
sudo install -m 700 -o root -g root ./cmdez.sh /opt/cmdez.sh
```

Installation step requires manual intervention.
To add tags to certain commands:
- Replace `FOO` with your arbitrary command 
- Replace `BAR` with your arbitrary identifier/tag
...and run the command.
```bash
sudo tee -a /etc/auditd/rules.d/cmdez.rules << 'EOF'
# Apply command-specific tag
-a always,exit -F arch=b64 -S execve -F exe=FOO -k BAR

EOF
```

Log all commands via AuditD
```bash
sudo tee -a /etc/auditd/rules.d/cmdez.rules << 'EOF'
# Log all commands
-a always,exit -F arch=b64 -S execve

EOF
```

Installation step requires manual intervention.
To exclude a user, replace `PLACEHOLDER` with path of command/binary you would like to exclude; repeat as needed for more multiple commands/binaries
```bash
sudo tee -a /etc/auditd/rules.d/cmdez.rules << 'EOF'
# Exclusion for all-command logging
-a never,exit -F arch=b64 -S execve -F exe=PLACEHOLDER

EOF
```

Finalize.
```bash
# Kill and restart AuditD
pgrep auditd | sudo xargs kill -9
```

## Feature Set

1. Most notably, makes AuditD logs actually human-friendly
- Oh; and it also preserves most of the nitty-gritty you need.
2. Is a SystemD service and so...
- A side-effect is that SystemD services forward to JournalCTL
- JournalCTL is often configured to forward to rsyslog
- Since the service effectively forwards to rsyslog, if you configre rsyslog to forward to a remote log server all commands ran can be logged to an external server!
3. Handles incoming logs very quickly

```bash
# View human-readable command logs
journalctl -u cmdez
```

## Roadmap

There are plans to expand to other such things that aren't command execution.
```bash
# View human-readable tagged log
journalctl -u cmdez -t '[AuditD Tag]'
```