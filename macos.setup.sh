#!/usr/bin/env bash
# see more here https://github.com/mathiasbynens/dotfiles/blob/master/.macos
defaults write com.apple.screencapture name "screenshot"
defaults write com.apple.screencapture include-date -bool true;
killall SystemUIServer
