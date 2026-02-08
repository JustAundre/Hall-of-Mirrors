# Hall of Mirrors

BullSH, the BullShit Shell for SSH.

## Requirements

The target system for the installation must...
- Be Linux (not MacOS)
- Have...
* Bash
* BC (basic calculator)
* Python3 or above
* Use SystemD
* PrintF / Echo

Additionally, please note that this is only as effective as the system is secure;

Servers get hit by the weakest link more often than not.

## Manual Installation

To install the this, you *should* preferably have, but are allowed to not have...
- Have a shell, preferably `bash`.
- Have `gcc`
- Have `git`
- Have `tee`

Clone the repository/download its source code
```bash
git clone https://github.com/JustAundre/Hall-of-Mirrors.git
```

Change directory into the project
```bash
cd "./Hall-of-Mirrors"
```

**PLEASE** review and edit `main/bull.sh`, `main/chaos-chaos.c` and `main/securecloak.sh` to your needs; recompile as needed.

Create the warning log file
```bash
sudo install -m 766 -o root -g root /dev/null /var/tmp/install.log
sudo chattr +a /var/tmp/install.log
```

Install `main/bull.sh` to `/opt/bull.sh`
```bash
sudo install -m 755 -o root -g root ./main/bull.sh /opt/bull.sh
```

Install `main/securecloak.sh` to `/opt/securecloak.sh`
```bash
sudo install -m 755 -o root -g root ./main/securecloak.sh /opt/securecloak.sh
```

Install `main/chaos-chaos.so` to `/opt/chaos-chaos.so`
```bash
sudo install -m 744 -o root -g root ./main/chaos-chaos.so /opt/chaos-chaos.so
```

Add the `ForceCommand /opt/bull.sh` directive to `/etc/ssh/sshd_config`
```bash
echo "# Drop everyone into BullSH by default\nForceCommand /opt/bull.sh" | sudo tee -a /etc/ssh/sshd_config
```

Append the below to the end of each Sysadmin's `~/.bashrc` file.
```bash
PKGLOG=$(awk -F'"' '/PKGLOG=/ {print $2}' /opt/bull.sh)
echo "Heya, BullSH is installed--you're now getting alerts for possible intrusions."
echo "You can run the below command to view all recently failed logon attempts:"
echo "journalctl -t sshd-internal -f"
echo "Oh, also, you can find a backup log at $PKGLOG."
journalctl -t sshd-internal -f &
```

Append the below to the end of `/etc/ssh/sshd_config`, where SYS_ADMIN_USER is the user you would like to exclude; repeat as necessary (or don't, if you don't wish to exclude anyone.)
```bash
Match User SYS_ADMIN_USER
    ForceCommand none
```

## Features

1. Fake root terminal
2. Realistic errors
3. Psycological torture!
4. Even after escaping BullSH, entire sessions are logged! (including `stderr`/`stdout` along with commands ran)
5. Logging galore; failed MFA attempt? Logged! Suspicious/risky command? Logged! Successful MFA attempt? Logged--but what does the log contain?
* User IP
* User ID
* Username
* Attempted input
6. The logs go to a inconspicous log file *and* JournalCTL--should work with remote logging as well.
7. Recent alerts are displayed to sysadmins on login!

`journalctl -t sshd-internal -f -o cat` to view commands/input attempted in BullSH
`journalctl -t sshd-all -f -o cat` to view all commands ran in a real shell
`journalctl -t sshd-internal -f -p 5 -o cat` for successful MFA attempts
`journalctl -t sshd-internal -f -p 4 -o cat` for failed ones.
`journalctl -t sshd-internal -f -p 3 -o cat` for risky commands ran in a real shell
Hidden log files are located at `/var/tmp/`

## Roadmap

1. More gaslighting!! :3
* If input is a known bad password, exec unshare -rm --root=/path/to/fake/filesystem /usr/bin/bash (jail to fake filesystem)
2. Deal with "$SSH_ORIGINAL_COMMAND"
* Make a special warning for it.

Default Password: 
`0hMyL0()rDGETM3OUT.PLE@S3`

## Self-compiling (Encouraged)

Compile `chaos-chaos.so` with the below
```bash
gcc -fPIC -shared -o ./main/chaos-chaos.so ./main/chaos-chaos.c -ldl
```

## Changing the Password

Note: the default [hashing rounds](https://www.reddit.com/r/linuxquestions/comments/yvf994/what_is_meant_by_rounds_in_regards_to_secure/?rdt=60089) for BullSH is 2500

First, get the password you want to change to in plaintext. Hash your password into [SHA512](https://qr.ae/pCmBQJ) (with the hashing rounds accounted for.)

Go into `main/bull.sh` and change the `passHash` variable(s) to your new hash

Refer to the Compiling guide and then the Installation guide.