PHONY: all link theme package font

package:
	~/dotfiles/install/package.sh

theme:
	~/dotfiles/install/theme.sh

link:
	~/dotfiles/install/link.sh

font:
	~/dotfiles/install/font.sh

all: package link font theme
