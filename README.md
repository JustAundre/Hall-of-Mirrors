# Hall of Mirrors

BullSH, the BullShit Shell for SSH.

## Requirements

The target system for the installation must...
- Be Linux *(not MacOS)*
- Use `sudo` for administrative action authentication
- Have the standard filesystem structure
- Be using `SSH` as the main access point

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

**PLEASE** review and edit `main/bullsh.c`, `main/chaos-chaos.c` and `main/securecloak.sh` to your needs.

Install `main/bullsh` to `/usr/bin/bullsh`
```bash
sudo install -m 755 -o root -g root ./main/bullsh /usr/bin/bullsh
```

Install `main/chaos-chaos.so` to `/var/lib/chaos-chaos.so`
```bash
sudo install -m 644 -o root -g root ./main/chaos-chaos.so /var/lib/chaos-chaos.so
```

Install `main/securecloak.sh` to `/etc/securecloak.sh`
```bash
sudo install -m 755 -o root -g root ./main/securecloak.sh /etc/securecloak.sh
```

Add the `. /etc/securecloak.sh` directive to `/etc/bashrc` **OR** `/etc/bash.bashrc` (depending on your flavor of Linux).
```bash
printf "\n# Insert some restrictive wrappers to prevent destructive and malicious action and warn on said attempts of such actions\n. /etc/securecloak.sh 2>/dev/null" | sudo tee -a /etc/bashrc
```

Add the `ForceCommand /usr/bin/bullsh` directive to `/etc/ssh/sshd_config`
```bash
printf "\n# Drop everyone into BullSH by default\nForceCommand /usr/bin/bullsh" | sudo tee -a /etc/ssh/sshd_config
```

Append the below to the end of each Sysadmin's `~/.bashrc` file.
```bash
touch "$PKGLOG"
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

## Compiling

(I actively encourage you to compile it yourself.)

Compiling `chaos-chaos.so`
```bash
gcc -fPIC -shared -o ./main/chaos-chaos.so ./main/chaos-chaos.c -ldl
```

Compiling `bull`
```bash
gcc -o ./main/bullsh ./main/bullsh.c
```

## Changing the Password

First, get the password you want to change to in plaintext. Hash the plaintext password into SHA512<br>
(preferably using the `sha512sum` command like `printf 'PASSWORD_HERE' | sha512sum | cut -d' ' -f1`)<br>
Go into `main/hatch.c` and find the line which looks like `const char* TARGET = ...`<br>
Replace the contents of the quotation marks which may look something like `= "9ffbf43126e33be52cd2bf7as23dsf..."` with the result from the command you were previously instructed to run

Refer to the Compiling guide and then the Installation guide.