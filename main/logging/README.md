# Logging

Persistent, secure & readable full session logs; because logs aren't any good if you can bypass them, can change them, can't read them or don't get the full picture.

## Dependencies

Must have/use the below:
- SSH

## Installation

Change directory into this directory & run the installation script
```bash
cd Hall-of-Mirrors/main/logging
./install.sh
```

## Feature Set

1. Full session logging to text files
- You see what the user sees.
- Append-only while live, immutable when done.
- Logging on the root level, user on the user level. Non-privileged users can't stop the logging.
- If the logging dies, the shell dies--simple.
2. Bash history files cannot be deleted; only new entries may be added!
3. Username on the file stays consistent, even across commands such as `sudo -i`, `sudo su` & `sudo bash`.

Use the below to queue up all logs & select ones to delete after review.

```bash
mapfile -t logs < <(ls -1t /var/log/sessions/*)

for log in "${logs[@]}"; do
	less -R "${log}" &&
		read -rp "Delete (${log})?: " del
	if [[ "${del}" =~ ^[yY] ]]; then
		chattr -ia "${log}"
		rm "${log}"
	fi
done
```

Use the below to actively monitor history files in home directories:
```bash
mapfile -t histories < <(find /home -maxdepth 2 -type f -name '*history')

for history in "${histories[@]}"; do
	printf 'Monitoring %s:\n\n' "${history}"
	tail -fn10 "${history}" &
done
```