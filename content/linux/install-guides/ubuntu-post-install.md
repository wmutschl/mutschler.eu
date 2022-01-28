---
title: 'Ubuntu Desktop: Things to do after installation (Apps, Settings, and Tweaks)'
#linktitle: Ubuntu 20.04 apps-settings-tweaks
summary: In the following I will go through my post installation steps on Ubuntu, i.e. which settings I choose and which apps I install and use.
toc: true
type: book
#date: "2020-04-24"
draft: false
weight: 13
---

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

In the following I will go through my post installation steps, i.e. which settings I choose and which apps I install and use.

## Basic Steps

#### Go through welcome screen
This is self-explanatory. Usually I already set up Online Accounts for Nextcloud.

#### Get rid of unnecessary languages
Open "language" in "region settings", do not update these, but first remove the unnecessary ones. Then reopen "languages" and update these.

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
sudo reboot now
```


#### Get Thunderbolt Dock to work and adjust monitors
I use a Thunderbolt Dock (DELL TB16) with three monitors, which is great but also a bit tricky to set up (see [Dell TB16 Archwiki](https://wiki.archlinux.org/index.php/Dell_TB16)). I noticed that sometimes I just need to plug the USB-C cable in and out a couple of times to make it work (there seems to be a loose contact). Anyways, for me the most important step is to check in "Settings-Privacy-Thunderbolt", whether the Thunderbolt dock works, so I can rearrange my three monitors in "monitor settings". I then save this as default for "gdm":
```bash
sudo cp ~/.config/monitors.xml ~gdm/.config/
```

#### Restore from Backup
I mount my luks encrypted backup storage drive using nautilus and use rsync to copy over my files and important configuration scripts:
```bash
export BACKUP=/media/$USER/UUIDOFBACKUPDRIVE/@home/$USER/
sudo rsync -avuP $BACKUP/Bilder ~/
sudo rsync -avuP $BACKUP/Dokumente ~/
sudo rsync -avuP $BACKUP/Downloads ~/
sudo rsync -avuP $BACKUP/dynare ~/
sudo rsync -avuP $BACKUP/Images ~/
sudo rsync -avuP $BACKUP/Musik ~/
sudo rsync -avuP $BACKUP/Schreibtisch ~/
sudo rsync -avuP $BACKUP/SofortUpload ~/
sudo rsync -avuP $BACKUP/Videos ~/
sudo rsync -avuP $BACKUP/Vorlagen ~/
sudo rsync -avuP $BACKUP/Work ~/
sudo rsync -avuP $BACKUP/.config/Nextcloud ~/.config/
sudo rsync -avuP $BACKUP/.gitkraken ~/
sudo rsync -avuP $BACKUP/.gnupg ~/
sudo rsync -avuP $BACKUP/.local/share/applications ~/.local/share/
sudo rsync -avuP $BACKUP/.matlab ~/
sudo rsync -avuP $BACKUP/.ssh ~/
sudo rsync -avuP $BACKUP/wiwi ~/
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
eval "$(ssh-agent -s)" #works in bash
eval (ssh-agent -c) #works in fish
ssh-add ~/.ssh/id_rsa
```
Don't forget to add your public keys to GitHub, Gitlab, Servers, etc.


#### Filesystem optimizations: fstrim timer and tlp
[Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard); however, I am mostly on the 5.4 kernel, so I make sure that discard is not set in either my fstab or crypttab files, and also enable the fstrim.timer systemd service:
```bash
sudo sed -i "s|,discard||" /etc/fstab
cat /etc/fstab #should be no discard
sudo sed -i "s|,discard||" /etc/crypttab
cat /etc/crypttab #should be no discard
sudo systemctl enable fstrim.timer
```
Also, there is some debate whether tlp on btrfs is a good choice or should be deactivated. In any case, my laptops have sufficient battery power, so I remove it:
```bash
sudo apt remove --purge tlp
```

## Security steps with Yubikey
I have two Yubikeys and use them
- as second-factor for all admin/sudo tasks
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
sudo apt install -y gpg scdaemon gnupg-agent pcscd gnupg2 # stuff for GPG
```

