# Hall of Mirrors

[ Active Development Warning -- Unstable ]

BullSH, the **b**ull**s**h..eet **s**hell for SSH.
When passwords are dumpster fire; BullSH is here to save the day!
Now it's 1 *bad* password and 3 multi-factor authentication passwords with complexity of *your* choosing.

## Requirements

The target system for the installation must have/use...
- `Bash` 5.0+
- `Python` 3.0+
- `SystemD`
- `printf` and `tee`
- `gcc`
- `GNU` coreutils
- `SSH` server (duh)

Additionally, please note that this is only as effective as the system is secure; servers get hit by the weakest link more often than not.

## Manual Installation

Clone the repository & cd into the repository
```bash
git clone https://github.com/JustAundre/Hall-of-Mirrors.git
cd ./Hall-of-Mirrors
```

PLEASE review, configure and edit `./main/bull.sh`, `./main/chaos-chaos.c` and `./main/securecloak.sh` to suit your needs best--**recompile `./main/chaos-chaos.so` as needed.**

Create the log file(s)
Install `./main/bull.sh` to `/opt/bull.sh`
Install `./main/securecloak.sh` to `/opt/securecloak.sh`
Install `./main/chaos-chaos.so` to `/opt/chaos-chaos.so`
Add the `ForceCommand /opt/bull.sh` directive to `/etc/ssh/sshd_config`
```bash
sudo install -m 766 -o root -g root /dev/null /var/tmp/install.log
sudo chattr +a /var/tmp/install.log

sudo install -m 766 -o root -g root /dev/null /var/tmp/packages.log
sudo chattr +a /var/tmp/packages.log

sudo install -m 755 -o root -g root ./main/bull.sh /opt/bull.sh

sudo install -m 755 -o root -g root ./main/securecloak.sh /opt/securecloak.sh

sudo install -m 744 -o root -g root ./main/chaos-chaos.so /opt/chaos-chaos.so

sudo tee -a /etc/ssh/sshd_config <<EOF
# Drop everyone into BullSH
ForceCommand /opt/bull.sh
EOF
```

Append the below to the end of `/etc/ssh/sshd_config`, where SYS_ADMIN_USER is the user you would like to exclude; repeat as necessary (or don't, if you don't wish to exclude anyone.)
```bash
Match User SYS_ADMIN_USER
    ForceCommand none
```

Restart SSHD to apply changes
```bash
sudo systemctl restart ssh || sudo systemctl restart sshd || sudo service ssh restart
```

If you *don't* want to use the decoy filesystem redirection, make sure to disable it in the `bull.sh` configuration.

Otherwise, go ahead and grab a decoy root filesystem of your choice, configure it and deploy it to `/opt/bsfs`.

My choice is the Alpine Linux Mini-Root FS.
```bash
sudo mkdir -p /opt/bsfs
wget https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-minirootfs-3.19.1-x86_64.tar.gz
tar -xvf alpine-minirootfs-3.19.1-x86_64.tar.gz -C /opt/bsfs
rm alpine-minirootfs-3.19.1-x86_64.tar.gz
```

## Features

1. Fake root terminal, realistic errors and psycological torture!
2. Send attackers using suspicious/flagged credentials to a decoy filesystem
3. Logging galore; everything from individual commands, failed MFA attempts, *successful* MFA attempts, whole terminal sessions (including in the decoy filesystem)
- User IP
- Username
- UID
- EUID
- Source TTY
- Attempted input (when applicable)
- MFA Layer (when applicable)
4. Logs are duplicated and sent to a file
5. Self-expandable--if you *really* need more than 3 MFA passwords for some reason
6. Highly configurable, customizable and optimized.

`journalctl -t sshd-internal -fp5`	to view successful MFA attempts
`journalctl -t sshd-internal -fp4`	to view failed ones
`journalctl -t sshd-internal -fp3`	to view risky commands ran in a real shell
`journalctl -t sshd-internal -f`	to view all of the above at once
`journalctl -t sshd-all -f` 		to view all commands ran in a real shell
`/var/tmp/`							Location of backup log files
`less -R [LOG FILE PATH]`			to view log text file logs (to render control characters correctly)

Default Password(s):

L1: `*hMyL0(o)r`

L2: `DGE3TM3oOU`

L3: `T.PLE@$3!?`

## Roadmap

1. Deal with "$SSH_ORIGINAL_COMMAND"
- Make a special warning for it.

## Self-compiling (Encouraged)

Compile `chaos-chaos.so` with the below
`gcc -fPIC -shared -o ./main/chaos-chaos.so ./main/chaos-chaos.c -ldl`

## Changing the Password

Note: the default [hashing rounds](https://www.reddit.com/r/linuxquestions/comments/yvf994/what_is_meant_by_rounds_in_regards_to_secure/?rdt=60089) for BullSH is 2500

First, get the password you want to change to in plaintext. Hash your password into [SHA512](https://qr.ae/pCmBQJ) (with the hashing rounds accounted for.)

Go into `main/bull.sh` and change the `passHash` variable(s) to your new hash 

[ it is advised you move the default password hashes to the fake hashes after installing your new hashes. ]

Refer to the Compiling guide and then the Installation guide.
