# Hall of Mirrors

BullSH, the BullShit Shell for SSH.

## Requirements

The target system for the installation must...
- Be Linux (*not MacOS*)
- Have the standard filesystem structure
- Be using `SSH` as the main access point
- Have the basic calculator (`bc`) binary installed

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

**PLEASE** review and edit `main/bull.sh`, `main/chaos-chaos.c` and `main/securecloak.sh` to your needs.

Create the warning log
```bash
sudo install -m 766 -o root -g root /dev/null /var/tmp/install.log
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

Add the `ForceCommand /usr/bin/bull.sh` directive to `/etc/ssh/sshd_config`
```bash
printf "\n# Drop everyone into BullSH by default\nForceCommand /opt/bull.sh" | sudo tee -a /etc/ssh/sshd_config
```

Append the below to the end of each Sysadmin's `~/.bashrc` file.
```bash
export $(sed -n 's/declare -r //; /^PKGLOG=/p' /opt/bull.sh)
tail -fn4 "$PKGLOG" &
printf "Heya, BullSH is installed--you're now getting alerts for possible intrusions;\nYou may manually check the full log of likely intrusions by reading the log file below:\n$PKGLOG\n"
```

## Features

1. Attempting to do enter anything that ISN'T the password is met with a no permission error from "*Bash*"
2. After dropping into the real shell, you cannot `exit` back into BullSH.
3. All sessions after escaping BullSH are logged (including `stderr`/`stdout` along with commands ran)
4. Every wrong escape attempt in BullSH also issues a warning
5. After escaping, some commands will instead issue an alert to sysadmins with
* The username
* The IP address
* The full attempted input
6. The sysadmins will be shown the past 4 alerts upon logging in

Default Password: 
`0hMyL0()rDGETM3OUT.PLE@S3`

## Self-compiling (Encouraged)

Compiling `chaos-chaos.so`
```bash
gcc -fPIC -shared -o ./main/chaos-chaos.so ./main/chaos-chaos.c -ldl
```

## Changing the Password

First, get the password you want to change to in plaintext. Hash your ideal plaintext password into [SHA512](https://qr.ae/pCmBQJ)<br>

(Preferably using the [sha512sum](https://www.computerhope.com/unix/sha512sum.htm) command)

Note: the default [hashing rounds](https://www.reddit.com/r/linuxquestions/comments/yvf994/what_is_meant_by_rounds_in_regards_to_secure/?rdt=60089) for BullSH is 250

Go into `main/bull.sh` and change the `passHash` variable to your new hash<br>


Refer to the Compiling guide and then the Installation guide.