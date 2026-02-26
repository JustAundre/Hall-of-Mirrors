# Chaotic

Welcome to the chaotic section--security through anything but patching vulnerabilites.

## Notices

This is only as effective as the system is secure; this is a guard for the front door, which is useless if you forgot to fix that broken window.

The default hashing rounds for passwords is `2500` and you're advised ***not*** to go lower. Should you need to change it, remember to change the configured hashing rounds in `./bull.sh` otherwise you're gonna lock yourself out.

This script acts a "*Plan B*" in the event the password of a user is compromised, but doesn't mean you don't need to have good passwords (or just use GPG keys)

I'd argue one of the best strengths of this suite is the forensics and logging; although that doesn't mean anything if you don't actually see the logs.

**IMPORTANT:** Heya, you're gonna need to change some configurations in `./bull.sh` to get the most out of this suite--please review the code; I'd like to think I did good at commenting the code to make sure almost anyone and cut and chop the script to their needs.

## Dependencies

- `Bash` 5.0+
- `Python` 3.0+
- `SystemD`
- `gcc`
- `GNU` coreutils
- `SSH` server

## Installation

```bash
# CD into the the chaotic sub-project
cd ./Hall-of-Mirrors/main/chaotic

# Create the log file(s)
sudo install -m 766 -o root -g root /dev/null /var/tmp/shell.log
sudo chattr +a /var/tmp/shell.log

# Install ./bull.sh to /opt/bull.sh
sudo install -m 755 -o root -g root ./bull.sh /opt/bull.sh

# Install ./securecloak.sh to /opt/securecloak.sh
sudo install -m 755 -o root -g root ./securecloak.sh /opt/securecloak.sh

# Install ./chaos-chaos.so to /opt/chaos-chaos.so
sudo install -m 744 -o root -g root ./chaos-chaos.so /opt/chaos-chaos.so

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
journalctl -fp5t sshd-internal # View successful MFA attempts
journalctl -fp4t sshd-internal # View failed ones
journalctl -fp3t sshd-internal # View risky commands ran in a real shell
journalctl -ft bullsh-mfa # View all of the above at once
journalctl -ft bullsh-cmds # View all commands ran in a real shell

/var/tmp/ # Location of backup log files--you'll know it when you see it.
less -R "/var/tmp/*" # View log text file logs (to render control characters correctly)
```

## Compiling

Recompile `chaos-chaos.so`
```bash
gcc -fPIC -shared -o ./chaos-chaos.so ./chaos-chaos.c -ldl
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