Make sure that OpenPGP and PIV are enabled on both Yubikeys as shown above.

#### Yubikey: two-factor authentication for admin/sudo password 
Let's set up the Yubikeys as second-factor for everything related to sudo using the common-auth pam.d module:
```bash
pamu2fcfg > ~/u2f_keys # When your device begins flashing, touch the metal contact to confirm the association.
pamu2fcfg -n >> ~/u2f_keys # Do the same with your backup device
sudo mv ~/u2f_keys /etc/u2f_keys
# Make this required for common-auth
echo "auth    required                        pam_u2f.so nouserok authfile=/etc/u2f_keys cue" | sudo tee -a /etc/pam.d/common-auth
# Before you close the terminal, open a new one and check whether you can do `sudo echo test`
```

#### Yubikey: private GPG key
Let's use the private GPG key on the Yubikey (a tutorial on how to put it there is taken from [Heise](https://www.heise.de/ratgeber/FIDO2-YubiKey-als-OpenPGP-Smartcard-einsetzen-4590032.html) or [YubiKey-Guide](https://github.com/drduh/YubiKey-Guide)). My public key is given in a file called `/home/$USER/.gnupg/public.asc`:
```bash
sudo systemctl enable pcscd
sudo systemctl start pcscd
# Insert yubikey
gpg --card-status
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

## Apps


### Flatpak support
Enable flatpak support
```bash
sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

### System utilities

#### arandr
In case my monitor settings need more tweaking:
```bash
sudo apt install -y arandr
```

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
sudo apt install gnome-tweaks
```
I like to display my battery life using a percentage, set do nothing on lid close, and add weekday to the clock. Also clicking on the clock I set the location for wheather.


#### nautilus-admin
Right-click context menu in nautilus for admin
```bash
sudo apt install -y nautilus-admin
```


#### Timeshift and timeshift-autosnap-apt
Install Timeshift and configure it directly via the GUI for easy and almost instant system snapshots with btrfs:
```bash
sudo apt install -y timeshift
sudo timeshift-gtk
```
* Select "btrfs" as the "Snapshot Type"; continue with "Next"
* Choose your btrfs system partition as "Snapshot Location"; continue with "Next"  (even if timeshift does not see a btrfs system in the GUI it will still work, so continue (I already filed a bug report with timeshift))
* "Select Snapshot Levels" (type and number of snapshots that will be automatically created and managed/deleted by Timeshift), my recommendations:
  * Activate "Monthly" and set it to 1
  * Activate "Weekly" and set it to 3
  * Activate "Daily" and set it to 5
  * Deactivate "Hourly"
  * Activate "Boot" and set it to 3
  * Activate "Stop cron emails for scheduled tasks"
  * continue with "Next"
  * I also include the `@home` subvolume (which is not selected by default). Note that when you restore a snapshot Timeshift you get the choise whether you want to restore it as well (which in most cases you don't want to).
  * Click "Finish"
* "Create" a manual first snapshot & exit Timeshift
  
*Timeshift* will now check every hour if snapshots ("hourly", "daily", "weekly", "monthly", "boot") need to be created or deleted. Note that "boot" snapshots will not be created directly but about 10 minutes after a system startup. *Timeshift* puts all snapshots into `/run/timeshift/backup`. Conveniently, the real root (subvolid 5) of your btrfs partition is also mounted here, so it is easy to view, create, delete and move around snapshots manually. 

Now let's install *timeshift-autosnap-apt* from GitHub
```bash
sudo apt install -y git
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt
cd /home/$USER/timeshift-autosnap-apt
sudo make install
```

After this, optionally, make changes to the configuration file:
```bash
sudo nano /etc/timeshift-autosnap-apt.conf
```
For example, as we don't have a dedicated `/boot` partition, we can set `snapshotBoot=false` in the `timeshift-autosnap-apt-conf` file to not rsync the `/boot` directory to `/boot.backup`. Note that the EFI partition is still rsynced into your snapshot to `/boot.backup/efi`.

Check if everything is working:
```bash
sudo timeshift-autosnap-apt
```
Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift*.



#### Virtual machines: Quickemu and other stuff
I used to set up KVM, Qemu, virt-manager and gnome-boxes as this is much faster as VirtualBox. However, I have found a much easier tool for most tasks: [Quickqemu](https://github.com/wmutschl/quickemu) which uses the snap package Qemu-virgil:
```bash
git clone https://github.com/wmutschl/quickemu ~/quickemu
sudo apt install snapd bsdgames wget
sudo snap install qemu-virgil --edge
sudo snap connect qemu-virgil:kvm
sudo snap connect qemu-virgil:raw-usb
sudo snap connect qemu-virgil:removable-media
sudo snap connect qemu-virgil:audio-record
sudo ln -s ~/quickemu/quickemu /usr/local/bin/quickemu
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

