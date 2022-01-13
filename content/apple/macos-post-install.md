---
title: 'macOS Monterey 12.1: Things to do after installation (Apps, Settings, and Tweaks) [WORK-IN-PROGRESS]'
#linktitle: macOS Monterey 12.1 apps-settings-tweaks
summary: In the following I will go through my post installation steps on macOS Monterey 12.1, i.e. which settings I choose and which apps I install and use.
toc: true
type: book
#date: "2022-01-05T"
draft: false
weight: 11
---
{{< figure src="DeskSetup.jpg" >}}

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

Since January 2021 I've been using an Apple MacBook Air (M1) as my daily driver. Even though I have a strong Linux background, I do like macOS quite a lot. Particularly, one of the great things about macOS is the huge amount of useful and well-designed apps, tools and utilities; not only on from the App Store but also by side-loading. Therefore, in the following I will go through my post installation steps, i.e. which apps I install and use and which system preferences I choose. In other words, this guide serves as a reminder of what I set and how I use my MacBook Air (M1).

### Beware of the costs
As we all know, not only Apple hardware but also software comes at a hefty premium. I've tried to write down how much I've spent on apps and subscriptions since I started my macOS journey in January 2021, and I've documented that below for each app. Here is a rough summary:

- 700€ one-time on app purchases
- 230€/year on app subscriptions
- 240€/year on Apple One Family

This doesn't include the applications and subscriptions I tested and discarded, so there is probably a significant sunk costs as well. On the other hand, some apps are universal and I have bought them before on my iPhone or iPad. Moreover, some subscriptions are covered by my university. 

Anyways, pay attention to the cost if you decide to use Apple's eco system. My tip: Try to cover the cost by buying gift cards in advance with a 15 or 20 percent bonus credit so that the cost is reduced by that percentage. I usually do this each year to at least cover my Apple One Family and other app subscriptions.



## Basic steps
Note that I do the initial macOS setup without any devices connected to the MacBook.

