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