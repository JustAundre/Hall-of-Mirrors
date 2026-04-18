# General Configurations

A place for general secure configuration templates to go

## Installation

CD into the general configurations sub-project
```bash
cd Hall-of-Mirrors/main/general-conf
```

Restricting certain configurations of a shell usually should be fine; even for admins.
Install `secure-env.sh` to `/etc/profile.d/secure-env.sh`
```bash
sudo install -m 755 -o root -g root secure-env.sh /etc/profile.d/secure-env.sh
```

Fail2Ban's real nice; you don't want a million bruteforce attacks against your SSH port.
Install `jail.local` to `/etc/fail2ban/jail.local`
- Dependencies: SSH, Fail2Ban & FirewallD.
```bash
sudo install -m 600 -o root -g root jail.local /etc/fail2ban/jail.local
```

## Roadmap

1. I should try to make & integrate a custom script with F2B which will flag subnets based on suspicious activity of IPs
	- A flagged subnet will **not** automatically ban the entire subnet, however...
	- A flagged subnet will have IPs originating from that subnet reduced to 1 login attempt.