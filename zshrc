############################################################
#options
############################################################
#changing directories
setopt autocd
setopt autopushd
setopt cdablevars
setopt pushdignoredups
#comletition
setopt completeinword
#expansion and globbing
setopt extendedglob
setopt no_nomatch
#history
setopt extended_history
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_verify
#initialization
#input/output
#job control
setopt notify
setopt no_hup
#prompting
setopt prompt_subst
#scripting and functions
#shell emulation
#shell state
#zle
setopt no_beep
setopt emacs
############################################################
#end options
############################################################
# history
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall

autoload -Uz compinit
compinit
# End of lines added by compinstall
#


#bindings
#ctr+[left|right] arrow
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word
#bindkey "^[[1;5C" emacs-forward-word
#bindkey "^[[1;5D" emacs-backward-word
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search


for config_file (~/dotfiles/zsh/lib/*.zsh) source $config_file
source ~/dotfiles/zsh/aliases
source ~/dotfiles/zsh/robbyrussell.zsh-theme

export PATH=~/dotfiles/bin:/usr/local/heroku/bin:/usr/local/cuda/bin:$PATH:~/.local/bin
export ZSH=~/.cache/zsh

function new-github() {
  git remote add origin git@github.com:rambominator/$1.git
  git push origin master
  git config branch.master.remote origin
  git config branch.master.merge refs/heads/master
  git config push.default current
}

# specific settings for my laptop
if [ $HOST = thin ]; then
  alias rds='rdesktop -k en-us -g 1000x700 -u Administrator $@ > /dev/null 2>&1'
fi

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
PATH=$PATH:$HOME/.rvm/bin

[[ -s "/etc/bash_completion.d/virtualenvwrapper" ]] && source "/etc/bash_completion.d/virtualenvwrapper"
