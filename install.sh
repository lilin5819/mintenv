#!/bin/bash
# Author:lilin
# email:1657301947@qq.com
# github:https://github.com/lilin5819/mintenv

function configMirrors()
{
    sudo cp -f etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d
    sudo dpkg --add-architecture i386
    echo "update mirrors,waiting for a while......"
    sudo apt update
    sudo apt dist-upgrade
}

function installBasicTools()
{
    echo "install basic tools"
    sudo apt install vim openssh-server openssh-client git git-svn git-remote-hg subversion mercurial hgsvn \
        hgsubversion mercurial-git mercurial-server curl wget samba nfs-kernel-server xinetd tftp-hpa \
        tftpd-hpa lrzsz minicom manpages-zh firefox-locale-zh-hans expect axel dos2unix ack-grep -y
    sudo apt install silversearcher-ag  -y
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install
    sudo cp -f etc/samba/smb.conf /etc/samba/smb.conf
    sudo cp -f etc/default/tftpd-hpa /etc/default/tftpd-hpa
    sudo cp -f etc/xinetd.d/tftp /etc/xinetd.d/tftp
    sudo mkdir /opt/{smb,tftp} && sudo chmod -R 777 /opt/{smb,tftp}
    sudo systemctl enbale smbd xinetd tftpd-hpa
    sudo systemctl restart smbd xinetd tftpd-hpa
}

function installDevTools()
{
    echo "install dev libs and tools"
    sudo apt install ia32-libs libncurses5-dev gcc-multilib g++-multilib g++-5-multilib gcc-5-doc libstdc++6-5-dbg \
        kernel-package linux-source libstdc++-5-doc binutils build-essential cpio u-boot-tools kernel-common openjdk-9-jdk wireshark nmap libpcap-dev -y
    sudo apt install ctags cscope
}

function installVPN()
{
    echo "install VPN"
    sudo apt install pppoe pptpd xl2tpd -y
    wget https://raw.github.com/philpl/setup-simple-ipsec-l2tp-vpn/master/setup.sh
    sudo sh setup.sh
    sudo cp -rf etc/{ppp,pptpd.conf,xl2tpd} /etc/
    # openswan_pkg=openswan-*.tar.*
    # [ -f $openswan_pkg ] || wget https://download.openswan.org/openswan/openswan-latest.tar.gz
    # tar xf openswan-latest.tar.gz
    # cd openswan-*
    # sudo make programs uninstall
    # sudo make programs install
    # cd ..

}

function createUser()
{
    echo "create new User....................."
    user=$1
    if [[ $user = $USER || -z $user ]]; then
        echo "Stop Create User!"
        return 1
    fi
    [ -z $user ] && echo "Usage: $0 user <username>   # create a user named <username>" && exit 1
    sudo useradd -s /bin/bash -G adm,cdrom,sudo,dip,plugdev,lpadmin,vboxsf,sambashare $user
    [ -z $? ] && echo "create user failed!" && exit 1
    echo "Please input you new user passwd:"
    sudo passwd $user
    sudo cp -rf $HOME /home/$user
    sudo chown -R $user:$user /home/$user
    echo "please input you samba passwd:"
    sudo smbpasswd -a $user
    sudo systemctl restart smbd
    eval "sudo sed -i 's/.*\(-.*\)/${user}\1/g' /etc/hostname"
    echo ""
    echo "Success ! You has add a new user: $user!"
    echo "Now ,Your hostname is $user-VB,please reboot to refresh hostname!"
    echo "Then you can login and del the old user with typing this:"
    echo ""
    echo "su - $user"
    echo "cd ~/mintenv && bash install.sh deluser $USER"
    echo ""
    echo "Rebooting now ............."
    sleep 4
    sudo reboot now
}

function delUser() {
    user=$1
    if [[ $user = $USER ]]; then
        echo "You can't del youself!"
        echo "Please retry after login another account!"
        return 1
    else
        sudo userdel $user
        sudo rm -rf /home/$user
    fi

}

function installVim8() {
    echo "Installing vim8.0 from source for better features....."
    sudo apt remove vim vim-runtime vim-common -y
    sudo apt-get install libncurses5-dev libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git checkinstall -y
    if [[ -d './vim' ]]; then
        echo "You have vim src"
        cd vim
        sudo make uninstall
        make clean
        make distclean
        git reset --hard
        git pull
    else
        git clone https://github.com/vim/vim.git
        cd vim
    fi

    python2_config_dir=`sudo find /usr/lib -type d -a -regex ".*python2.7/config.*"`
    python3_config_dir=`sudo find /usr/lib -type d -a -regex ".*python3.5/config.*"`
    ./configure --with-features=huge \
        --enable-multibyte \
        --enable-rubyinterp=yes \
        --enable-pythoninterp=yes \
        --with-python-config-dir=$python2_config_dir \
        --enable-python3interp=yes \
        --with-python3-config-dir=$python3_config_dir \
        --enable-perlinterp=yes \
        --enable-luainterp=yes \
        --enable-gui=gtk2 --enable-cscope --prefix=/usr
    make VIMRUNTIMEDIR=/usr/share/vim/vim80
    [ -n $? ] && sudo make install || echo "compile vim8 failed!"
    cd ..
    echo "end install vim8"
}

function installSpacevim() {
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/liuchengxu/space-vim/master/install.sh)"
    rm ~/.spacevim && ln -s ~/mintenv/spacevim ~/.spacevim
}

function installOhmyzsh() {
    sudo apt install zsh
    sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}

function main()
{
    case $1 in
        env)
            configMirrors
            installBasicTools
            installDevTools
            #installVim8
            installVPN
            installSpacevim
        ;;
        vim8)
            installVim8
            installSpacevim
        ;;
        adduser)
            createUser $2
        ;;
        deluser)
            delUser $2
        ;;
        all)
            configMirrors
            installBasicTools
            installDevTools
            installVPN
            installVim8
            installSpacevim
            createUser $2
        ;;
        *)
            echo "Usage: $0 env                   # install develop envs"
            echo "       $0 vim8                  # install vim8 with python、python3、ruby、perl、lua support,and other features."
            echo "       $0 adduser <username>    # create a user named <username>"
            echo "       $0 deluser <username>    # del a user named <username>"
            echo "       $0 all <username>        # install with all features and create a user named <username>"
            echo "--------   powered by lilin   ----------"
            echo "fork me in github:   https://github.com/lilin5819/mintenv   ----------"
        ;;
    esac
}

main $*
