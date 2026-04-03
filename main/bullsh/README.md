# BullSH

Security through psychological terror.

## Notices

TLDR...
- Default hashing rounds for passwords is `2500`
- Remember to change the password hashes and/or the hashing amount to your needs.

## Dependencies

- `Python 3.0+`
- `gcc`
- `SSH` server

## Installation

```bash
# CD into the the chaotic sub-project
cd Hall-of-Mirrors/main/chaotic

# Create the log file(s)
sudo install -m 766 -o root -g root /dev/null /var/tmp/shell.log
sudo chattr +a /var/tmp/shell.log

# Install bull.sh to /opt/bull.sh
sudo install -m 755 -o root -g root bull.sh /opt/bull.sh

# Enable usage of BullSH via /etc/ssh/sshd_config ForceCommand directive
sudo tee -a /etc/ssh/sshd_config <<EOF
# Drop everyone into BullSH
ForceCommand /opt/bull.sh
EOF
```

Installation step requires manual intervention.
```bash
# To exclude a user, replace PLACEHOLDER with user you would like to exclude and run;
# ...repeat as necessary for more than 1 user.
sudo tee -a /etc/ssh/sshd_config <<EOF
Match User PLACEHOLDER
	ForceCommand none
EOF
```

Finalize.
```bash
sudo systemctl restart sshd
```

## Feature List

1. Fake root terminal, realistic errors and psycological torture!
2. Logging galore; everything from individual commands, failed MFA attempts, *successful* MFA attempts, whole terminal sessions (including in the decoy filesystem)
	- Source IP of SSH session
	- Username
	- UID
	- EUID
	- Source TTY
	- Attempted input (when applicable)
	- MFA Layer (when applicable)
3. Logs are duplicated and sent to a file
4. Self-expandable--if you *really* need more than 3 MFA passwords for some reason
5. Highly configurable, customizable and optimized.

```bash
# Commands ran while in BullSH (if unexpected commands are logged, MAKE A REPORT.)
journalctl -ft bullsh-cmds

# Authentication logs
journalctl -ft bullsh-mfa # Merged view of the below
journalctl -fp4t bullsh-mfa # Failed authentication attempts
journalctl -fp3t bullsh-mfa # Successful authentication attempts

# Duplicate copy of the above logs
less -R /var/tmp/shell.log
```

Session log files are in `/var/tmp/`, unfortunately not `/var/log/` because the script runs in the userland and making it run as root would be walking on ice you don't know the thickness of.

## Compiling

Recompile `chaos-chaos.so`
```bash
gcc -fPIC -shared -o chaos-chaos.so chaos-chaos.c -ldl
```

## The Password(s)

Default Password(s):

L1: `*hMyL0(o)r`

L2: `DGE3TM3oOU`

L3: `T.PLE@$3!?`

## Changing the Password(s)

First, get the password you want to change to in plaintext. Hash your password into [SHA512](https://qr.ae/pCmBQJ) (with the hashing rounds accounted for.)

Go into `./bull.sh` and change the `passHash` variable(s) to your new hash 

[ it is advised you move the default password hashes to the fake hashes after installing your new hashes. ]

Refer to the Compiling guide and then the Installation guide.

## Roadmap/Notes

- There is room to add some fake success logic to redirect the attacker to a whole 'nother system entirely;
	- Use SSHpass to SSH into a sacrificial server where the attacker has full reign over a little crib
	- Just gotta make sure to disable standalone outbound traffic