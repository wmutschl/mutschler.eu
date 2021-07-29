---
title: Things to do after installing Pop!_OS 21.04 (Apps, Settings, and Tweaks)
linktitle: Pop!_OS 21.04 apps-settings-tweaks
toc: true
type: book
date: "2021-07-28T00:00:00+01:00"
draft: false

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 13
---

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

In the following I will go through my post installation steps, i.e. which settings I choose and which apps I install and use.

## Basic Steps

### Set hostname
By default my machine is called `pop-os`; hence, I rename it for better accessability on the network:
```sh
hostnamectl set-hostname precision
```

#### Change the mirror for getting updates, set locales, get rid of unnecessary languages
I am living in Germany, so I adapt my locales:
```bash
sudo sed -i 's|http://us.|http://de.|' /etc/apt/sources.list.d/system.sources
sudo locale-gen de_DE.UTF.8
sudo locale-gen en_US.UTF.8
sudo update-locale LANG=en_US.UTF-8
```
In Region Settings open "Manage Installed Languages", do not update these, but first remove the unnecessary ones. Then reopen "languages" and update these.

#### Install updates and reboot
```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sudo fwupdmgr update
flatpak update
sudo reboot now
```


#### Set Hybrid Graphics 
[Switching Graphics in Pop!_OS](https://support.system76.com/articles/graphics-switch-pop/) is easy: either use the provided extension and restart or run
```bash
sudo system76-power graphics hybrid
sudo reboot now
```

#### Get Thunderbolt Dock to work and adjust monitors
I use a Thunderbolt Dock (DELL TB16 or Anker PowerExpand Elite 13-in-1 or builtin into my LG 38 curved monitor), which is great but also a bit tricky to set up (see [Dell TB16 Archwiki](https://wiki.archlinux.org/index.php/Dell_TB16)). I noticed that sometimes I just need to plug the USB-C cable in and out a couple of times to make it work (there seems to be a loose contact). Anyways, for me the most important step is to check in "Settings-Privacy-Thunderbolt", whether the Thunderbolt dock works, so I can rearrange my monitors in "monitor settings".

#### Restore from Backup
I mount my luks encrypted backup storage drive using nautilus and use rsync to copy over my files and important configuration scripts:
```bash
export BACKUP=/media/$USER/UUIDOFBACKUPDRIVE/@home/$USER/
sudo rsync -avuP $BACKUP/Pictures ~/
sudo rsync -avuP $BACKUP/Documents ~/
sudo rsync -avuP $BACKUP/Downloads ~/
sudo rsync -avuP $BACKUP/dynare ~/
sudo rsync -avuP $BACKUP/Images ~/
sudo rsync -avuP $BACKUP/Music ~/
sudo rsync -avuP $BACKUP/Desktop ~/
sudo rsync -avuP $BACKUP/SofortUpload ~/
sudo rsync -avuP $BACKUP/Videos ~/
sudo rsync -avuP $BACKUP/Templates ~/
sudo rsync -avuP $BACKUP/Work ~/
sudo rsync -avuP $BACKUP/.config/Nextcloud ~/.config/
sudo rsync -avuP $BACKUP/.gitkraken ~/
sudo rsync -avuP $BACKUP/.gnupg ~/
sudo rsync -avuP $BACKUP/.local/share/applications ~/.local/share/
sudo rsync -avuP $BACKUP/.matlab ~/
sudo rsync -avuP $BACKUP/.ssh ~/
sudo rsync -avuP $BACKUP/.dynare ~/
sudo rsync -avuP $BACKUP/.gitconfig ~/

sudo chown -R $USER:$USER /home/$USER
```

#### Sync Firefox to access password manager
I use Firefox and like to keep my bookmarks and extensions in sync. Particularly, I use Bitwarden for all my passwords.


#### SSH keys
If I want to create a new SSH key, I run:
```bash
ssh-keygen -t rsa -b 4096 -C "willi@mutschler"
```
Otherwise, I restore my `.ssh` folder from my backup. Either way, afterwards, one needs to add the file containing your key, usually `id_rsa`, to the ssh-agent:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```
Don't forget to add your public keys to GitHub, Gitlab, Servers, etc.

### SSH keys
If I want to create a new SSH key, I run e.g.:
```sh
ssh-keygen -t ed25519 -C "popos-on-precision"
```
Usually, however, I restore my `.ssh` folder from my backup (see above). Either way, afterwards, one needs to add the file containing your key, usually `id_rsa` or `id_ed25519`, to the ssh-agent:
```sh
bash -c 'eval "$(ssh-agent -s)"' #works both on bash and fish, on fish one could also do 'eval (ssh-agent -c)'
ssh-add ~/.ssh/id_ed25519
```
Don't forget to add your public key to GitHub, Gitlab, Servers, etc.


## Security steps with Yubikey
I have two Yubikeys and use them
- as second-factor for all admin/sudo tasks
- to unlock my luks encrypted partitions
- for my private GPG key

For this I need to install several packages:
```bash
sudo apt install -y yubikey-manager yubikey-personalization # some common packages
# Insert the yubikey
ykman info # your key should be recognized
# Device type: YubiKey 5 NFC
# Serial number: 
# Firmware version: 5.1.2
# Form factor: Keychain (USB-A)
# Enabled USB interfaces: OTP+FIDO+CCID
# NFC interface is enabled.
# 
# Applications	USB    	NFC     
# OTP     	Enabled	Enabled 	
# FIDO U2F	Enabled	Enabled 	
# OpenPGP 	Enabled	Enabled 	
# PIV     	Enabled	Disabled	
# OATH    	Enabled	Enabled 	
# FIDO2   	Enabled	Enabled 	

sudo apt install -y libpam-u2f # second-factor for sudo commands
sudo apt install -y yubikey-luks  # second-factor for luks
sudo apt install -y gpg scdaemon gnupg-agent pcscd gnupg2 # stuff for GPG
```

Make sure that OpenPGP and PIV are enabled on both Yubikeys as shown above.

#### Yubikey: two-factor authentication for admin/sudo password 
Let's set up the Yubikeys as second-factor for everything related to sudo using the common-auth pam.d module:
```bash
pamu2fcfg > ~/u2f_keys # When your device begins flashing, touch the metal contact to confirm the association. You might need to insert a user pin as well
pamu2fcfg -n >> ~/u2f_keys # Do the same with your backup device
sudo mv ~/u2f_keys /etc/u2f_keys
# Make this required for common-auth
echo "auth    required                        pam_u2f.so nouserok authfile=/etc/u2f_keys cue" | sudo tee -a /etc/pam.d/common-auth
```
Before you close the terminal, open a new one and check whether you can do `sudo echo test`

#### Yubikey: two-factor authentication for luks partitions
Let's set up the Yubikeys as second-factor to unlock the luks partitions. If you have brand new keys, then create a new key on them:
```bash 
ykpersonalize -2 -ochal-resp -ochal-hmac -ohmac-lt64 -oserial-api-visible #BE CAREFUL TO NOT OVERWRITE IF YOU HAVE ALREADY DONE THIS
```
Now we can enroll both yubikeys to the luks partition:
```bash
export LUKSDRIVE=/dev/nvme0n1p4
#insert first yubikey
sudo yubikey-luks-enroll -d $LUKSDRIVE -s 7 # first yubikey
#insert second yubikey
sudo yubikey-luks-enroll -d $LUKSDRIVE -s 8 # second yubikey
export CRYPTKEY="luks,keyscript=/usr/share/yubikey-luks/ykluks-keyscript"
sudo sed -i "s|luks|$CRYPTKEY|" /etc/crypttab
cat /etc/crypttab #check whether this looks okay
sudo update-initramfs -u
```

#### Yubikey: private GPG key
Let's use the private GPG key on the Yubikey (a tutorial on how to put it there is taken from [Heise](https://www.heise.de/ratgeber/FIDO2-YubiKey-als-OpenPGP-Smartcard-einsetzen-4590032.html) or [YubiKey-Guide](https://github.com/drduh/YubiKey-Guide)). My public key is given in a file called `/home/$USER/.gnupg/public.asc`:
```bash
sudo systemctl enable pcscd
sudo systemctl start pcscd
# Insert yubikey
gpg --card-status
# If this did not find your Yubikey, then try to first reboot.
# If it still does not work, then put
# echo 'reader-port Yubico YubiKey' >> ~/.gnupg/scdaemon.conf
# reboot and try again. Make sure to enable pcscd.
cd ~/.gnupg
gpg --import public.asc #this is my public key, my private one is on my yubikey
export KEYID=91E724BF17A73F6D
gpg --edit-key $KEYID
  trust
  5
  y
  quit
echo "This is an encrypted message" | gpg --encrypt --armor --recipient $KEYID -o encrypted.txt
gpg --decrypt --armor encrypted.txt
# If this did not trigger to enter the Personal Key on your Yubikey, then try to put
# echo 'reader-port Yubico YubiKey' >> ~/.gnupg/scdaemon.conf
# reboot and try again. Make sure to enable pcscd.
```


#### Fish - A Friendly Interactive Shell
I am trying out the Fish shell, due to its [user-friendly features](https://fedoramagazine.org/fish-a-friendly-interactive-shell/), so I install it and make it my default shell:
```sh
sudo apt install -y fish util-linux-user
chsh -s /usr/bin/fish
```
You will need to log out and back in for this change to take effect. Lastly, I want to add the ~/.local/bin to my $PATH [persistently](https://github.com/fish-shell/fish-shell/issues/527) in Fish:
```sh
mkdir -p /home/$USER/.local/bin
set -Ua fish_user_paths /home/$USER/.local/bin
```
Also I make sure that it is in my $PATH also on bash:
```sh
bash -c 'echo $PATH'
#/home/$USER/.local/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin
```
If it isn't then I make the necessary changes in my `.bashrc`.


## Apps

### Snap support
Enable snap support
```bash
sudo apt install snapd
```


### System utilities

#### Caffeine
A little helper in case my laptop needs to stay up all night
```bash
sudo apt install -y caffeine
```
Run caffeine indicator.


#### Flatseal
Flatseal is a great tool to check or change the permissions of your flatpaks:
```bash
flatpak install flatseal
```

#### GParted
In case I need to adjust the partition layout:
```bash
sudo apt install -y gparted
```
Open GParted, check whether it works.


#### Gnome-tweaks
Using gnome tweaks
```bash
sudo apt install gnome-tweak-tool 
```
In Gnome Tweaks I make the following changes:

- Disable "Suspend when laptop lid is closed" in General
- Disable "Activities Overview Hot Corner" in Top Bar
- Enable "Weekday" and "Date" in "Top Bar"
- Enable Battery Percentage (also possible in Gnome Settings - Power)
- Check Autostart programs
- Put the window controls to the left and disable the minimize button


#### nautilus-admin
Right-click context menu in nautilus for admin
```bash
sudo apt install -y nautilus-admin
```


#### Virtual machines: Quickemu and other stuff
I used to set up KVM, Qemu, virt-manager and gnome-boxes as this is much faster as VirtualBox. However, I have found a much easier tool for most tasks: [Quickqemu](https://github.com/wmutschl/quickemu) which uses the snap package Qemu-virgil:
```bash
git clone https://github.com/wmutschl/quickemu ~/quickemu
sudo apt install snapd bsdgames wget
sudo snap install qemu-virgil
sudo snap connect qemu-virgil:kvm
sudo snap connect qemu-virgil:raw-usb
sudo snap connect qemu-virgil:removable-media
sudo snap connect qemu-virgil:audio-record
sudo ln -s ~/quickemu/quickemu /home/$USER/.local/bin/quickemu
# Note that I keep my virtual machines on an external SSD
```
In case I need the old stuff:
```bash
sudo apt install -y qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager libvirt-daemon ovmf gnome-boxes
sudo adduser $USER libvirt
sudo adduser $USER libvirt-qemu
# run gnome-boxes
# run libvirt add user session
# As I use btrfs I need to change compression of images to no:
sudo chattr +C ~/.local/share/gnome-boxes
sudo chattr +C ~/.local/share/libvirt
```


### Networking

#### OpenSSH Server
I sometimes access my linux machine via ssh from other machines, for this I install the OpenSSH server:
```bash
sudo apt install openssh-server
```
Then I make some changes to 
```bash
sudo nano /etc/ssh/sshd_config
```
to disable password login and to allow for X11forwarding.

#### Nextcloud
I have all my files synced to my own Nextcloud server, so I need the sync client:
```bash
sudo apt install -y nextcloud-desktop
```
Open Nextcloud and set it up. Recheck options.


#### OpenConnect and OpenVPN
```bash
sudo apt install -y openconnect network-manager-openconnect network-manager-openconnect-gnome
sudo apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
```
Go to Settings-Network-VPN and add openconnect for my university VPN and openvpn for ProtonVPN, check connections.

### Coding

#### Dynare related packages
I am a developer of [Dynare](https://www.dynare.org) and need these packages to compile it from source and run it optimally ob Ubuntu-based systems:
```bash
sudo apt install -y build-essential gfortran liboctave-dev libboost-graph-dev libgsl-dev libmatio-dev libslicot-dev libslicot-pic libsuitesparse-dev flex bison autoconf automake texlive texlive-publishers texlive-latex-extra texlive-fonts-extra texlive-latex-recommended texlive-science texlive-plain-generic lmodern python3-sphinx latexmk libjs-mathjax doxygen x13as
```

#### git related packages:
git is most important, as a GUI for it, I use GitKraken. Also to use lfs on some repositories one needs to initialize it once:
```bash
sudo apt install -y git git-lfs
git-lfs install
flatpak install -y gitkraken
```
The flatpak version of GitKraken works perfectly. Open GitKraken and set up Accounts and Settings. Note that in case of flatpak, one needs to add the following Custom Terminal Command: `flatpak-spawn --host gnome-terminal %d`. 

#### Matlab
I have a license for MATLAB, unzipping the installation files in the the home folder and running:
```bash
sudo mkdir -p /usr/local/MATLAB/R2021a
sudo chown -R $USER:$USER /usr/local/MATLAB
/home/$USER/matlab_R2021a_glnxa64/install
```
On Ubuntu based systems it is always recommended to install `matlab-support` which renames/excludes the GCC libraries that ship with MATLAB such that we can use the ones from our distro:
```bash
sudo apt install -y matlab-support
```
Run matlab and activate it. Note that there is still a [shared resources-for-x11-graphics bug](https://de.mathworks.com/matlabcentral/answers/342906-could-not-initialize-shared-resources-for-x11graphicsdevice#answer_425485?s_tid=prof_contriblnk), which can be solved by
```bash
#this solves the shared resources for x11 graphics bug
echo "-Djogl.disable.openglarbcontext=1" > /usr/local/MATLAB/R2021a/bin/glnxa64/java.opts
```
Run matlab and I change some settings to use Windows type shortcuts on the Keyboard, add `mod` and `inc` files as supported extensions, and do not use MATLAB's source control capabilities.


#### Visual Studio Code
I am in the process of transitioning all my coding to Visual Studio code:
```bash
sudo apt install -y code
```
I keep my profiles and extensions synced.

### Text-processing

#### Latex related packages
I write all my papers and presentations with Latex using Visual Studio Code as editor:
```bash
sudo apt install -y texlive texlive-font-utils texlive-pstricks-doc texlive-base texlive-formats-extra texlive-lang-german texlive-metapost texlive-publishers texlive-bibtex-extra texlive-latex-base texlive-metapost-doc texlive-publishers-doc texlive-binaries texlive-latex-base-doc texlive-science texlive-extra-utils texlive-latex-extra texlive-science-doc texlive-fonts-extra texlive-latex-extra-doc texlive-pictures texlive-xetex texlive-fonts-extra-doc texlive-latex-recommended texlive-pictures-doc texlive-fonts-recommended texlive-humanities texlive-lang-english texlive-latex-recommended-doc texlive-fonts-recommended-doc texlive-humanities-doc texlive-luatex texlive-pstricks perl-tk
```
Open texstudio and set it up.


#### Masterpdf
I have purchased a license for Master PDF in case I need advanced PDF editing tools:
```bash
flatpak install -y masterpdf
```
Open masterpdf and enter license. Also I use flatseal to give the app full access to my home folder.


### Communication

#### Mattermost
Our Dynare team communication is happening via Mattermost:
```bash
flatpak install -y mattermost-desktop
```
Open mattermost and connect to server. I find that the snap works best for me in terms of displaying the icon in the tray.

#### Skype
Skype can be installed either via snap or flatpak. I find the flatpak version works better with the system tray icons:
```bash
flatpak install -y skype
```
Open skype, log in and set up audio and video.

#### Zoom
Zoom can be installed either via snap or flatpak. I find the flatpak version works better with the system tray icons:
```bash
flatpak install -y zoom
```
Open zoom, log in and set up audio and video.


### Multimedia

#### VLC 
The best video player:
```bash
sudo apt install -y vlc
```
Open it and check whether it works.

#### Multimedia Codecs
Install and compile multimedia codecs:
```bash
sudo apt install -y libavcodec-extra libdvd-pkg; sudo dpkg-reconfigure libdvd-pkg
```

#### OBS
Install:
```bash
sudo apt install -y obs-studio
```
Open OBS and set it up, import your scenes, etc.






## Misc tweaks and settings

#### Reorder Favorites on Dock
I like to reorder the favorites on the dock and add additional ones.

#### Go through all programs
Hit <kbd>META</kbd>+<kbd>A</kbd> and go through all programs, decide whether you need them or uninstall these.


#### Bookmarks for netdrives
Using <kbd>CTRL</kbd>+<kbd>L</kbd> in nautilus, I can add some netdrives:
- university cluster `sftp://palma2c.uni-muenster.de`
- personal homepage `sftp://mutschler.eu`
and add bookmarks to these drives for easy access with nautilus.


#### History search in terminal using page up and page down
When I use bash I like this feature:
```bash
sudo nano /etc/inputrc
# Uncomment "\e[5~": history-search-backward
# Uncomment "\e[6~": history-search-forward
```

#### Go through Settings
- Turn off bluetooth
- Change wallpaper
- Select Light Theme
- Dock
  - Deactivate Extend dock to the edges of the screen
  - Dock visibility: intelligently hide
  - Show Dock on Display: All Displays
- Automatically delete recent files and trash
- Turn of screen after 15 min
- Turn on night mode
- Add online account for Nextcloud
- Deactivate system sounds, mute mic
- Turn of suspend, turn on shutdown for power button
- Turn on natural scrool for mouse touchpad
- Go through keyboard shortcuts and adapt, I also add a custom one for xkill on <kbd>CTRL</kbd>+<kbd>ALT</kbd>+<kbd>X</kbd>
- Check region and language, remove unnecessary languages, then update 
- Change clock to 24h format
