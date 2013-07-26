from invoke import run, task
import os

home = os.environ['HOME']

def cd(*args):
    os.chdir(os.path.join(*args))

@task
def updatezsh():
    url = "https://raw.github.com/robbyrussell/oh-my-zsh/master/lib/"
    libs = 'completion git termsupport spectrum theme-and-appearance'
    for lib in [x + '.zsh' for x in libs.split()]:
        cd(home, 'dotfiles/zsh/lib')
        run("wget -q -O {0} {1}{0}".format(lib, url))
    print("OK!")
