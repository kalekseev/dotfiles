git_diff_head() {
    git diff HEAD~$1
}

generate_ctags() {
    local language="python"
    if [ -n "$1" ];
    then
        language="$1"
    fi
    if [ -n "$VIRTUAL_ENV" ]
    then
        ctags -a -R --languages=$language . $VIRTUAL_ENV/lib/python*
    else
        ctags -a -R --languages=$language .
    fi
}

set_django_settings_module() {
    local sdir=`find . -maxdepth 2 -mindepth 2 -type d -name settings -printf '%P'`
    if [ -e "$sdir/$1.py" ];
    then
        echo "using $sdir/$1.py as default settings"
    else
        echo "file $sdir/$1 doesn't exist"
    fi
    DJANGO_SETTINGS_PATH="`echo $sdir | tr '/' '.'`"
    export DJANGO_SETTINGS_MODULE="$DJANGO_SETTINGS_PATH.$1"
}

set_hg_prompt() {
    export PROMPT='%{$fg_bold[red]%}➜ %{$fg_bold[green]%}%p %{$fg[cyan]%}%c %{$fg_bold[blue]%}$(hg_prompt_info)%{$fg_bold[blue]%} % %{$reset_color%}'
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

explain () {
  if [ "$#" -eq 0 ]; then
    while read  -p "Command: " cmd; do
      curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$cmd"
    done
    echo "Bye!"
  elif [ "$#" -eq 1 ]; then
    curl -Gs "https://www.mankier.com/api/explain/?cols="$(tput cols) --data-urlencode "q=$1"
  else
    echo "Usage"
    echo "explain                  interactive mode."
    echo "explain 'cmd -o | ...'   one quoted command to explain it."
  fi
}
