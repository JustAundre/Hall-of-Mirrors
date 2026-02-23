#!/bin/bash
for file in /var/log/sessions/*; do
	chattr -ia "$file"
	rm -f "$file"
done