### Connect Thunderbolt docks
After doing the initial steps, I use the two Thunderbolt ports on my MacBook Air to connect on the one hand a [LG 35WN75C-B Curved UltraWide monitor](https://www.lg.com/de/monitore/lg-35wn75c-b) (which gives me a couple of additional USB ports) and on the other hand an [Anker PowerExpand Elite 13-in-1 Thunderbolt dock](https://www.anker.com/de/a8396launch) (which gives me much needed connectivity).

### Connect devices
The following devices are connected to the Anker dock:
- Audio Input & Output (Front): [Logitech Speakers Z130](https://www.logitech.com/de-de/products/speakers/z130-stereo-speakers.980-000418.html)
- Gigabit Ethernet: [CAT 7 Ethernet cable](https://www.amazon.de/gp/product/B0119F6512/ref=ppx_yo_dt_b_search_asin_title?ie=UTF8&psc=1)
- Thunderbolt 3 (40Gbps, 15W): [Solid State Logic SSL 2](https://www.solidstatelogic.com/products/ssl2)
- Thunderbolt 3 (40Gbps, 85W): [MacBook Air M1](https://www.apple.com/de/macbook-air/)
- USB 3.1 Gen 1 USB-A (Back): [Cable Matters DisplayLink 4K UHD](https://www.cablematters.com/pc-736-138-usb-30-to-hdmi-adapter-supporting-4k-resolution-for-windows-and-mac.aspx)
- USB 3.1 Gen 1 USB-A (Front): [Yubikey 5 NFC](https://www.yubico.com/de/product/yubikey-5-nfc/)
- USB 3.1 Gen 2 USB-C (Front): [Blackmagic ATEM Mini](https://www.blackmagicdesign.com/products/atemmini)


The following devices are connected to the LG 38 curved monitor:
- USB 3.0 USB-A: [Samsung T5 SSD](https://www.samsung.com/semiconductor/minisite/ssd/product/portable/t5/) for Time Machine
- USB 3.0 USB-A: [Logitech unifying receiver](https://www.logitech.com/en-us/products/mice/unifying-receiver-usb.910-005235.html) which connects my [Logitech MX Master 3](https://www.logitech.com/en-us/products/mice/mx-master-3.html) and my [Logitech ERGO K860](https://www.logitech.com/de-de/products/keyboards/k860-split-ergonomic.html) keyboard (USB-A)

### DisplayLink adapter
The MacBook Air M1 chip is only able to connect to a single external monitor natively; however, using an external DisplayLink Adapter I am able [to connect two or more external displays]((https://www.macworld.co.uk/how-to/how-connect-two-or-more-external-displays-apple-silicon-m1-mac-3799794/)). In particular, I connect a [FUJITSU Display B24-8 TS Pro](https://www.fujitsu.com/de/products/computing/peripheral/displays/b24-8-ts-pro/) in rotated mode. The quality is not great, either because of the adapter or the monitor or both, but as I am mostly using it to read PDFs, it does the job. To make this work, one has to install the [DisplayLink Manager](https://www.synaptics.com/products/displaylink-graphics/downloads/macos) software. After installing it, one needs to activate the app in `Screen Recording` in the `Security & Privacy` part of `System Preferences`.  Note that if you lock your system, there will be a message in the menu bar that *Your screen is being observed*.Moreover, in `Notifications & Focus` at the bottom activate `When mirroring or sharing the display` under `Allow notifications`. Furthermore, in the Apps settings, I set the rotation to 90° and set the software to launch at startup.

### Arrange displays and change desktop backgrounds
Go to `Displays` in `System Preferences` and arrange the displays. My MacBook is typically on a pile of books (on the left), the LG monitor is the main monitor and the rotated Dell monitor is on the right. I also choose different backgrounds for each monitor.

### Browsers and extensions
#### Safari (WIP)
My daily driver for surfing the web is Safari, so I go through the preferences and set it up to my liking. I also adjust the start page to see my iCloud tabs. Lastly, I install the following extensions via the App Store:
- [Bitwarden (10$/year)](https://apps.apple.com/us/app/bitwarden/id1352778147?mt=12): This also installs a desktop app, which I start first to enable `Unlock with TouchID`. Then I set up the extension in Safari to also use Biometrics to unlock in Safari.
- [1Blocker (1.99€/month)](https://apps.apple.com/us/app/1blocker-ad-blocker-privacy/id1365531024): In the extensions panel of the Safari preferences I enable all 1Blocker extensions and then set up the app to my liking.

Settings:
- Show Favorites Bar
  
#### Chrome
For YouTube and some websites that do not work under Safari, I also install [Google Chrome](https://www.google.com/chrome/). I don't make it my default browser, but do sign in to my Google account to sync my settings and extensions. Again I am using [Bitwarden](https://chrome.google.com/webstore/detail/bitwarden-free-password-m/nngceckbapebfimnlniiiahkandclblb?hl=en) to access my passwords and [uBlock origin](https://chrome.google.com/webstore/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm?hl=en) to block ads.

### Enable internet accounts for calendar, contacts and mails
In `Internet Accounts` of `System Preferences` I enable and set up my accounts for mails, calendars and contacts:
- Mailbox.org (IMAP and SMTP)
- Nextcloud (CardDAV and CalDAV)
- University account (IMAP and SMTP)
- Microsoft 365 account (Exchange)
- iCloud (all except Mail)

### Finder Preferences
I change some preferences in Finder for my convenience:

- Show Connected servers on desktop
- New Finder windows show `wmutschl` (my user name)
- Show all items in the sidebar except Recents and AirDrop
- Show all filename extensions
- Don't show warning before changing an extension
- Don't show warning before removing from iCloud Drive
- Show warning before emptying the Bin
- Remove items from the Bin after 30 days
- Keep folders on top for `In windows when sorting by name`
- Keep folders on top for `On Desktop`

When performing a search I select `Search the Current Folder`; moreover, in the View menu I activate `Show Path Bar` and `Show Status Bar`. Lastly, I change the view to icon view, <kbd>CMD</kbd>+<kbd>1</kbd>, then I hit <kbd>CMD</kbd>+<kbd>j</kbd> and select the layout I want by default; particularly, I like:
- Activate `Always open in icon view` and `Browse in icon view`
- Group by `None`
- Sort by `Name`
- Icon Size `64 x 64`
- Grid spacing `5`
- Text Size `12`
- Label Position: `Bottom`
- Uncheck `Show Item Info`
- Check `Show Item Preview`
- Check `Show Library Folder`
- Background `Default`
Hit `Use As Defaults` at the bottom.


## Terminal.app
The terminal is a very powerful tool I use daily for my work, so I do the following to create my development environment. So open Terminal.app and run the following commands.

### Xcode Command Line Tools
`Command Line Tools for Xcode` (like git, rsync, compilers) are important for coding and development, they can be installed by:
```sh
xcode-select --install
```


### Rosetta 2
Unfortunately, some software I use is still (and probably will never) be ported to Apple Silicon (ARM), so I make sure to install the Intel compatibility layer [Rosetta 2](https://support.apple.com/en-us/HT211861):
```sh
softwareupdate --install-rosetta --agree-to-license
```

### Homebrew (Intel and ARM)
Homebrew is the [missing package manager for macOS](https://brew.sh) which allows one to install all sorts of software and tools I need for my work. I need to make sure that I have both the Intel as well as ARM version of homebrew installed. So open terminal.app and install the ARM version of homebrew first:
```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/wmutschl/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```
This installs Homebrew into `/opt/homebrew`. Next, I install the Intel version using the `arch -x86_64` prefix:
```sh
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
This install Homebrew into `/usr/local/homebrew`. 


### Fish (A Friendly Interactive Shell)
Instead of Apples default `zsh` shell, I like to use [Fish shell](https://fishshell.com) as it is much more [interactive and user-friendly](https://fedoramagazine.org/fish-a-friendly-interactive-shell/). This can be installed easily with (ARM) homebrew:
```sh
brew install fish
```
To make fish the default shell one needs to first include it into `/etc/shells`:
```sh
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
cat /etc/shells
#/bin/bash
#/bin/csh
#/bin/dash
#/bin/ksh
#/bin/sh
#/bin/tcsh
#/bin/zsh
#/opt/homebrew/bin/fish
```
And then change the shell:
```sh
chsh -s /opt/homebrew/bin/fish
```
Close the Terminal.app and re-open another Terminal.app and you should be greeted by Fish.

Lastly, I make sure that `/opt/homebrew/bin` is in my `fish_user_paths`:
```sh
set -U fish_user_paths /opt/homebrew/bin $fish_user_paths
```

### Alias for ARM Homebrew and Intel Homebrew in Fish
Sometimes I need to be sure to either run Homebrew on ARM or on Intel, so I create an alias `mbrew` for the ARM version of Homebrew and another one `ibrew` for the Intel version of Homebrew. In Fish you do this in the following way:
```sh
alias mbrew "/opt/homebrew/bin/brew"
funcsave mbrew

alias ibrew "arch -x86_64 /usr/local/bin/brew"
funcsave ibrew
```

### .local/bin in $PATH
I like to have `$HOME/.local/bin` in my $PATH. In Fish one can do this using the following command:
```sh
mkdir -p /Users/wmutschl/.local/bin
set -Ua fish_user_paths /Users/wmutschl/.local/bin
```
zsh and bash usually pick this up, once the folder is created. You can check this by opening another Terminal.app and running
```sh
bash -C "echo $PATH"
zsh -c "echo $PATH"
```

### Terminal theme
I like the [Dracula Dark theme for Terminal.app](https://draculatheme.com/terminal), which can be downloaded via git:
```sh
mkdir -p $HOME/dracula/terminal-app
git clone https://github.com/dracula/terminal-app.git $HOME/dracula/terminal-app
```
To activate the theme, go to the preferences menu of Terminal.app and to the `Profiles` tab. On the bottom click on the circle with the three dots and select import. Go to `$HOME/dracula/terminal-app` and select the `Dracula.terminal` file. Select the `Dracula` profile and click on `Default` at the bottom. Close the preferences and all Terminal.app windows. Re-open it and you should have the new theme. Actually, it is a mix between Fish and Dracula, which I like.


## Time Machine: Backup and restore files

The easiest way to restore everything is to use the migration assistant, but typically I only need to restore some folders and files from my Time Machine backups (or alternatively sync from my Nextcloud server). So I open Time Machine, add my backup disk and activate both automatic backups as well as displaying it in the menu bar. After the first backup, you can either use Time Machine directly to restore certain folders and files or, alternatively, open the disk in finder, select the most recent snapshot and simply copy the files and folders over.


## SSH keys
If I want to create a new SSH key, I run in Terminal.app:
```sh
ssh-keygen -t ed25519 -C "MacBook Air"
```
Usually, however, I restore my `.ssh` folder from my backup (see above). Either way, afterwards, one needs to add the file containing your key, usually `id_rsa` or `id_ed25519`, to the ssh-agent. First start the ssh-agent in the background:
```sh
eval "$(ssh-agent -s)" #works in bash,zsh
eval (ssh-agent -c) #works in fish
```
Next, we need to modify `~/.ssh/config` file to automatically load keys into the ssh-agent and store passphrases in the keychain. As I restore from backup, I don't have to do this step. But for completeness, if the file does not exist yet, create and open it:
```sh
touch ~/.ssh/config 
nano ~/.ssh/config
```
Make sure that it includes the following lines:
```sh
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```
If your SSH key file has a different name or path than the example code, modify the filename or path to match your current setup. Note: If you chose not to add a passphrase to your key, you should omit the *UseKeychain* line. Lastly, let's add our private SSH key to the ssh-agent:
```sh
ssh-add -K ~/.ssh/id_ed25519
```
Don't forget to add your public key to GitHub, Gitlab, Servers, etc.

## Private GPG key with Yubikey
I store my private GPG key on two Yubikeys (a tutorial on how to put it there is taken from [Heise](https://www.heise.de/ratgeber/FIDO2-YubiKey-als-OpenPGP-Smartcard-einsetzen-4590032.html) or [YubiKey-Guide](https://github.com/drduh/YubiKey-Guide)). For this I need to install several packages via ARM Homebrew first
```sh
mbrew install gnupg yubikey-personalization ykman
```
Make sure that the .gnupg folder has the correct permissions:
```sh
find ~/.gnupg -type f -exec chmod 600 {} \;
find ~/.gnupg -type d -exec chmod 700 {} \;
```
Now insert the first Yubikey and check whether it is recognized:
```sh
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
# PIV     	Enabled	Enabled	
# OATH    	Enabled	Enabled 	
# FIDO2   	Enabled	Enabled 	
```
Do the same for the backup Yubikey. Make sure that OpenPGP and PIV are enabled on both Yubikeys as shown above. Next, check whether the GPG card on both Yubikeys is readable by gpg:
```sh
gpg --card-status
# Reader ...........: Yubico YubiKey OTP FIDO CCID
# Application ID ...: D2760001240100000006096001740000
# Application type .: OpenPGP
# Version ..........: 0.0
# Manufacturer .....: Yubico
# Serial number ....: 09600174
# Name of cardholder: [not set]
# Language prefs ...: [not set]
# Salutation .......: 
# URL of public key : [not set]
# Login data .......: [not set]
# Signature PIN ....: not forced
# Key attributes ...: rsa4096 rsa4096 rsa4096
# Max. PIN lengths .: 127 127 127
# PIN retry counter : 3 0 3
# Signature counter : 652
# UIF setting ......: Sign=off Decrypt=off Auth=off
# Signature key ....: C13E 5D55 8A9F 4AFE AE08  6186 91E7 24BF 17A7 3F6D
#     created ....: 2019-12-09 08:36:41
# Encryption key....: 5D12 A11E 39A6 1ED2 E0F9  9F23 16B5 237D 5563 8B96
#     created ....: 2019-12-09 08:36:41
#Authentication key: E1B6 6FC6 852C 0FC1 9917  D825 8CFE 5D68 CC28 71C3
#     created ....: 2019-12-09 08:38:21
#General key info..: pub  rsa4096/91E724BF17A73F6D 2019-12-09 Willi Mutschler <willi@mutschler.eu>
#sec>  rsa4096/91E724BF17A73F6D  created: 2019-12-09  expires: never     
#                                card-no: 0006 09600174
#ssb>  rsa4096/16B5237D55638B96  created: 2019-12-09  expires: never     
#                                card-no: 0006 09600174
#ssb>  rsa4096/8CFE5D68CC2871C3  created: 2019-12-09  expires: never     
#                                card-no: 0006 09600174
```
I copy my public key in a file called `/home/$USER/.gnupg/public.asc`:

```sh
cd ~/.gnupg
gpg --import public.asc
gpg --edit-key 91E724BF17A73F6D
  trust
  5
  y
  quit
echo "This is an encrypted message on my Mac" | gpg --encrypt --armor --recipient $KEYID -o encrypted_MAC.txt
gpg --decrypt --armor encrypted_MAC.txt
```
This should ask you for the User Pin and you should be able to decrypt the message.



## Apple Apps
Before I install additional apps, I go through all the applications Apple ships by default in order to provide the necessary permissions and change some settings. So I click on all the apps in Launchpad and make changes to some app settings, which I list below.

#### App Store
Turn off Video Autoplay and Automatic Updates as I usually do manual updates once a week to not miss new features.

#### Calendar
Check whether all calendars are correctly synced and set the default calendar and notification times.

#### Contacts
Check whether all contacts are correctly synced and sort by first name.

#### Disk Utility
In the view menu I select to `Show all devices` and `Show APFS Snapshots`.

#### iMessage and FaceTime
First, sign in to iMessage and then set up *Name and Photo*. Second, turn on *Enable Messages in iCloud* and *Send read receipts*. Also make sure that messages are kept forever. Lastly, I sign in to FaceTime and check the settings as well.

#### Mail
- Check addresses and ports of mail accounts
- Deactivate `organize by conversation` in *View* for all folders (needs to be done for each folder individually)
- Change message font to Menlo

#### Music
Turn on Lossless audio.

#### Photos
I go to preferences and check the following:
- [x] Download Originals to this Mac
- [x] Deactivate Autoplay Videos and Live Photos
- [x] Activate Show Holiday Events
- [x] Activate Show Memories Notifications
- [x] Sharing: Include location information

#### Podcasts
Deactivate automatic downloads.

#### TV+
I change the quality of streaming and downloads to the highest values. Also I activate automatic deletion of watched movies and TV shows.






## Apps, Apps, Apps
In the following I list the tools I use, how to install and configure them. 

### Productivity and Utilities

#### Amphetamine and Amphetamine Enhancer (free)
A little helper in case my MacBook needs to stay up all night. It can be installed from the App Store. Start the app and follow the instructions on the welcome screen. I also download [Amphetamine Enhancer](https://github.com/x74353/Amphetamine-Enhancer) to use the *Closed Display fail-safe*.


#### Dockey (free)
This neat little app makes the Dock behave as I like. [Download](https://dockey.publicspace.co) it and move it manually to the Applications folder. I choose the following preferences:
- Auto-Hide Dock: Hide
- Animation Delay: Little
- Animation Speed: Fast

#### Logi Options+ (free)
Logitech Options does not work well with Apple Silicon; however, they have a new beta software called [Logi Options+](https://www.logitech.com/de-ch/software/logi-options-plus.html) which you can download via signing up for the beta program. After that you get the download link via email. Install the software and follow the onboarding screen to allow some permissions in `Security & Privacy`, i.e. `Accessibility`,  `Bluetooth` and `Input Monitoring`. I set some general behavior; particularly, I don't use natural scrolling on the scroll wheel and use the inverted direction for the thumb wheel. I then have a look at the global settings of the buttons. I remap the default behavior of the forward and back buttons to copy and paste. At the same time, I enable applications-specific settings for Safari and Chrome such that the default behavior is to go forward and back again. Moreover, I like that the thumb wheel switches between tabs. Next, I remap the gestures such that clicking the thumb button opens Mission Control, hold+left goes back, hold+right goes forward, hold+up opens a terminal, hold+down opens Safari. 


#### Mission Control Plus (9.65€)
From Gnome I am used to be able to close the windows from the activity overview, which is called mission control on macOS. So I download [Mission Control plus](https://www.fadel.io/missioncontrolplus) for which I already purchased a license. Unzip it and manually move it to the applications folder. Open the app and follow the instructions. Then enter the license in the menu bar and I choose to hide the tray icon.

#### Moom (9.99€)
There are many options for tiling windows on macOS. I find Moom quite flexible and install it via the [App Store](https://apps.apple.com/us/app/moom/id419330170?mt=12).  I choose to run it as a menu bar application and open at startup. I also add a keyboard shortcut <kbd>CTRL</kbd>+<kbd>space</kbd> and add layouts I use often to shortcuts. When I have a working configuration I backup the settings by running in terminal.app:
```sh
defaults export com.manytricks.Moom ~/Moom.plist
```
So when I re-install Moom I can simply restore my settings by running in terminal.app:
```sh
defaults import com.manytricks.Moom ~/Moom.plist
```

#### Money Money (29.99€)
I really like this tool for my banking so I purchased a license. Download the software from the [App Store](https://apps.apple.com/de/app/moneymoney/id872698314?mt=12) and open it. Immediately in the menu bar I select `Help`-`Show database in Finder`. Close Money Money completely (<kbd>CMD</kbd>+<kbd>q</kbd>). Then I delete the three folders `Database`, `Extensions` and `Statements` and restore them from my backup. Restart Money Money, enter your database password and license. Then I go through the settings.


#### Nextcloud (free)
I have all my user files synced to my own Nextcloud server, see my [backup strategy](../../linux/backup), so I need the sync client, which can be [downloaded](https://nextcloud.com/install/#install-clients). Open nextcloud.app and set up the server and a first folder sync. After the first sync, I need to recheck the options and particularly launch the app on System startup, deactivate 500 MB limit and edit the ignored files. Usually, I don't sync hidden files and add `.DS_Store` and `*.photoslibrary` to the ignored files list. Again make sure to adjust settings after the first folder sync, because otherwise the Global Ignore Settings cannot be adjusted.


#### Reeder 5 (9.99€)
This is my go to RSS reader app on my iPhone, iPad and MacBook. I usually use it on my iPhone, but I also want it on my MacBook, so download it from the [App Store](https://apps.apple.com/de/app/reeder-5/id1529448980?mt=12) and enable syncing feeds via iCloud. Activate `Don't fetch on this mac` as I am fetching the feeds on my iPhone.

#### Things 3 (49.99€)
My favorite To-Do app, which I've bought for all my devices. Download from the [App Store](https://apps.apple.com/de/app/things-3/id904280696?mt=12), start it and enable Things Cloud. This syncs my to-do's between my devices. I then go through the preferences and adjust to my liking.

#### Timeular (89€)
I've purchased a [Timeular Tracker](https://timeular.com/tracker/) in 2021, which came with the [Basic plan](https://timeular.com/pricing/) for free. Now, the tracker is cheaper (69€), but the basic plan is not included anymore and costs 5€/month. So I am quite happy with my deal. Anyways, I install the app from the [website](https://timeular.com/download/), start it and sign in. This syncs my data and settings.


### Networking and Virtualization

#### Tailscale (free)
This is an amazing piece of software based on wireguard to connect all my devices no matter where I am at or if there are firewalls between the devices. It creates a Mesh network and I can access securely all my mobile devices, computers and servers without exposing them to the internet. Tailscale can be downloaded from the [App Store](https://apps.apple.com/us/app/tailscale/id1475387142?mt=12). Open the app and select to auto start on login. The app resides as a tray icon, which you can click to sign in to your account, change some settings and easily access the IP addresses of the different machines.


#### Microsoft Remote Desktop (free)
I use [xrdp](https://c-nergy.be/blog/?cat=79) on servers that have a desktop environment. As a client software I use Microsoft Remote Desktop which can be downloaded from the [App Store](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466?mt=12). Open it and change the settings, particularly, the video settings to 1080p. Using the [Tailscale](#tailscale-free) IPs I can then connect to my servers.

#### Parallels (39.99€/year)
This is a powerful and user-friendly piece of software to run virtual machines (VM). Particularly, I like to try out Linux ARM VM's, Raspberry Pi Images, or MacOS clean installs to test Dynare versions. Parallels can be downloaded from their [website](https://www.parallels.com/products/desktop/trial/) after signing up. I am eligible to use the Education version, which is sufficient for my needs. After installation and activating the software I go through the settings. If I have not done so already, I also create a clean MacOS install for testing. Note that all VMs will be installed into `~/Parallels`. Obviously, I don't want the virtual machines in my Time Machine backups, so I exclude this folder in my Time Machine preferences.

#### Screens 4 (29.99€)
To access my servers via VNC or my MacBook Air from remote, I use Screens 4 combined with [Tailscale](#tailscale-free). It can be downloaded from the [App Store](https://apps.apple.com/de/app/screens-4/id1224268771?mt=12) and I set it up to use sync my settings via iCloud. Particularly, I sync my machines and like to share the clipboard.


#### University VPN and eduroam (free)
To access the VPN of my university and connect to the [eduroam wifi network](https://eduroam.org), I need to install two profiles. So first download these

- [eduoroam profile](https://uni-tuebingen.de/fileadmin/Uni_Tuebingen/Einrichtungen/ZDV/Dokumente/Anleitungen/eduroam/eduroam_2021.mobileconfig)
- [VPN profile](https://uni-tuebingen.de/fileadmin/Uni_Tuebingen/Einrichtungen/ZDV/Dokumente/Anleitungen/VPN/vpn-uni-tuebingen-2021.mobileconfig)

Then go to settings and install those profiles. Afterwards one simply follows the [VPN guide](https://zdv-wiki.uni-tuebingen.de/display/CICS/VPN+Configuration+on+macOS) or the [eduroam guide](https://uni-tuebingen.de/en/einrichtungen/zentrum-fuer-datenverarbeitung/dienstleistungen/netzdienste/netzzugang/roaming/eduroam-os-x/) to set it up. Also make sure to test whether it works.



### Text-processing

#### DeepL (free)
One of the best tools ever to translate chunks of text from one language into another. [Download](https://www.deepl.com/en/app/) and install it. Now every time I hit <kbd>CMD</kbd>+<kbd>c</kbd> twice, my selected text will be sent to DeepL and auto-translated. I often improve my texts by translating the texts back and forth while adjusting the expressions by right-clicking on words and phrases.

#### iA Writer (29.99€)
Even though I do like [Ulysses](https://ulysses.app) and [Bear](https://bear.app), they miss Latex and table capabilities that I really like to use. I found that [iA Writer](https://ia.net/writer) is perfect for me and also does not include a subscription service which is great. Lastly, it creates standard `txt` or `md` files which you can easily move around instead of putting everything in some proprietary database. So overall, a great solution which also works across all my Apple devices. It can be installed from the [App Store](https://apps.apple.com/de/app/ia-writer/id775737590?mt=12). Start it and enable iCloud sync to get all your files. Also check the preferences, settings and themes. I quite like the default though.

#### Keynote (free)
Instead of Powerpoint I really like Apples take on presentations. It can be installed via thee [App Store](https://www.zotero.org). Open it and go through the settings.

#### Latex related packages (free)
I simply install [MacTex](http://www.tug.org/mactex/mactex-download.html) and use the [LaTex Workshop extension](https://marketplace.visualstudio.com/items?itemName=James-Yu.latex-workshop) for [VScode](#visual-studio-code-free) as my editor.

#### Liquid Text LIVE (95.99€/year)
I use this app both on my Mac and iPad for research, it can be installed from the [App Store](https://apps.apple.com/us/app/liquidtext/id922765270) and has [different versions](https://www.liquidtext.net/pricing-features). As I am using it on my iPad as well I chose the LIVE edition. It does need some getting used to, particularly the handling of folders and files, but it is really great to collect thoughts and read papers for research, teaching and other projects. Highly recommended! After installation I need to restore my purchases to re-activate my license and sync my database.

#### Microsoft Excel and Word (free via university, otherwise 69€/year)
Sometimes I get documents which require [Microsoft Excel](https://apps.apple.com/us/app/microsoft-excel/id462058435?mt=12) and [Microsoft Word](https://apps.apple.com/us/app/microsoft-word/id462054704?mt=12) from the [App Store](https://apps.apple.com/de/app-bundle/microsoft-365/id1450038993?mt=12). Luckily, I have a license via my university; but honestly, I try to use other tools.

#### Notability (11.99€)
Notability is the app I love to use for teaching and writing down notes on my iPad. As those notes can be synced via iCloud, I also like to have the app on my MacBook, but honestly, I mostly use it on my iPad. It can be installed via the [App Store](https://apps.apple.com/us/app/notability/id360593530). They recently changed to a subscription model; however, I purchased it a couple of years ago and don't need the new features yet. Otherwise it would be 11.99€/year. So after opening the app, I restore my purchases and sync using iCloud.

#### PDF Expert (69.99€)
I have purchased PDF Expert in 2019 for any advanced PDF editing needs I have. I really don't need any Adobe products for that. It can be installed from the [Mac App Store](https://apps.apple.com/de/app/pdf-expert-pdf-bearbeiten/id1055273043?mt=12). Open it and go through the settings; make sure that the purchases are restored.


#### Zotero (free)
Zotero is great to keep track of the literature I use in my research and teaching. Download it from their [website](https://www.zotero.org) and install it. Open zotero, log in to an account, and sync the settings. I need to install one extension called [better-bibtex](https://github.com/retorquere/zotero-better-bibtex/releases/) and also disable the LibreOffice and Word connector extensions.





### Coding

#### GitKraken (4.95€/month)
GitKraken is a great tool that simplifies `git` for me. I use it daily and have a Pro license. So, download the [GitKraken installer](https://www.gitkraken.com/download) and install it. Open GitKraken and set up Accounts and Settings (or restore from Backup).

#### Hugo (free)
My website uses the [Hugo Academic Theme](https://github.com/wowchemy/starter-hugo-academic) for [Hugo](https://github.com/gohugoio/hugo), which is based on Go. So I install Go and hugo with ARM Homebrew:
```sh
mbrew install golang hugo
```

#### MATLAB (free via university, otherwise 500€ + 250€ per toolbox)
I use MATLAB for teaching and research; unfortunately, the cost is quite high, but luckily I have a university-wide license. So I install MATLAB using the installation files from [Mathworks](https://mathworks.com/download). Follow the instructions to install all the toolboxes I need. Then start MATLAB, make sure the license is activated and I sign in. Then I go through the preference section.
There is a `Warning: the font "Times" is not available, so "Lucida Bright" has been substituted, but may have unexpected appearance or behavor. Re-enable the "Times" font to remove this warning.` So I download a free [times font](https://www.freebestfonts.com/timr45w-font) and install it.


#### Visual Studio Code (free)
I do all my non-MATLAB development work and server administration stuff with VSCode. The Apple Silicon installer can be [downloaded and installed](https://code.visualstudio.com/download). As I use the *Settings Sync* functionality, I only need to sign in and sync all my settings and extensions cross-plattform. Pretty great!


#### Dynare (free)
As I am a member of the development team, I need to have some tools installed with Homebrew. For this, I've written a guide on how to [compile Dynare from source for macOS](https://git.dynare.org/Dynare/dynare#macos), which I simply follow.






### Communication

#### Mattermost (free)
Our Dynare team communication is happening via Mattermost which can be easily [downloaded and installed](https://mattermost.com/download/#). Connect the server and log in. The preferences are synced from the server, but better safe than sorry, I double check the preferences.

#### Skype (free)
I use Skype to communicate with work colleagues. The Apple Silicon installer for Skype can be installed from their [website](https://www.skype.com/de/get-skype/). Open skype, log in and set up audio and video. Start a meeting and try out to share the screen, this will open a prompt to also enable `Screen Sharing` in `Security & Privacy` settings, which I enable.


#### Zoom (free via university, otherwise 14.99€/month)
I use Zoom mostly for work meetings and teaching, but also the occasional private online gathering. Also my [booking appointments system](https://schedule.mutschler.eu) automatically creates Zoom links. The software can be installed from their [website](https://zoom.us/download). Choose the installer for Apple Silicon/M1. Open zoom, log in and set up audio and video, and any other settings. Start a meeting and try out to share the screen, this will open a prompt to also enable `Screen Sharing` in `Security & Privacy` settings, which I enable.




### Multimedia

#### Atem Switchers Software (free)
As I use an ATEM Mini to switch video inputs for teaching and presentations, I [download](https://www.blackmagicdesign.com/support/family/atem-live-production-switchers) and install the software to make sure I have the latest firmware. Open Atem Software Control.app and either restore your settings from a backup or set up the ATEM to your liking.

#### Elgato Control Center (free)
I have two Elgato Key Lights which I usually control via home.app (connected via [homeassistant](https://www.home-assistant.io/integrations/elgato/)). To make sure I have the latest firmware I also install the [Elgato Control Center](https://www.elgato.com/en/downloads). Once downloaded move it to the Applications folder and go through its preferences.

#### Fission (42$)
For fast and lossless audio editing I have purchased [Fission](https://rogueamoeba.com/fission/). After downloading it, move the app to the applications folder, start it and enter your license. I also go through the preferences.

#### Hand Mirror (free)
A neat little tool to quickly check how you look on your webcam. Install it from the [App Store](https://apps.apple.com/us/app/hand-mirror/id1502839586?mt=12) and start it. I usually increase the window size to max.

#### IINA (free)
One of the best video players for macOS. [Download](https://iina.io), open the dmg and install it. Open the app and check the settings.

#### Narrated (16.99€)
A neat little software for screen recordings with a personal touch which I like to use for simple screen recordings. For more advanced settings, I rely on [OBS](#obs-free).
Download from the [website](), open it and allow the required permissions in `Security & Privacy`. Close the overlay of the app so you can access the menu bar to change some settings and enter the license key.

#### OBS (free)
OBS is the number one choice for streaming and recording. It needs some getting used to, but once you set up your scenes it works flawlessly. [Download]((https://obsproject.com/download)) OBS Studio and install it. Open OBS and allow the required permissions in `Security & Privacy`. Import your scenes, etc. I still have much to learn in OBS.

#### OpenAudible (15.95€)
OpenAudible is an audiobook library manager that helps keep track of and back up my audible purchases. [Download](https://openaudible.org), install and enter your license. Then I go through the preferences, change the default file format to MP3 and adjust the library folders. Next I connect to Audible and do a full sync of my library.

#### Pro Apps Bundle for Education: Final Cut Pro (239,98€)
I purchased the [Pro Apps Bundle for Education](https://www.apple.com/at-edu/shop/product/BMGE2ZM/A/pro-apps-bundle-für-bildung) including Final Cut Pro, Logic Pro, Motion, Compressor and MainStage. However, so far I have only used Final Cut Pro to edit my YouTube videos. Once you get the code for the education bundle enter it in the App Store and you can download the apps you need. I usually keep my raw video files in a folder `~/FinalCutRaw` and I don't want this in my Time Machine backups. So I add this folder to the exception list in Time Machine.

#### Creator's Best Friend (9.99€)
Creator’s Best Friend converts Chapter Markers from a Final Cut Pro project into Video Chapters for YouTube. It is very easy to use and I like that. Install it from the [App Store](https://apps.apple.com/app/id1524172135).

#### Pixelmator Pro (19.99€)
Most of the times Apple Photos is sufficient for me to edit my pictures. However, for advanced editing I use Pixelmator Pro which can be installed from the [App Store](https://apps.apple.com/us/app/pixelmator-pro/id1289583905?mt=12).




## System Preferences

I open `System Preferences` and basically go through all the settings to improve my experience on macOS. I try to document this below.


#### Apple ID
- Edit the profile picture
- Check `Name, Phone, Email` and deactivate `Announcements` and `Apps, music, TV and more`
- `Password & Security`: Make sure that `Two-Factor Authentification` is On and there is at least one `Trusted Phone Numbers`. I also `manage` the information in `Account Recovery` and `Legacy Contact` if there are changes. Lastly, it is nice to clean up `Apps Using Apple ID`.
- `Payment & Shipping`: Double check whether my credit card and Shipping address are correct.
- `iCloud`: Turn on all services I use, i.e. everything except *iCloud Mail* and *Hide My Email*. I also `Manage` my iCloud Storage and delete files/backups of devices and Apps that I don't use anymore.
- `Media & Purchases`: Enable `Use TouchID for purchases`. I then double-check everything under `Manage` both my account and my subscriptions. Particularly, I `Share New Subscriptions` with my family and want to receive `Renewal Receipts`.

Lastly, I `Remove from account` any devices that I don't have anymore.

#### Family Sharing

I check if I share all subscribed apps with my family and also if the roles are correct. Moreover, I go through everything under `Shared with your Family` and make changes if needed.

#### General

- Appearance: Light
- Accent color: multicolor (first one)
- Highlight color: `Accent Color`
- Sidebar icon size: `Small`
- Check `Allow wallpaper tinting in windows`
- Show scroll bars: `Automatically based on mouse or trackpad`
- Click in the scroll bar to: `Jump to the next page`
- Default web browser: `Safari.app`
- Prefer tabs: `in full screen` when opening documents
- Uncheck `Ask to keeo changes when closing documents`
- Check `Close windows when quitting an app`
- Recent items: `10` Documents, Apps, and Servers
- Check `Allow Handoff between this Mac and your iCloud devices`

#### Desktop & Screen Saver

Desktop: Set background for each display. I like to use the Dynamic Desktops, `The Beach` for the MacBook Air, `The Lake` for the LG Monitor, and `The Cliffs` for the Fujitsu Monitor.

Screen Saver: 
- I like the `Hello` screensaver and use the default `Screen Saver Options`.
- Activate `Show Screen Saver after *10* Minutes`. Note that we need to change the `Sleep` setting to a higher number.
- Deactivate `Use random screen saver`
- Deactivate `Show with clock`
- Hot Corners (bottom right): remove everything as I don't use `Quick note`

#### Dock & Menu Bar

Dock & Menu Bar
- Size: leave at default (about 40%)
- Magnification: Activate and set to about 75%
- Position on screen: `Bottom`
- Minimize Windows using: `Genie effect`
- Activate `Double-Click a window’s title bar` to `zoom`
- Activate `Minimize windows into application icon`
- Activate `Animate opening applications`
- Activate `Automatically hide and show the Dock`
- Activate `Show indicators for open applications`
- Activate `Show recent applications in Dock`
- Deactivate `Automatically hide and show the menu bar on desktop`
- Activate `Automatically hide and show the menu bar in full screen`

Control Center:
- Deactivate `Show in Menu Bar` for
  - Wi-Fi
  - Bluetooth
  - Air Drop
  - Keyboard Brightness
  - Display
  - Sound
- Activate `Show in Menu Bar` for
  - Focus (when active)
  - Screen Mirroring (when active)
  - Now Playing (when active)

Other Modules:
- Accessibility Shortcuts: deactivate both `Show in Menu Bar` and `Show in Control Center`
- Battery: activate `Show in Menu Bar`, activate `Show in Control Center`, activate `Show percentage`
- Fast User Switching: deactivate both `Show in Menu Bar` and `Show in Control Center`

Menu Bar Only:
- Clock: 
  - activate `Show the day of the week` and activate `Show date`
  - Time Options: `Digital`
  - activate `Use a 24-hour clock`
  - deactivate `Flash the time separators` and `Display the time with seconds`
  - deactivate `Announce the time`
- Spotlight: deactivate `Show in Menu Bar`
- Siri: activate `Show in Menu Bar`
- Time Machine: activate `Show in Menu Bar`

#### Mission Control

I keep the defaults, i.e.:

- activate `Automatically rearrange Spaces based on most recent use`
- activate `When switching to an application, switch to a Space with open windows for the application`
- deactivate `Group windows by application`
- activate `Displays have separate Spaces`

I also keep the default keyboard shortcuts, i.e. only <kbd>CTRL</kbd>+<kbd>↑</kbd> for Mission Control and <kbd>CTRL</kbd>+<kbd>↓</kbd> for Application windows. I manage the mouse buttons with [Logi Options+](#logi-options+-free) so no need to change mouse buttons heren. Moreover, in *Hot Corners* I remove everything as I don't use `Quick note` on my mac.

#### Siri

- Activate `Enable Ask Siri`
- Deactivate `Listen for “Hey Siri”`
- Keyboard Shortcut: default (`hold mic`)
- Language: `German (Germany)`
- Siri Voice: `Voice 1`
- Voice Feedback: `On`
- Activate `Show Siri in menu bar`
- Sometimes, I do `Delete Siri & Dictation Histroy`, but mostly not
- Go through `Siri Suggestions & Privacy`

#### Spotlight

- Search Results: activate everything
- Privacy: don't add anything

#### Language & Region
General
- Preferred languages: Primary: `English (US)`, Secondary: `German (Germany)`
- Region: `Germany` which will change to `Germany (Custom)` once I changed the advanced settings below.
- Calendar: Gregorian
- Time format: 24-Hour Time
- Temperature: Celsius
- Live Text: Activate `Select Text in Images`
- Under the wheel: Click `Apply to Login Windows`
- Translation Languages: 
  - Download *English (US)* and *German (Germany)*
- Advanced:
  - General
    - Number separators: Grouping `,` Decimal `.`
    - Currency: Euro (€), Grouping `,` Decimal `.`
    - Measurement units: Metric
    - First day of week: Monday
    - List sort order: Universal
  - Dates & Times: I keep the defaults

Apps
- Money Money in German


#### Notifications & Focus (WIP)
- Go through if you really need the notifications and which kind
- Usually, I leave everything turned on and when something annoys me, I then go ahead and turn it off

#### Internet Accounts
I already checked this at the beginning; but again I go through each account and turn off/on the required services.

#### Passwords
I don't use this and so I make sure this is empty.

#### Wallet & Apple Pay
Check whether my credit card is correct. Otherwise, I set it up by clicking on *Add Card*.

#### Users & Groups
Willi Mutschler (Admin)
- Change your Avatar Picture and/or Password if needed
- Open Contacts Card and check whether the info is correct
- Go through “Login Items”

Guest user
- Make sure it is turned off

Login Options: I usually leave the defaults:
- Automatic login: `Off`
- Display login window as: `List of users`
- Activate `Show the Sleep, Restart, and Shut Down buttons`
- Deactivate `Show input menu in login window`
- Deactivate `Show password hints`
- Deactivate `Show fast user switching menu`
- I don't require any `Accessibility Options`
- I don't have any `Network Account Server` to join

#### Accessibility (WIP)
- I leave all the defaults

#### Screen Time (WIP)
- Turn On
- Check “Share across devices”
- Uncheck “Use Screen Time Passcode”

#### Extensions (WIP)
- Go through what you really need


#### Security & Privacy (WIP)
- General
    - Check “Require Password 5 Minutes after sleep or screen saver begins”
    - Allow apps downloaded from “App Store and identified developers”
    - Do I need System extensions????
- File Vault: Turn On
- Firewall: Turn Off
- Privacy: Go through everything and make your choice accordingly


#### Software Update
I do my updates on a weekly basis, so I don't need the Automatic features of macOS. Therefore:
- Uncheck “Automatically keep my Mac updated”
- Advanced
    - Check “Check for updates”
    - Uncheck “Download new updates when available”
    - Uncheck “Install macOS updates”
    - Uncheck “Install app updates from the App Store”
    - Uncheck “Install system data files and security updates”

#### Network
I set up two locations, one for home and one for my work, by hitting `duplicate location`. In each location I remove unused ones and change the order of the devices under `Set Service Order`. Particularly, I make sure that I have the following order: VPN, LAN, Wi-Fi, Tailscale. My Work location requires me to also set a certain IP address.

#### Bluetooth
- Turn On
- AirPods Pro `Options`
  - Switch `Connect to This Mac` to `When Last Connected to This Mac`.
  - Press & Hold AirPod: Siri

#### Sound
Sound Effects
  - Alert Sound: `Boop`
  - Play sound effects through `Selected sound output device`
  - Alert volume: `100%`
  - Uncheck `Play sound on startup`
  - Check `Play user interface sound effects`
  - Uncheck `Play feedback when volume is changed`
  - Output volume: `50%`
  - Uncheck `Show Sound in menu bar`

Output: Select your default device, for me it is Realtek USB2.0 Audio, and I set the volume to about 80%.

Input: Select your default device, for me it is MacBook Air Microphone, and I set the input volume to 75%.

#### TouchID
I `Add Fingerprint` for my other index finger. I also ask my wife to add her finger as well. I select everything under `Use Touch ID for`.


#### Keyboard (WIP)
Keyboard
  - Key Repeat: `7/8`
  - Delay Until Repeat: `3/6`
  - Check `Adjust keyboard brightness in low light`
  - Uncheck `Turn keyboard backlight off after 5 secs of inactivity`
  - Press Globe-key to `Show Emoji & Symbols`
  - Check `Use F1, F2 etc keys as standard function keys`
  - `Modifier keys`: keep defaults

Text
  - Replace “@@@“ with “@mutschler.eu” and remove other Text replace features
  - Uncheck `Correct spelling automatically`
  - Uncheck `Capitalise words automatically`
  - Uncheck `Add period with double-space`
    - Spelling: `Automatic by Language`
    - Uncheck `Use smart quotes and dashes`
- Shortcuts
    - Go through whether you are happy with the defaults
    - Uncheck “Use keyboard navigation to move focus between controls”
- Input Sources:
    - German
    - Uncheck “Show Input menu in menu bar”
- Dictation
    - Off
    - Language: English (United States)
    - Shortcut: Press mic key


#### Trackpad (WIP)
- Point & Click
    - Check “Look up & data detectors”
    - Check “Secondary click”
    - Check “Tap to click”
    - Click: Medium
    - Tracking speed: 4/10
    - Uncheck “Silent clicking”
    - Check “Force Click and haptic feedback”
- Scroll & Zoom
    - Check “Scroll direction: Natural”
    - Check “Zoom in or out”
    - Check “Smart zoom”
    - Check “Rotate”
- More Gestures
    - Check “Swipe between pages”
    - Check “Swipe between full-screen apps”
    - Check “Notification Center”
    - Check “Mission Control”
    - Uncheck “App Exposé”
    - Check “Launchpad”
    - Check “Show Desktop”

#### Mouse (WIP)


#### Displays (WIP)
- Display
    - Resolution: Default for display
    - Check "Automatically adjust brightness
    - Check True Tone
- Color: If you need, make changes to the Display profile (I don't)
- Night Shift
    - Schedule: Sunset to Sunrise
    - Color Temperature: Middle
- Check: Show mirroring options in the menu bar when available


#### Printers & Scanners (WIP)
- Click on the `+` and add your printer and set your Default printer and paper size


#### Battery
Battery
- Turn display off after: `20 min`
- Activate `Put hard disks to sleep when possible`
- Activate `Slightly dim the display while on battery power`
- Deactivate `Optimize video streaming while on battery`. If activated, then when you play high dynamic range (HDR) video while on battery power, the video will be played in standard dynamic range (SDR), which uses less energy.
- Activate `Optimized battery charging`
- Activate `Show battery status in menu bar`
- Deactivate `Low power mode`
- Check `Battery Health`: *Battery Condition: Normal* and *Maximum Capacity: 95%* after about 8 months of usage. Note that I use my MacBook Air mostly connected to a dock, except for presentations and when I am travelling.

Power Adapter
- Turn display off after: `20 min`
- Activate `Prevent your Mac from automatically sleeping when the display is off`
- Activate `Put hard disks to sleep when possible`
- Activate `Wake for network access` (important for iCloud and find my features)
- Deactivate `Low power mode`

Schedule
- Deactivate `Start up or wake`


#### Date & Time (WIP)
- Date & Time: Check "Set date and time automatically: Apple"
- Time Zone: Check "Set time zone automatically using current location"

#### Sharing (WIP)
- Computer Name: "MacBook Air von Willi"
- Service which I turn on:
    - Printer Sharing
Select my Work location (Apple-Location), I then enable Internet Sharing, i.e. I share from my LAN connection to computers using Wi-Fi. Under Wi-Fi Options I change the password. Double check in the Network preferences that if you change locations, that Wi-Fi is connected and not shared anymore.

#### Time Machine (WIP)
- Check "Back Up Automatically"
- Check "Show Time Machine in menu bar"
- Set up Time Machine by clicking "Select Backup Disk"
- Options: Check "Back up while on battery power"

#### Startup Disk (WIP)
no need to set anything

#### Profiles (WIP)
- I need to install the eduroam certificate of my university here

#### macFUSE (WIP)



## Update routine

### System updates
Click on the Apple symbol in the left corner, select `About this Mac`, then `Software Update` and check for new updates. 

### App Store
Open the AppStore and check which apps can be updated.

### Homebrew
Open terminal.app:
```sh
mbrew update
mbrew upgrade
mbrew autoremove

ibrew update
ibrew upgrade
ibrew autoremove
```


Keyboard settings: Use keyboard navigation to move focus between controls


## System extensions
To enable system extensions, you need to modify your security settings in the Recovery environment.
To do this, shut down your system, then press and hold the Touch ID or power button to launch Startup Security Utility. In Startup Security Utility, enable kernel extensions from the Security Policy button.


TRAY ICON AUFRÄUMEN