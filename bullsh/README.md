# BullSH

## Notices

- Default hashing rounds for passwords is `2500`
- Remember to change the password hashes &/or the hashing amount to your needs.

## Dependencies

- `Python 3.0<=`
- `SSHD 4.4<=`

## Installation

Review and run `install.sh`

## Feature List

1. Fake root terminal, realistic errors & psycological torture!
2. Logs are duplicated & sent to a file
3. Self-expandable—if you *really* need more than 3 MFA passwords for some reason
4. Highly configurable, customizable & optimized.

For BullSH logs, use the below command:
```bash
journalctl -ft bullsh
```

Logs consist of:
- Failed authentications
	- Contains input & EUID for command.
- Successful authentications
- Passes onto a real shell

All logs contain:
- User IP
- Username
- User UID
- Current/new BullSH layer

BullSH session log files are in `/var/tmp/` opposed to `/var/`***`log/`*** due to security risks.

## The Password(s)

Default Password(s):

L1: `*hMyL0(o)r`

L2: `DGE3TM3oOU`

L3: `T.PLE@$3!?`

## Changing the Password(s)

First, get the password you want to change to in plaintext. Hash your password into [SHA512](https://www.quora.com/How-does-SHA-512-work/) (with the hashing rounds accounted for.)

Go into `bull.sh` & change the `hashes` variable to your new hash

## Roadmap/Notes

- There is room to add some fake success logic to redirect the attacker to a whole 'nother system entirely.