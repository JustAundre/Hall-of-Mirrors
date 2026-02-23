# General Configurations

A place for general secure configuration templates to go

## Installation

CD into the general configurations directory
```bash
cd ./Hall-of-Mirrors/main/general-conf
```

Tight enough to stop your system from crashing, loose enough to for medium loads.
Don't be caught with your pants down by a `:(){ :|:& };:`...
Install `./limits.conf` to `/etc/security/limits.conf`
```bash
sudo install -m 644 -o root -g root ./limits.conf /etc/security/limits.conf
```

Restricting certain configurations of a shell usually should be fine; even for admins.
Install `./secure-env.sh` to `/etc/profile.d/secure-env.sh`
```bash
sudo install -m 733 -o root -g root ./secure-env.sh /etc/profile.d/secure-env.sh
```

Fail2Ban's real nice; you don't want a million bruteforce attacks against your SSH port.
Install `./jail.local` to `/etc/fail2ban/jail.local`
- Dependencies: SSH, Fail2Ban and FirewallD.
```bash
sudo install -m 600 -o root -g root ./jail.local /etc/fail2ban/jail.local
```