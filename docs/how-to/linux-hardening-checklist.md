# Manual Auditing

## Secure Your Environment

Backslash escape, quote, or use absolute paths to binaries for important commands

Check the below paths for suspicious commands

```txt
/etc/bashrc
/etc/bash.bashrc
/etc/profile
/etc/profile.d/*
~/.bashrc
~/.bash_profile
~/.bash_logout
```

## Software Updates

Ensure your repositories are secure & untampered

Update repository cache

Upgrade packages

Upgrade snaps & flatpaks (if applicable)

Remove unpermitted software as directed by your scenario/documentation

Ensure there are no unfamiliar/unnecessary scripts being ran via crontabs, cron, or SystemD timers & services.

## Kernel Configurations

Enable `SYN cookies` to prevent a form of DoS

Log martian IPs ("*Impossible*" IPs)

Disable `IPv6` if it's not needed

Disable `IP forwarding` if it's not needed

## Authorization/Authentication Stack

Ensure `root` user is locked with no password.

Ensure users have only the neccessary permissions

Ensure users have only the neccessary groups

No UID 0 users aside from `root`.

Ensure only recognized users are on the systemctl

Ensure passwords are as documented

Ensure passwords (including MySQL/MariaDB/PostgreSQL user passwords) are secure & not in wordlists like `rockyou.txt` or can be cracked with a dictionary attack

Ensure ALL password hashes are in `/etc/shadow` & **NOT** `/etc/passwd`

### PAM

Ensure `PAM` uses proper password quality checks, (i.e. cannot reuse the past 3 passwords, has to have `x` amount of symbols/numbers/uppercases/lowercases, etc.)

Ensure `PAM` is not hooked with a malicious backdoor module / malicious `pam_exec.so` script

## `/etc/login.defs`

Set `UMASK` to `077` (`027` if `077` is too strict, & `022` if `027` is too strict).

Set `ENCRYPT_METHOD` to `YESCRYPT` (`SHA-512` if `YESCRYPT` isn't available)

## Access Control

`/boot/` is preferably mounted as read-only (AFTER YOU RUN UPDATES.)

`/usr/` is preferably is mounted as read-only (AFTER YOU RUN UPDATES.)

`/etc/shadow` & `/etc/gshadow` are `600` & owned by `0:shadow`

`/etc/passwd`, `/etc/group` & `/etc/sshd_config` are `644` & owned by `0:0`

`/etc/ssh/sshd_config.d` should be `700` & owned by `0:0`

## Firewall

Ensure it's active

Ensure outgoing packets are allowed by default

Denied by default is great but also is prone to breakage & hassle.

Ensure incoming packets are denied by default

Ensure allowed incoming/outgoing packets are whitelisted

Block ICMP pings & ICMP timestamp request & reply requests

- Do **NOT** block all ICMP requests in general; breaks basic networking.

## SSHD Configuration

Can be found @ `/etc/ssh/sshd_config`.

Disable `root` login

Disable `X11 forwarding`

In competition environments its preferable to keep `PasswordAuthentication on`, however, realistically you should use GPG keys & keep `PasswordAuthentication off`.

## WWW

Is there a password field, or a commenting function? Test it for common injection vulnerabilities

Disable PHP file parsing on your webserver if not needed

Ensure the webserver does NOT show a file tree &/or enumerate files in a directory when there no `index.html`

Ensure the webserver does not leak software versions

Ensure the webserver does not follow symlinks

Update Wordpress themes & external plugins (if applicable)

## Services

See [this page](https://docs.rockylinux.org/9/guides/security/systemd_hardening) for more information regarding SystemD unit file hardening.
