PHONY: all link theme packages font

packages:
	~/dotfiles/install/packages.sh

theme:
	~/dotfiles/install/theme.sh

link:
	~/dotfiles/install/link.sh

font:
	~/dotfiles/install/font.sh

all: packages link font theme
