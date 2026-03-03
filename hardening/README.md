# Hardening Script(s)

Over-engineered script for securing Linux machines

## Notes

Works best on a headless Linux servers--may break casual desktop users.

## Script Execution Flow

- Run `forensics.sh`
- Review `forensic.sh`'s log file
- Run `attr-mgr.sh` (select remove mode)
- Run `general.sh`
- Run scripts inside `./service-scripts` where applicable
- Run `attr-mgr.sh` (select restore mode)
- Run `forensics.sh`
- Review `forensic.sh`'s log file (again)

## Manual Auditing

Software Updates
- Ensure your repositories are secure and untampered
- Update repository cache
- Upgrade packages
- Upgrade snaps and flatpaks (if applicable)
- Remove unpermitted software as directed by your scenario/documentation
- Ensure there are no unfamiliar/unnecessary scripts being ran via crontabs, cron, or SystemD timers and services.

Ensure your shell isn't compromised
- Backslash escape, quote, or use absolute paths to binaries for important commands
- Check the below files for suspicious commands
	- `/etc/bashrc`
	- `/etc/bash.bashrc`
	- `/etc/profile`
	- `/etc/profile.d/`*
	- `~/.bashrc`
	- `~/.bash_profile`
	- `~/.bash_logout`

Secure Kernel Configurations
- Enable `SYN cookies` to prevent a form of DoS
- Log martian IPs ("Impossible" IPs)
- Disable `IPv6` if it's not needed
- Disable `IP forwarding` if it's not needed

Check users, user groups, shells, passwords and user IDs.
- Ensure `root` user is disabled.
- Ensure users have only the neccessary permissions
- Ensure users have only the neccessary groups
- Ensure only `root` has `UID 0`
- Ensure only recognized users are on the systemctl
- Ensure passwords are as documented
- Ensure passwords (including MySQL/MariaDB/PostgreSQL user passwords) are secure and not in wordlists like `rockyou.txt` or can be cracked with a dictionary attack
- Ensure ALL password hashes are in `/etc/shadow` and **NOT** `/etc/passwd`

`/etc/login.defs` configurations
- Set `UMASK` to `077` (`027` if `077` is too strict, and `022` if `027` is too strict).
- Set `ENCRYPT_METHOD` to `YESCRYPT` (`SHA-512` if `YESCRYPT` isn't available)

Ensure all directories and files have correct permissions
- `/boot/` is preferably mounted as read-only (AFTER YOU RUN UPDATES.)
- `/usr/` is preferably is mounted as read-only (AFTER YOU RUN UPDATES.)
- `/etc/shadow` and `/etc/gshadow` are `600` and owned by `root:shadow`
- `/etc/passwd`, `/etc/group` and `/etc/sshd_config` are `644` and owned by `root:root`
- `/etc/ssh/sshd_config.d` should be `700` and owned by `root:root`

Check the firewall
- Ensure it's active
- Ensure outgoing packets are allowed by default
	- Denied by default is great but also is prone to breakage and hassle.
- Ensure incoming packets are denied by default
- Ensure allowed incoming/outgoing packets are whitelisted
- Block ICMP pings and ICMP timestamp request and reply requests
	- Do **NOT** block all ICMP requests in general; breaks basic networking.

Check `/etc/ssh/sshd_config` for secure configurations
- Disable root login
- Disable `X11 forwarding`
- In competition environments its preferable to keep `PasswordAuthentication on`, however, realistically you should use GPG keys and keep `PasswordAuthentication off`.

Web server vulnerabilities
- Is there a password field, or a commenting function? Test it for common injection vulnerabilities
- Disable PHP file parsing on your webserver if not needed
- Ensure the webserver does NOT show a file tree and/or enumerate files in a directory when there no `index.html`
- Ensure the webserver does not leak software versions
- Ensure the webserver does not follow symlinks
- Update Wordpress themes and external plugins (if applicable)

Restrict systemd service units with only the neccessary permissions
- Just apply sandboxing in general.
- See [this page](https://docs.rockylinux.org/9/guides/security/systemd_hardening) for more information

PAM configuration
- Ensure `PAM` uses proper password quality checks, (i.e. cannot reuse the past 3 passwords, has to have `x` amount of symbols/numbers/uppercases/lowercases, etc.)
- Ensure `PAM` is not hooked with a malicious module / malicious `pam_exec.so` script