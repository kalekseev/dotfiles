#!/usr/bin/env bash
# see more here https://github.com/mathiasbynens/dotfiles/blob/master/.macos
defaults write com.apple.screencapture name "screenshot"
defaults write com.apple.screencapture include-date -bool true;
killall SystemUIServer

sudo tee /Library/LaunchDaemons/limit.maxfiles.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>limit.maxfiles</string>
    <key>ProgramArguments</key>
    <array>
      <string>launchctl</string>
      <string>limit</string>
      <string>maxfiles</string>
      <string>64000</string>
      <string>200000</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>ServiceIPC</key>
    <false/>
  </dict>
</plist>
EOF
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist

sudo tee /Library/LaunchDaemons/limit.maxproc.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
      <string>limit.maxproc</string>
    <key>ProgramArguments</key>
      <array>
        <string>launchctl</string>
        <string>limit</string>
        <string>maxproc</string>
        <string>2048</string>
        <string>2048</string>
      </array>
    <key>RunAtLoad</key>
      <true/>
    <key>ServiceIPC</key>
      <false/>
  </dict>
</plist>
EOF
sudo chown root:wheel /Library/LaunchDaemons/limit.maxproc.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist
