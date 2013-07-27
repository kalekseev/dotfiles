from invoke import run, task
import os
import sys

home = os.environ['HOME']

def cd(*args):
    os.chdir(os.path.join(*args))

@task
def updatezsh():
    url = "https://raw.github.com/robbyrussell/oh-my-zsh/master/lib/"
    cd(home, 'dotfiles/zsh/lib')
    for lib in os.listdir('.'):
        sys.stdout.write('.')
        run("wget -q -O {0} {1}{0}".format(lib, url))
    print('done!')
