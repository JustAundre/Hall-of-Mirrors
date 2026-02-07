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
printf "\n# Drop everyone into BullSH by default\nForceCommand /opt/bull.sh" | sudo tee -a /etc/ssh/sshd_config
```

Append the below to the end of each Sysadmin's `~/.bashrc` file.
```bash
echo -e "Heya, BullSH is installed--you're now getting alerts for possible intrusions;\nYou may manually check the full log of likely intrusions by reading the log file below:\n$PKGLOG\n\nHere are the first few alerts below:"
journalctl -t sshd-internal -f &
echo -e "You can run the below command to view all recently ran comands:\njournalctl -t sshd-internal -f"
```

Append the below to the end of `/etc/ssh/sshd_config`, where SYS_ADMIN_USER is the user you would like to exclude; repeat as necessary (or not if you don't wish to exclude anyone.)
```bash
Match User SYS_ADMIN_USER
    ForceCommand none
```

## Features

1. Attempting to do enter anything that ISN'T the password is met with a no permission error from "*Bash*"
2. After dropping into the real shell, you cannot `exit` back into BullSH.
3. All sessions after escaping BullSH are logged (including `stderr`/`stdout` along with commands ran)
4. Every wrong escape attempt in BullSH also issues a warning
5. After escaping, some commands will instead issue an alert to sysadmins with
* The username
* The UID
* The IP address
* The full attempted input
6. The sysadmins will be shown the past 4 alerts upon logging in

## Roadmap

1. More gaslighting!! :3
* If input is a known bad password, exec unshare -rm --root=/path/to/fake/filesystem /usr/bin/bash (jail to fake filesystem)

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