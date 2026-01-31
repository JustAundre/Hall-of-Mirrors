# Hall of Mirrors

A tarpit for remote attackers, so that you may kick them off faster.

## Manual Installation

**PLEASE** review and edit `main/bullsh`, `main/hatch` and `main/seshlogger` to your needs.

Install `main/bullsh` to `/etc/bullsh` on your system
```bash
sudo install -m 644 -o root -g root ./main/bullsh /etc/bullsh
```

Install `main/hatch` to `/usr/local/bin/hatch`
```bash
sudo install -m 644 -o root -g root ./main/hatch /etc/hatch
```

Make a softlink **FROM** `/usr/bin/rbash` **TO** `/usr/bin/bash`
```bash
sudo ln -s /usr/bin/bash /usr/bin/rbash
```

Make a softlink **FROM** `/usr/bin/freedom` **TO** `/usr/bin/bash`
```bash
sudo ln -s /usr/bin/bash /usr/bin/freedom
```

Add the `ForceCommand /usr/bin/rbash` directive to `/etc/ssh/sshd_config`
```bash
sudo printf "\n#Drop everyone into a restricted shell by default\nForceCommand /usr/bin/rbash" >>/etc/ssh/sshd_config
```

Add the `. /etc/bullsh` directive to `/etc/bashrc` AND/OR `/etc/bash.bashrc` (depending on your flavor of Linux).
```bash
sudo printf "\n. /etc/bullsh" >> /etc/bashrc
# OR
sudo printf "\n. /etc/bullsh" >> /etc/bash.bashrc
```

Append `main/seshlogger` to `/etc/profile`
```bash
sudo cat ./main/seshlogger >> /etc/profile
```

## Features

**ILL-ADVISED TO ATTEMPT TO DO ANYTHING INSIDE OF BULLSH; MAY YIELD UNDESIRABLE BEHAVIOR**
**ONLY RUN COMMANDS IN BULLSH TO TEST ITS FUNCTIONALITY AND REPORT BUGS**

1. Attempting to delete files will silently fail but simulate fake disk latency.
2. Attempting to clear your command history will instead back up your history and not clear it.
3. Attempting to remotely login to another server using the compromised server will warn blue team, wait a randomly decided amount of time and then give a fake error
4. Attempting to switch to another user will give you a fake root shell
5. Attempting to run a command with `sudo` will pause your terminal for 3 seconds and then give a fake error about how you're not permitted to run commands with root
6. Attempting to change passwords for any user will pause you for a randomly decided amount of time and then not do anything
7. Attempting to list the files in your location will always return a permission error
8. Attempting to read the contents of a file into your terminal will always return a permission error
9. Attempting to check the type of a command will always say the command is a builtin command of the shell flavor you're using
10. Attempting to see which file you're executing when you enter a specific word will always say that command doesnt exist anywhere
11. Attempting to bypass functions and aliases using the shell builtin command; "command" will fail with a permission error
12. Attempting to unset the functions silently fails
13. Attempting to redefine the functions silently fails
14. Attempting to enumerate/list your environment variables and functions silently fails
15. Attempting to start a new shell silently fails
16. Attempting to use absolute file paths to specify the command you want to run with perfect percision is blocked
17. Attempting to change directories (`cd`) is blocked
18. Attempting to bypass the absolute file path block is patched
19. Attempting to start a new shell without all of the above using the 1 bypass mercilfuly provided by the setup requires a password.
20. Certain commands will be logged and an alert will be issued to sysadmins with the following information
	* Current user
	* Initial user
	* IP address
	* Terminal session
	* Full attempted command
21. The sysadmins will be shown the past 4 alerts upon logging in
22. All sessions are silently logged the second they're opened (including `stderr` along with `stdout`)
23. Trying to run the ZSH shell instead redirects to the fake root terminal

**Default Password:** `0hMyL0()rDGETM3OUT.PLE@S3`

## Roadmap

Mask the `set` command
Mask the `grep` command
Mask the `find` command
Mask the `vim`/`vi` commands
Mask the `systemctl` command