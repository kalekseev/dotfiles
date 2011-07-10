cd ~
rm -rf .gitignore
ln -s dotfiles/gitignore .gitignore
rm -rf .gitconfig
ln -s dotfiles/gitconfig .gitconfig
rm -rf .gemrc
ln -s dotfiles/gemrc .gemrc
echo 'source ~/dotfiles/bashrc' >> .bashrc
ln -s ~/dotfiles/my.zsh ~/.oh-my-zsh/custom/my.zsh