#### Dropbox
Unfortunately, I still have some use case for Dropbox:
```bash
sudo apt install -y nautilus-dropbox
```
Open dropbox and set it up, check options.


#### Nextcloud
I have all my files synced to my own Nextcloud server, so I need the sync client:
```bash
sudo apt install -y nextcloud-desktop
```
Open Nextcloud and set it up. Recheck options and note to ignore hidden files once the first folder sync is set up.


#### OpenConnect and OpenVPN
```bash
sudo apt install -y openconnect network-manager-openconnect network-manager-openconnect-gnome
sudo apt install -y openvpn network-manager-openvpn network-manager-openvpn-gnome
```
Go to Settings-Network-VPN and add openconnect for my university VPN and openvpn for ProtonVPN, check connections.

#### Remote desktop
To access our University remote Windows desktop session:
```bash
sudo apt install -y rdesktop
echo "rdesktop -g 1680x900 wiwi-farm.uni-muenster.de -r disk:home=/home/$USER/  &" > ~/wiwi.sh
chmod +x wiwi.sh
cat <<EOF > ~/.local/share/applications/wiwi.desktop
[Desktop Entry]
Name=WIWI Terminal Server
Comment=WIWI Terminal Server wiwi-farm
Keywords=WIWI;RDP;
Exec=/home/$USER/wiwi.sh
Icon=preferences-desktop-remote-desktop
Terminal=false
MimeType=application/x-remote-connection;x-scheme-handler/vnc;
Type=Application
StartupNotify=true
Categories=Network;RemoteAccess;
EOF
```
Note that I also add a shortcut launcher.

#### TigerVNC Viewer
To access my server via VNC I install a very tiny VNC viewer, which works great:
```bash
sudo apt install -y tigervnc-viewer
```


### Coding

