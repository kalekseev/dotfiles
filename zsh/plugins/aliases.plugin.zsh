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

