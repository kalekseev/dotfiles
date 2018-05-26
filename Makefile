PHONY: all link theme package font

package:
	~/dotfiles/install/package.sh

link:
	~/dotfiles/install/link.sh

font:
	~/dotfiles/install/font.sh

all: package link font
