translate() {
wget -qO- "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&q=$1&langpair=${2:-en}|${3:-ru}" | sed -E -n 's/[[:alnum:]": {}]+"translatedText":"([^"]+)".*/\1/p';
echo ''
return 0;
}
alias gs='git status '
alias ga='git add '
alias gb='git branch '
alias gc='git commit'
alias gd='git diff'
alias go='git checkout '
alias gk='gitk --all&'
alias gx='gitx --all'

alias got='git '
alias get='git '

alias sd='sudo'
alias ag='apt-get'
alias agu='apt-get update'
alias agd='apt-get dist-upgrade'
alias ac='apt-cache'
alias acs='apt-cache search'

alias rd='rdesktop -k en-us -g 1200x900 -u Administrator $@ > /dev/null 2>&1'
alias gw_rd='ssh -f gw.loc -L 3389:192.168.22.101:3389 -N'
alias gw_sql='ssh -f gw.loc -L 1433:192.168.22.101:1433 -N'
alias gw_tr='ssh -f gw.loc -L 9091:localhost:9091 -N'

