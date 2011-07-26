gdcp() {
  git diff $1 | iconv -f cp1251 -t utf8 | more
}

export PATH=$PATH:$HOME/dotfiles/bin
export HISTCONTROL=erasedups
export HISTTIMEFORMAT="%d-%m-%y %T "
export LC_CTYPE=ru_RU.UTF-8

#aliases
source $HOME/dotfiles/aliases

bindkey '5D' backward-word
bindkey '5C' forward-word
bindkey '\e.' insert-last-word


# specific settings for my laptop
if [ $HOST = thin ]; then
  alias rds='rdesktop -k en-us -g 1000x700 -u Administrator $@ > /dev/null 2>&1'
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"