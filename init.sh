cd ~
ln -s dotfiles/.gitignore .gitignore
ln -s dotfiles/.gitconfig .gitconfig
ln -s dotfiles/.gemrc .gemrc
echo 'source ~/dotfiles/.bashrc' >> .bashrc
ln -s ~/dotfiles/my.zsh ~/.oh-my-zsh/custom/my.zsh
