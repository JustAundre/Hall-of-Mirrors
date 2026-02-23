# General Configurations

A place for general secure configuration templates to go

## Installation

CD into the general configurations directory
```bash
cd ./Hall-of-Mirrors/main/general-conf
```

Install `./limits.conf` to `/etc/security/limits.conf`
```bash
sudo install -m 644 -o root -g root ./limits.conf /etc/security/limits.conf
```

Install `./secure-env.sh` to `/etc/profile.d/secure-env.sh`
```bash
sudo install -m 733 -o root -g root ./secure-env.sh /etc/profile.d/secure-env.sh
```

Install `./jail.local` to `/etc/fail2ban/jail.local`
- Dependencies: SSH, Fail2Ban and FirewallD.
```bash
sudo install -m 600 -o root -g root ./jail.local /etc/fail2ban/jail.local
```