#### Dynare related packages
I am a developer of [Dynare](https://www.dynare.org) and need these packages to compile it from source and run it optimally ob Ubuntu-based systems:
```bash
sudo apt install -y build-essential gfortran liboctave-dev libboost-graph-dev libgsl-dev libmatio-dev libslicot-dev libslicot-pic libsuitesparse-dev flex bison autoconf automake texlive texlive-publishers texlive-latex-extra texlive-fonts-extra texlive-latex-recommended texlive-science texlive-plain-generic lmodern python3-sphinx latexmk libjs-mathjax doxygen
sudo apt install -y x13as
```

#### git related packages:
git is most important, as a GUI for it, I use GitKraken. Also to use lfs on some repositories one needs to initialize it once:
```bash
sudo apt install -y git git-lfs
git-lfs install
flatpak install -y gitkraken
```
The flatpak version of GitKraken works perfectly for me and I do want to avoid using PPAs or DEB packages from vendors homepages. Open GitKraken and set up Accounts and Settings. Note that in case of flatpak, one needs to add the following Custom Terminal Command: `flatpak-spawn --host gnome-terminal %d`. 

#### MATLAB
I have a license for MATLAB R2020a, unzipping the installation files in the the home folder and running:
```
sudo /home/$USER/matlab_R2020a_glnxa64/install
sudo apt install -y matlab-support
matlab #activate matlab and close it again
sudo chown -R $USER:$USER /usr/local/MATLAB
sudo chown -R $USER:$USER /home/$USER/.matlab
```
sets up MATLAB perfectly. Note that there is still a [shared resources-for-x11-graphics bug](https://de.mathworks.com/matlabcentral/answers/342906-could-not-initialize-shared-resources-for-x11graphicsdevice#answer_425485?s_tid=prof_contriblnk), which can be solved by
```bash
#this solves the shared resources for x11 graphics bug
echo "-Djogl.disable.openglarbcontext=1" > /usr/local/MATLAB/R2020a/bin/glnxa64/java.opts
```
Run matlab and I change some settings to use Windows type shortcuts on the Keyboard, add `mod` files as supported extensions, and do not use MATLAB's source control capabilities.


#### R
For teaching and data analysis there is nothing better than R and RStudio. These are the packages I commonly use:
```bash
sudo apt install -y r-base r-base-dev libatlas3-base libopenblas-base r-cran-rgl r-cran-foreign r-cran-mass r-cran-minqa r-cran-nloptr r-cran-rcpp r-cran-rcppeigen r-cran-lme4 r-cran-sparsem r-cran-matrix r-cran-matrixmodels r-cran-matrixstats r-cran-pbkrtest r-cran-quantreg r-cran-car r-cran-lmtest r-cran-sandwich r-cran-zoo r-cran-evaluate r-cran-digest r-cran-stringr r-cran-stringi r-cran-yaml r-cran-catools r-cran-bitops r-cran-jsonlite r-cran-base64enc r-cran-digest r-cran-rcpp r-cran-htmltools r-cran-catools r-cran-bitops r-cran-jsonlite r-cran-base64enc r-cran-rprojroot r-cran-markdown r-cran-ggplot2 r-cran-dplyr r-cran-hmisc r-cran-readr r-cran-readxl
```
whereas R-Studio needs to be installed from a deb:
```bash
export RSTUDVER=1.3.959
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-$RSTUDVER-amd64.deb --directory-prefix=/home/$USER/Downloads/
sudo apt install libclang-dev
sudo dpkg -i /home/$USER/Downloads/rstudio-$RSTUDVER-amd64.deb
```
Open rstudio, set it up to your liking.


#### Java via Openjdk
Install the default OpenJDK Runtime Environment:
```bash
sudo apt install -y default-jre default-jdk
java -version
```


#### Visual Studio Code
I am in the process of transitioning all my coding to Visual Studio code:
```bash
sudo snap install code --classic
```
I still have to decide which extensions I find most useful.

### Text-processing

#### Latex related packages
I write all my papers and presentations with Latex using mostly TexStudio as editor:
```bash
sudo apt install -y texlive texlive-font-utils texlive-pstricks-doc texlive-base texlive-formats-extra texlive-lang-german texlive-metapost texlive-publishers texlive-bibtex-extra texlive-latex-base texlive-metapost-doc texlive-publishers-doc texlive-binaries texlive-latex-base-doc texlive-science texlive-extra-utils texlive-latex-extra texlive-science-doc texlive-fonts-extra texlive-latex-extra-doc texlive-pictures texlive-xetex texlive-fonts-extra-doc texlive-latex-recommended texlive-pictures-doc texlive-fonts-recommended texlive-humanities texlive-lang-english texlive-latex-recommended-doc texlive-fonts-recommended-doc texlive-humanities-doc texlive-luatex texlive-pstricks perl-tk
sudo apt install -y texstudio
```
Open texstudio and set it up.



#### Meld
A very good program to visually compare differences between files and folders:
```bash
sudo apt install -y meld
```

#### Microsoft Fonts
Sometimes I get documents which require fonts from Microsoft:
```bash
sudo apt install -y ttf-mscorefonts-installer
```
#### Masterpdf
I have purchased a license for Master PDF in case I need advanced PDF editing tools:
```bash
flatpak install -y masterpdf
```
Open masterpdf and enter license. Also I use flatseal to give the app full access to my home folder.


#### Softmaker Office
I have a personal license for Softmaker Office, which needs to be installed via deb:
```bash
echo "deb http://shop.softmaker.com/repo/apt wheezy non-free" | sudo tee /etc/apt/sources.list.d/softmaker.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3413DA98AA3E7F5E
sudo apt install softmaker-office-2018
```
Open it and enter license.


#### Zotero
Zotero is great to keep track of the literature I use in my research and teaching. I install it via a flatpak:
```bash
flatpak install -y zotero
```
Open zotero, log in to account, install extension [better-bibtex](https://github.com/retorquere/zotero-better-bibtex/releases/) and sync.


### Communication

#### Mattermost
Our Dynare team communication is happening via Mattermost:
```bash
sudo snap install mattermost-desktop
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

#### Reorder Favorites
I like to reorder the favorites on the gnome launcher such that the program are accessible via shortcuts: <kbd>CTRL</kbd>+<kbd>1</kbd> opens the first program, <kbd>CTRL</kbd>+<kbd>2</kbd> opens the second one and so on.

#### Go through all programs
Hit <kbd>META</kbd>+<kbd>A</kbd> and go through all programs, decide whether you need them or uninstall these.

#### Change default apps
My default programs:
- web: firefox
- calendar: gnome-calendar
- musik: vlc
- video: vlc
- photos: gnome-photos

#### Check Startup programs
I have the following startup programs:
- Caffeine
- Dropbox
- ignore-lid-switch-tweak
- im-launch
- mattermost-desktop
- Nextcloud
- NVIDIA X Server Settings
- SSH Key Agent

#### Bookmarks for netdrives
Using <kbd>CTRL</kbd>+<kbd>L</kbd> in nautilus, I can open the following links insider nautilus
- university netdrive: `davs://USER@wiwi-webdav.uni-muenster.de/`
- university cluster `sftp://palma2c.uni-muenster.de`
- personal homepage `sftp://mutschler.eu`
and add bookmarks to these drives for easy access with nautilus.


#### History search in terminal using page up and page down
```bash
sudo nano /etc/inputrc
# Uncomment "\e[5~": history-search-backward
# Uncomment "\e[6~": history-search-forward
```

#### Printer setup
My home printer is automatically detected, but our network printer at work uses samba and needs to be set up manually. First, install some packages:
```bash
sudo -i
apt install -y printer-driver-cups-pdf system-config-printer system-config-printer-gnome 
apt install -y samba samba-common samba-common-bin samba-libs smbc smbclient
nano /etc/samba/smb.conf #change workgroup to WIWI
service cups stop
service cups-browsed stop
cat <<EOF >> /etc/cups/printers.conf
<Printer Ricoh-Aficio-MP-C2051>
PrinterId 1
UUID urn:uuid:8b54aed6-6d75-3415-6dc7-bd2fe2b69f35
Info Aficio Mp C2051
MakeModel Ricoh Aficio MP C2051 PDF
DeviceURI smb://WIWI-PRINTER/D-2240P04
State Idle
StateTime 1588060222
ConfigTime 1588060817
Type 12540
Accepting Yes
Shared Yes
JobSheets none none
QuotaPeriod 0
PageLimit 0
KLimit 0
OpPolicy default
ErrorPolicy retry-job
Option outputorder normal
</Printer>
EOT

service cups start
```
Go into printer setup and choose the right driver for the printer manually. Also I deactivate cups-browsed as I don't need constant checking of printers on the network.

#### Go through Settings
- Turn off bluetooth
- Change wallpaper
- Automatically delete recent files and trash
- Turn of screen after 15 min
- Turn on night mode
- Add online account for Nextcloud
- Deactivate system sounds, mute mic
- Turn of suspend, shutdown for power button
- Turn on natural scrool for mouse touchpad
- Go through keyboard shortcuts and adapt, I also add a custom one for xkill on <kbd>CTRL</kbd>+<kbd>ALT</kbd>+<kbd>X</kbd>
- Check region and language, remove unnecessary languages, then update 
- Change clock to 24h format
