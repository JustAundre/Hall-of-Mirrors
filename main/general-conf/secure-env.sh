set +x
set -o functrace
set -o errtrace
set -o ignoreeof
set -o pipefail
shopt -s histappend

declare -rx PROMPT_COMMAND='history -a; history -w' LOG SHELLOPTS BASHOPTS SSH_CONNECTION SSH_CLIENT SSH_TTY SSH_ORIGINAL_COMMAND HOSTNAME USER LUID LOGNAME HOME HISTIGNORE='' HISTCONTROL='' HISTSIZE=10000 HISTFILESIZE=10000 HISTFILE="$HOME/.bash_history" TMOUT=90