.PHONY: all link theme package font zsh

package:
	~/dotfiles/install/package.sh

link:
	~/dotfiles/install/link.sh

font:
	~/dotfiles/install/font.sh

zsh:
	git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git ~/.oh-my-zsh || true
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

all: package link font
