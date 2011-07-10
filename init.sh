cd ~
rm -rf .gitignore
ln -s dotfiles/gitignore .gitignore

rm -rf .gitconfig
ln -s dotfiles/gitconfig .gitconfig

rm -rf .gemrc
ln -s dotfiles/gemrc .gemrc

rm -rf .zshrc
ln -s dotfiles/zsh/zshrc .zshrc

ln -s ~/dotfiles/zsh/my.zsh ~/.oh-my-zsh/custom/my.zsh
ln -s ~/dotfiles/zsh/plugins ~/.oh-my-zsh/custom/

echo 'source ~/dotfiles/bashrc' >> .bashrc
