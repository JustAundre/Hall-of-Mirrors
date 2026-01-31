# Hall of Mirrors

A tarpit for remote attackers, so that you may kick them off faster.

## Manual Installation

Review and edit `main/bullshell` to your needs

Install `main/bullshell` to `/etc/bullshell` on your system
```bash
sudo install -m 644 -o root -g root ./main/bullshell /etc/bullshell
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

## Automatic Install

Coming soon...

## Default Password

`0hMyL0()rDGETM3OUT.PLE@S3`