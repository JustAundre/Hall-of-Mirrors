#!/usr/bin/env bash
trap '' SIGINT SIGTSTP
/opt/mini-bull.sh
kill -9 "${PPID}"