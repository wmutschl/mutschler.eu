---
title: 'Ubuntu Server 20.10 on Raspberry Pi 4: installation guide with USB Boot (no SD card) and full disk encryption (excluding /boot) using btrfs-inside-luks and auto-apt snapshots with Timeshift'
summary: In this guide I will walk you through the installation procedure to get an Ubuntu 20.10 system with a luks-encrypted partition for the root filesystem (excluding /boot) formatted with btrfs that contains a subvolume @ for / and a subvolume @home for /home running on a Raspberry Pi 4. The system is installed to an external bootable USB drive so no SD card is required. I will show how to optimize the btrfs mount options and how to get a headless server, i.e. remotely unlock the luks partition using Dropbear which enables one to use SSH to decrypt the luks-encrypted partitions after a reboot. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation.
#linktitle: Raspberry Pi Ubuntu Server 20.04 USB-boot-btrfs-luks
toc: true
type: book
#date: "2021-01-10"
draft: false
weight: 35
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***


## Overview 
Since 2020, I am exclusively using btrfs as filesystem on all my systems, see: [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Ubuntu Server 20.10 on a Raspberry Pi 4 with the following structure:

- an unencrypted boot partition to make the Pi boot completely from USB (no SD card required)
- a btrfs-inside-luks partition for the root filesystem (excluding `/boot`) containing a subvolume `@` mounted as `/` and a subvolume `@home`  mounted as `/home`
- headless server: remote unlocking using Dropbear (passphrase prompt via dedicated SSH login on different port)
- automatic system snapshots and easy rollback similar to *zsys* using:
   - [Timeshift](https://github.com/teejee2008/timeshift) which will regularly take (almost instant) snapshots of the system
   - [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) which will automatically run Timeshift on any apt operation and also keep a backup of your boot partition inside the snapshot   

With this setup you basically get the same comfort of Ubuntu's 20.10's ZFS and *zsys* initiative, but with much more flexibility and comfort due to the awesome [Timeshift](https://github.com/teejee2008/timeshift) program, which saved my bacon quite a few times. This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).

This tutorial is most likely not the fastest way to achieve this, but it works for me and once everything is set up, you never have to go through it again (unless you get another Raspberry Pi of course;-) ).

## Tested environment
- Raspberry Pi 4 4GB
- Ubuntu Server 20.10
- Drives
  - Samsung T5 portable SSD (1 TB)
  - LaCie Porsche Design Mobile Drive (2TB)


## Step 0 (optional): Enable USB Boot on Raspberry Pi 4
Depending on when your Raspberry Pi 4 was manufactured, the bootloader EEPROM may need to be updated to enable booting from USB mass storage devices. I followed this [USB mass storage boot guide](https://www.raspberrypi.org/documentation/computers/raspberry-pi.html#usb-mass-storage-boot) to update my EEPROM, there is also an official [Ubuntu (optional) USB Boot guide](https://ubuntu.com/tutorials/how-to-install-ubuntu-desktop-on-raspberry-pi-4#4-optional-usb-boot). Note that you need to do this only once, afterwards your Pi will always be able to boot from USB.

## Step 1: Flash Ubuntu Server 20.10 on an external USB drive
In this tutorial we flash [Ubuntu Server 20.10 for Raspberry Pi](https://ubuntu.com/raspberry-pi) to an external USB 3.0 drive. To download and flash the image I first installed the [Raspberry Pi Imager](https://snapcraft.io/rpi-imager) from the snap store (`sudo snap install rpi-imager`). On my Fedora machine I had to switch, temporarily, from *Wayland* to *Gnome on Xorg* to run it. Then select the following:
- `CHOOSE OS` -> Other general purpose OS -> Ubuntu -> Ubuntu Server 20.10 (RPi 3/4/400) 64-bit server OS for arm64 architectures
- `CHOOSE SD CARD`: Your external USB 3.0 drive

In short, instead of selecting the SD card I am simply choosing my external USB drive instead. If you cannot do that for some reason, you can always [directly flash the image](https://www.raspberrypi.org/documentation/installation/installing-images/) to your USB drive or copy it over from a SD card.


## Step 2: Prepare partitions manually
By default the partition scheme looks like this (my external USB drive is named *sdb*, look for *system-boot* and *writable* in the `blkid` output):
```sh
sudo blkid
# /dev/sdb1: LABEL_FATBOOT="system-boot" LABEL="system-boot" UUID="2EC5-A982" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="254a9658-01"
# /dev/sdb2: LABEL="writable" UUID="c21fdada-1423-4a06-be66-0b9c02860d1d" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="254a9658-02"

sudo parted /dev/sdb print
# Model: LaCie P9227 Slim (scsi)
# Disk /dev/sdb: 2000GB
# Sector size (logical/physical): 512B/4096B
# Partition Table: msdos
# Disk Flags: 
# 
# Number  Start   End     Size    Type     File system  Flags
 # 1      1049kB  269MB   268MB   primary  fat32        boot, lba
 # 2      269MB   3348MB  3079MB  primary  ext4
```
If you would now boot from the drive, the second partition would expand on first boot to take over all space. One would then need to manually shrink it and move files around. To make life a bit easier, we will leave some space after the second partition and create a third partition which will actually contain our LUKS encrypted root btrfs filesystem and re-use the second partition for something else (e.g. [encrypted swap](../ubuntu-btrfs/#encrypted-swap) or an [encrypted dedicated docker image partition](../raspi-post-install/#option-a-create-dedicated-encrypted-docker-image-partition)) later on. With btrfs I do not need any other partitions for e.g. `/home`, as we will use subvolumes instead. 


Let's use `parted` for this (feel free to use `gparted` accordingly):
```bash
sudo parted /dev/sdb mkpart primary 5000MiB 100%
sudo parted /dev/sdb print
# Model: LaCie P9227 Slim (scsi)
# Disk /dev/sdb: 2000GB
# Sector size (logical/physical): 512B/4096B
# Partition Table: msdos
# Disk Flags: 
# 
# Number  Start   End     Size    Type     File system  Flags
#  1      1049kB  269MB   268MB   primary  fat32        boot, lba
#  2      269MB   3348MB  3079MB  primary  ext4
#  3      5243MB  2000GB  1995GB  primary
```
Note that the third partition starts at 5243MB, so my second partition will have a size of 5243MB-268MB=4975MB once the second partition gets extended on first boot.

## Step 3: Create LUKS partition and btrfs root filesystem
The Raspberry Pi 4 doesn't have hardware-accelerated AES support, so encryption is usually not very fast. [Google's Adiantum algorithm performs better on ARM](https://security.googleblog.com/2019/02/introducing-adiantum-encryption-for.html) so we use it for our LUKS partition:
```sh
sudo cryptsetup luksFormat --type=luks2 -c xchacha20,aes-adiantum-plain64 /dev/sdb3
# WARNING!
# ========
# This will overwrite data on /dev/sdb3 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/sdb3: 
# Verify passphrase:
```
Use a very good password here. Now map the encrypted partition to a device called `crypt_raspi`, which will be our root filesystem:

```bash
sudo cryptsetup luksOpen /dev/sdb3 crypt_raspi
# Enter passphrase for /dev/sdb3:
ls /dev/mapper/
# control ... crypt_raspi
```

Now let's format `crypt_raspi` with the btrfs filesystem:

```bash
sudo mkfs.btrfs /dev/mapper/crypt_raspi
# btrfs-progs v5.9 
# See http://btrfs.wiki.kernel.org for more information.
# 
# Label:              (null)
# UUID:               b220ee50-3511-4cfe-8988-fa2d4dedf677
# Node size:          16384
# Sector size:        4096
# Filesystem size:    1.81TiB
# Block group profiles:
#   Data:             single            8.00MiB
#   Metadata:         DUP               1.00GiB
#   System:           DUP               8.00MiB
# SSD detected:       no
# Incompat features:  extref, skinny-metadata
# Runtime features:   
# Checksum:           crc32c
# Number of devices:  1
# Devices:
#    ID        SIZE  PATH
#     1     1.81TiB  /dev/mapper/crypt_raspi

sudo cryptsetup luksClose crypt_raspi
```
Note that for an external SSD drive, like my Samsung Portable SSD T5, the SSD should be detected by btrfs automatically. Disconnect the external usb drive and connect it to your Pi.

## Step 4: Boot your Raspberry Pi and SSH into it
Before you boot your Pi, make sure that it is either connected to an HDMI display and you have Keyboard access to it or you are using it headless via SSH, i.e. by connecting it to your network either with [Wi-Fi or Ethernet](https://ubuntu.com/tutorials/how-to-install-ubuntu-on-your-raspberry-pi#3-wifi-or-ethernet). 

In all the following steps I will focus on the SSH way as I am connecting my Pi via ethernet (acutally I am also connecting a display just in case) so I can now plug in the USB drive and boot from it. If you need to set up Wi-Fi, check out the linked guide above. In any case, you need to find out the ip address of your pi (e.g. in your router). I have dedicated 192.168.178.50 (or ubuntu.fritz.box) to the Raspberry pi in the admin interface of my router. You can find out the ip by running either of these two commands on your computer (which should also be connected to the same network of course):
```sh
arp -na | grep -i "b8:27:eb"
arp -na | grep -i "dc:a6:32"
# ? (192.168.178.50) at dc:a6:32:d3:da:c2 [ether] on enp12s0u1u2
```
Note that the first boot might take a couple of minutes before the Pi's SSH server is up and running. Now let's SSH into it and change the default password `ubuntu` to one of your choice:

```sh
ssh ubuntu@192.168.178.50
# The authenticity of host '192.168.178.50 (192.168.178.50)' can't be established.
# ECDSA key fingerprint is SHA256:JrZAxm31CLs4ECU8BK9KsctGZciwO5xpcU7VdKDI/G8.
# Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
# Warning: Permanently added '192.168.178.50' (ECDSA) to the list of known hosts.
# ubuntu@192.168.178.50's password: 
# You are required to change your password immediately (administrator enforced)
# Welcome to Ubuntu 20.10 (GNU/Linux 5.8.0-1006-raspi aarch64)
# .....
# .....
# WARNING: Your password has expired.
# You must change your password now and login again!
# Changing password for ubuntu.
# Current password: 
# New password: 
# Retype new password: 
# passwd: password updated successfully
# Connection to 192.168.178.50 closed.
```
Reconnect using your newly created password:
```sh
ssh ubuntu@192.168.178.50
```

## Step 5: Update your Raspberry Pi system
```sh
sudo apt update
sudo apt upgrade
sudo apt autoremove
sudo snap refresh
sudo reboot now
```
Wait a short while and SSH back into your system; recheck if there are any further updates. If so, then install them and reboot again. If not, then power down your Pi
```sh
sudo shutdown now
```
and remove the USB drive from your Pi.

## Step 6: Create subvolumes (@ and @home) and rsync system and home files
Plug the USB drive back into your computer. You might get prompts from your file manager to mount the LUKS partition, cancel these prompts. Find out the name of your USB drive (look at `LABEL_FATBOOT="system-boot"` and `LABEL="writable"`), for me it is again `sdb`, and have a look at the partition table:
```sh
sudo blkid
# /dev/sdb1: LABEL_FATBOOT="system-boot" LABEL="system-boot" UUID="2EC5-A982" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="254a9658-01"
# /dev/sdb2: LABEL="writable" UUID="c21fdada-1423-4a06-be66-0b9c02860d1d" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="254a9658-02"
# /dev/sdb3: UUID="cd2b99fd-11c1-423f-b07b-44f704da1599" TYPE="crypto_LUKS" PTTYPE="atari" PARTUUID="254a9658-03"

sudo parted /dev/sdb print
# Model: LaCie P9227 Slim (scsi)
# Disk /dev/sdb: 2000GB
# Sector size (logical/physical): 512B/4096B
# Partition Table: msdos
# Disk Flags: 
# 
# Number  Start   End     Size    Type     File system  Flags
#  1      1049kB  269MB   268MB   primary  fat32        boot, lba
#  2      269MB   5243MB  4973MB  primary  ext4
#  3      5243MB  2000GB  1995GB  primary
```
Note that the second partition `sdb2` has been resized and contains the ext4 filesystem with the system files (the Pi's `/` and `/home` directories); whereas `sdb3` contains our btrfs-luks partition with the remaining space.

Now, let's map the btrfs-luks partition to a device called `crypt_raspi` and mount this to `/mnt/btrfs`. Also, we'll mount the ext4 partition to `/mnt/ext4`:
```sh
sudo mkdir -p /mnt/btrfs
sudo cryptsetup luksOpen /dev/sdb3 crypt_raspi
# Enter passphrase for /dev/sdb3:
sudo mount /dev/mapper/crypt_raspi /mnt/btrfs

sudo mkdir -p /mnt/ext4
sudo mount /dev/sdb2 /mnt/ext4
```
Let's create two subvolumes: `@` for the `/` directory and `@home` for the `/home` directory:
```sh
sudo btrfs subvolume create /mnt/btrfs/@
sudo btrfs subvolume create /mnt/btrfs/@home
```
Rsync to copy all files from the ext4 partition into our `@` and `@home` subvolumes:
```sh
sudo rsync -avhP /mnt/ext4/ /mnt/btrfs/@/
sudo mv /mnt/btrfs/@/home/ubuntu /mnt/btrfs/@home/ubuntu
sudo sync && sync #make sure everything is written to disk
```
Note that the home directories reside in the `@home` subvolume. This might take a little while depending on the speed of your drive. Unmount and clean-up on your computer:
```sh
sudo umount /mnt/btrfs
sudo umount /mnt/ext4
sudo cryptsetup luksClose crypt_raspi
sudo rmdir /mnt/btrfs
sudo rmdir /mnt/ext4
```
Unplug the USB drive from your computer.

## Step 7: Create a chroot environment on your Pi using the @ subvolume
Plug the USB drive back into your Pi, boot it and SSH into your Pi. Find out the name of your drive (usually `sda`):
```sh
sudo blkid
# /dev/sda2: LABEL="writable" UUID="c21fdada-1423-4a06-be66-0b9c02860d1d" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="254a9658-02"
# /dev/loop0: TYPE="squashfs"
# /dev/loop1: TYPE="squashfs"
# /dev/loop2: TYPE="squashfs"
# /dev/loop3: TYPE="squashfs"
# /dev/loop4: TYPE="squashfs"
# /dev/loop5: TYPE="squashfs"
# /dev/sda1: LABEL_FATBOOT="system-boot" LABEL="system-boot" UUID="2EC5-A982" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="254a9658-01"
# /dev/sda3: UUID="cd2b99fd-11c1-423f-b07b-44f704da1599" TYPE="crypto_LUKS" PTTYPE="atari" PARTUUID="254a9658-03"
```

Unlock your LUKS partition, map it to `crypt_raspi` and mount the `@` subvolume to `/mnt`:
```sh
sudo cryptsetup luksOpen /dev/sda3 crypt_raspi
sudo mount -o subvol=@ /dev/mapper/crypt_raspi /mnt
```
Create a chroot (change-root) environment to work directly from the `@` subvolume on your Pi:
```sh
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo chroot /mnt
```
You have now root access from your `@` subvolume as `/`. We now need to adapt the mount points correctly and enable the system to boot from the encrypted partition.

## Step 8: Make changes to fstab, crypttab and cmdline.txt
Let's make some changes to `/etc/fstab` to always
- mount `/` to the `@` subvolume inside `crypt_raspi`
- mount `/home` to the `@home` subvolume inside `crypt_raspi`
- mount the boot partition to `/boot/firmware`

Use either these `sed` and `echo` commands or open `/etc/fstab` in a text editor (e.g. nano) directly:
```sh
sed -i '\|^LABEL=writable|d' /etc/fstab #this removes any lines starting with LABEL=writable
echo "/dev/mapper/crypt_raspi  /               btrfs   defaults,subvol=@       0       0" >> /etc/fstab
echo "/dev/mapper/crypt_raspi  /home           btrfs   defaults,subvol=@home   0       0" >> /etc/fstab
```
Either way, your fstab should look like this:
```sh
cat /etc/fstab
# LABEL=system-boot       /boot/firmware  vfat    defaults        0       1
# /dev/mapper/crypt_raspi  /               btrfs   defaults,subvol=@       0       0
# /dev/mapper/crypt_raspi  /home           btrfs   defaults,subvol=@home   0       0

```
Now we can mount everything:
```sh
mount -av
# /boot/firmware           : successfully mounted
# /                        : ignored
# /home                    : successfully mounted
```
We need to tell the system where our `crypt_raspi` resides, so edit the `/etc/crypttab` file:
```sh
echo "crypt_raspi  /dev/sda3   none   luks" >> /etc/crypttab
cat /etc/crypttab
# crypt_raspi  /dev/sda3   none   luks
```

Lastly, we need to change the kernel parameters in `/boot/firmware/cmdline.txt`:

- Change `root=LABEL=writable` to `root=/dev/mapper/crypt_raspi rootflags=subvol=@`
- Change `rootfstype=ext4` to `rootfstype=btrfs`
- Add `cryptdevice=/dev/sda3:crypt_raspi` to the end of the line
- Remove `quiet` and `splash` (always good on a server)

So, use these `sed` commands or open the file in a texteditor:
```sh
cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.orig

sed -i "s|root=LABEL=writable|root=/dev/mapper/crypt_raspi rootflags=subvol=@|" /boot/firmware/cmdline.txt
sed -i "s|ext4|btrfs|" /boot/firmware/cmdline.txt
sed -i "s|quiet splash|cryptdevice=/dev/sda3:sdcard|" /boot/firmware/cmdline.txt

cat /boot/firmware/cmdline.txt
#dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mapper/crypt_raspi rootflags=subvol=@ rootfstype=btrfs elevator=deadline rootwait fixrtc cryptdevice=/dev/sda3:crypt_raspi
```
Very importantly, make the initramfs image aware of these changes:
```sh
update-initramfs -c -k all
```
If you have a display connected, and first want to check whether you are able to boot from your encrypted LUKS partition, then exit the chroot and reboot now:
```sh
exit
sudo reboot now
```
Alternatively, if you want to be able to remotely unlock your LUKS drive via a Dropbear SSH server, do the next step first in the chroot. Of course, you can always do Step 9 later after you booted into your system.

## Step 9 (optional): Remote unlocking using Dropbear SSH
For headless installations it is useful to have the ability to enter the LUKS passphrase remotely via SSH. We will install a [Dropbear SSH server](https://matt.ucc.asn.au/dropbear/dropbear.html) for the sole purpose of unlocking your LUKS partition. I have a dedicated SSH key for unlocking via Dropbear. So on my computer I have created a dedicated SSH key and stored it in a file `id_dropbear`:
```sh
ssh-keygen -t rsa -f ~/.ssh/id_dropbear -C dropbear # do this only once

# WRITE DOWN OR COPY YOUR PUBLIC KEY IN THE CLIPBOARD
cat ~/.ssh/id_dropbear.pub
# ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHZ8L+RCQnqmXTqhfqKmpM8F/E4edFhLgclpbqi9V5dKTuuaFFkkLsRrPbWkYGxQPpYqNUcVsbOisnJKIL5WRV9TvXBqcIhT84BwDdrFEnP9DoTj6eidHUU7AOjfqJ1E0plX5j+yixKK6jW5A4CHDHPcCq3iFmprZOMkrTP2WctzNu9qfe6mP2+9CFN5MWFsEiU137865LVLMwApp9BM4eTX9k+TZi7wD7AagfYEP+GTFTGwA7+OwjBbl4jZlRnD31uRcMour+qjd7VKhEB1m9L26fWzj/lT83Sj/SCHekbpO3Yvv2LKUlnd8dW4y/Eo883ZWx5A6C5IwWDF/ruOR/ dropbear
```
Note that ed25519 keys are not supported. 

On your Pi, make sure you are in an interactive root mode (if you are still in the chroot environment, skip this):
```sh
sudo -i
```
Next install Dropbear:
```sh
apt install dropbear-initramfs
```
Add your dedicated public key (`/home/$USER/.ssh/id_dropbear.pub` on my computer) to `/etc/dropbear-initramfs/authorized_keys`:
```sh
echo 'no-port-forwarding,no-agent-forwarding,no-x11-forwarding,command="/bin/cryptroot-unlock" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHZ8L+RCQnqmXTqhfqKmpM8F/E4edFhLgclpbqi9V5dKTuuaFFkkLsRrPbWkYGxQPpYqNUcVsbOisnJKIL5WRV9TvXBqcIhT84BwDdrFEnP9DoTj6eidHUU7AOjfqJ1E0plX5j+yixKK6jW5A4CHDHPcCq3iFmprZOMkrTP2WctzNu9qfe6mP2+9CFN5MWFsEiU137865LVLMwApp9BM4eTX9k+TZi7wD7AagfYEP+GTFTGwA7+OwjBbl4jZlRnD31uRcMour+qjd7VKhEB1m9L26fWzj/lT83Sj/SCHekbpO3Yvv2LKUlnd8dW4y/Eo883ZWx5A6C5IwWDF/ruOR/ dropbear' >> /etc/dropbear-initramfs/authorized_keys
```
Note that `no-port-forwarding,no-agent-forwarding,no-x11-forwarding,command="/bin/cryptroot-unlock"` restricts this SSH access to only run `/bin/cryptroot-unlock` and then close the SSH session. Moreover, I am changing the port for the Dropbear server to 4444 in `/etc/dropbear-initramfs/config` (add/uncomment `DROPBEAR_OPTIONS="-p 4444"`):

```sh
sed -i 's|#DROPBEAR_OPTIONS=|DROPBEAR_OPTIONS="-p 4444"|' /etc/dropbear-initramfs/config

cat /etc/dropbear-initramfs/config
# DROPBEAR_OPTIONS="-p 4444"
```
Don't forget to update the initramfs:
```sh
update-initramfs -u -k all
```
Now it is time to exit the chroot environment
```sh
exit
```
and reboot:
```sh
sudo reboot now
```

If you have a display connected, you should see 
```sh
Please unlock disk crypt_raspi:
# ...
# some other output
# ...
Begin: Starting dropbear:
```

Now from your computer use the dedicated SSH identity to access the Dropbear SSH server:
```sh
ssh -i ~/.ssh/id_dropbear root@192.168.178.50 -p4444
# Please unlock disk crypt_raspi:
# Connection to 192.168.178.50 closed.
```
If something goes wrong, simply connect a USB keyboard to your Pi and carefully type in your LUKS passphrase and hit Enter. This will also unlock your LUKS partition and boot into your system.



## Step 10: Some checks
Once the Pi booted and you entered your LUKS passphrase either remotely or directly, SSH into your system and check whether everything is working as it should:

```sh
sudo cat /etc/crypttab
# crypt_raspi  /dev/sda3   none   luks

sudo cat /etc/fstab
# LABEL=system-boot        /boot/firmware  vfat    defaults                0       1
# /dev/mapper/crypt_raspi  /               btrfs   defaults,subvol=@       0       0
# /dev/mapper/crypt_raspi  /home           btrfs   defaults,subvol=@home   0       0

sudo mount -av
# /boot/firmware           : already mounted
# /                        : ignored
# /home                    : already mounted

sudo mount -v | grep /dev/mapper
# /dev/mapper/crypt_raspi on / type btrfs (rw,relatime,space_cache,subvolid=257,subvol=/@)
# /dev/mapper/crypt_raspi on /home type btrfs (rw,relatime,space_cache,subvolid=258,subvol=/@home)

sudo btrfs filesystem show /
# Label: none  uuid: 0ba938bc-9f6a-4b2f-b978-c10b3528d17c677
#         Total devices 1 FS bytes used 2.47GiB
#         devid    1 size 1.81TiB used 5.02GiB path /dev/mapper/crypt_raspi

sudo btrfs subvolume list /
# ID 257 gen 57 top level 5 path @
# ID 258 gen 51 top level 5 path @home
```
Look's good. Let's check again for updates and reboot one more time:

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
sudo reboot now
```


## Step 11 (optional): Optimize btrfs mount options

### HDD and SSD
I have found that there is *some* general agreement to use the following mount options:

- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate.
- Lastly the pass flag for fschk in the `fstab` is useless for btrfs and should be set to 0.

So add these options to your btrfs subvolume mount points in your fstab:
```sh
sudo nano /etc/fstab
# LABEL=system-boot        /boot/firmware  vfat    defaults                                                             0       1
# /dev/mapper/crypt_raspi  /               btrfs   defaults,noatime,space_cache,commit=120,compress=zstd,subvol=@       0       0
# /dev/mapper/crypt_raspi  /home           btrfs   defaults,noatime,space_cache,commit=120,compress=zstd,subvol=@home   0       0
# /dev/mapper/crypt_raspi  /btr_pool       btrfs   defaults,noatime,space_cache,commit=120,compress=zstd,subvolid=5     0       0
sudo mkdir -p /btr_pool
sudo mount -a
```
Note that I also add a mountpoint `/btr_pool` for the btrfs root filesystem (this has always id 5) for easy access of all my subvolumes. You would need to restart to make use of the new options. Also compression is not used on already available files, but only for new or changed files.

### SSD-specific
If you are using a SSD, don't forget to **additionally** add the following mount options to your `/etc/fstab`:
- `ssd`: use SSD specific options for optimal use on SSD and NVME (if you have one)
- `discard=async`: [Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard)

Moreover, to use the discard support in btrfs we need to pass it on in `/etc/crypttab`:
```sh
sudo nano /etc/crypttab
# crypt_raspi /dev/sda3 none luks,discard
```
As [both fstrim and discard=async mount option can peacefully co-exist](https://www.phoronix.com/scan.php?page=news_item&px=Fedora-Btrfs-Opts-Discard-Comp), I also enable `fstrim.timer`:
```sh
sudo systemctl enable fstrim.timer
```

### Check mount options
Reboot and see which mount options are active:

```sh
sudo mount -v | grep /dev/mapper
# /dev/mapper/crypt_raspi on / type btrfs (rw,noatime,compress=zstd:3,space_cache,commit=120,subvolid=256,subvol=/@)
# /dev/mapper/crypt_raspi on /btr_pool type btrfs (rw,noatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/)
# /dev/mapper/crypt_raspi on /home type btrfs (rw,noatime,compress=zstd:3,space_cache,commit=120,subvolid=258,subvol=/@home)
```

## Step 12: Install Timeshift and Timeshift-autosnap-apt

### Timeshift
```bash
sudo apt install timeshift
sudo timeshift --btrfs
# First run mode (config file not found)
# Selected default snapshot type: BTRFS
# App config loaded: /etc/timeshift.json
# Mounted '/dev/dm-0 (sda3)' at '/run/timeshift/backup'
# Selected default snapshot device: /dev/dm-0
# App config saved: /etc/timeshift.json

echo $(blkid -s UUID -o value /dev/mapper/crypt_raspi)
# 0ba938bc-9f6a-4b2f-b978-c10b3528d17c
echo $(blkid -s UUID -o value /dev/sda3)
# cd2b99fd-11c1-423f-b07b-44f704da1599
```
Let's edit the configuration file (`/etc/timeshift.json`) of Timeshift. For this, use the UUID of `/dev/mapper/crypt_raspi` for `backup_device_uuid` and of `/dev/sda3` for `parent_device_uuid` (actually as we ran Timeshift with the `--btrfs` flag this should be autodetected). Mine looks like this:
```json
{
  "backup_device_uuid" : "0ba938bc-9f6a-4b2f-b978-c10b3528d17c",
  "parent_device_uuid" : "cd2b99fd-11c1-423f-b07b-44f704da1599",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "true",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "btrfs_use_qgroup" : "true",
  "schedule_monthly" : "true",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "true",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [
  ],
  "exclude-apps" : [
  ]
}
```

You can create your first snapshot now:
```sh
sudo timeshift --create --comments "First snapshot"
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-51-54
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-51-54/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-51-54/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-51-54/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2021-01-11_12-51-54': ondemand
# ------------------------------------------------------------------------------
# E: ERROR: can't list qgroups: quotas not enabled
# 
# E: btrfs returned an error: 256
# E: Failed to query subvolume quota
# Enabled subvolume quota support
# Added cron task: /etc/cron.d/timeshift-hourly

sudo timeshift --list
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Device : /dev/dm-0 (sda3)
# UUID   : 0ba938bc-9f6a-4b2f-b978-c10b3528d17c
# Path   : /run/timeshift/backup
# Mode   : BTRFS
# Status : OK
# 1 snapshots, 2.0 TB free
# 
# Num     Name                 Tags  Description     
# ------------------------------------------------------------------------------
# 0    >  2021-01-11_12-51-54  O     First snapshot 

sudo timeshift --create --comments "Second snapshot"
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-54-13
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-54-13/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-54-13/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_12-54-13/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2021-01-11_12-54-13': ondemand
# ------------------------------------------------------------------------------

sudo timeshift --list
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Device : /dev/dm-0 (sda3)
# UUID   : 0ba938bc-9f6a-4b2f-b978-c10b3528d17c
# Path   : /run/timeshift/backup
# Mode   : BTRFS
# Status : OK
# 2 snapshots, 2.0 TB free
# 
# Num     Name                 Tags  Description      
# ------------------------------------------------------------------------------
# 0    >  2021-01-11_12-51-54  O     First snapshot   
# 1    >  2021-01-11_12-54-13  O     Second snapshot 
```
Note that the cron job and btrfs quotas are enabled on first run, so don't worry about the `qgroups: quotas not enabled` error. Timeshift will now check every hour if snapshots (“hourly”, “daily”, “weekly”, “monthly”, “boot”) need to be created or deleted. Note that “boot” snapshots will not be created directly but about 10 minutes after a system startup. I also include the `@home` subvolume (which is not selected by default). Note that when you restore a snapshot you can always choose whether or not you also want to restore @home (which in most cases you don't want to).

Timeshift puts all snapshots into `/run/timeshift/backup/timeshift-btrfs`. Conveniently, the real root (subvolid 5) of your btrfs partition is also mounted to `/run/timeshift/backup`, so it is easy to view, create, delete and move around snapshots manually.

### Timeshift-autosnap-apt
Open a terminal and install some dependencies:
```bash
sudo apt install -y btrfs-progs git make
```
Now let’s install [Timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) from GitHub:
```sh
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt
cd /home/$USER/timeshift-autosnap-apt
sudo make install
```
After this, make changes to the configuration file:
```sh
sudo nano /etc/timeshift-autosnap-apt.conf
```
For example, as we don’t have a dedicated `/boot/efi` partition, we should set `snapshotEFI=false` in the configuration file. Check if everything is working:
```sh
sudo timeshift-autosnap-apt
# Rsyncing /boot into the filesystem before the call to timeshift.
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_13-00-39
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_13-00-39/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_13-00-39/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-01-11_13-00-39/info.json
# BTRFS Snapshot saved successfully (9s)
# Tagged snapshot '2021-01-11_13-00-39': ondemand
# ------------------------------------------------------------------------------

sudo timeshift --list
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,space_cache,commit=120,subvolid=5,subvol=/
# 
# Device : /dev/dm-0 (sda3)
# UUID   : 0ba938bc-9f6a-4b2f-b978-c10b3528d17c
# Path   : /run/timeshift/backup
# Mode   : BTRFS
# Status : OK
# 3 snapshots, 2.0 TB free
# 
# Num     Name                 Tags       Description                                            
# ------------------------------------------------------------------------------
# 0    >  2021-01-11_12-51-54  O H D W M  First snapshot                                         
# 1    >  2021-01-11_12-54-13  O          Second snapshot                                        
# 2    >  2021-01-11_13-00-39  O          {timeshift-autosnap-apt} {created before call to APT} 
```
Now, if you run any `sudo apt install|remove|upgrade|dist-upgrade` command, *Timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift*.


## Step 13: Decide what to do with second ext4 partition
Now as everything is up and running from `/dev/mapper/crypt_raspi` on `/dev/sda3`, we don't have any use for `/dev/sda2` anymore. So, either let it be, delete it, or use it as an [encrypted swap partition](../ubuntu-btrfs/#encrypted-swap) or (what I do) as an [encrypted docker image partition](../raspi-post-install/#option-a-create-dedicated-encrypted-docker-image-partition).

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**

*If you want more, check out my [Raspberry Pi post installation steps](../raspi-post-install)*

*If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift/).*


## Troubleshooting
For troubleshooting, always connect a display. Note that we removed quiet and splashed, so you should get a verbose output.

#### Fails to boot, fails to unlock LUKS, boots into Initramfs:
If the Raspberry Pi fails to boot and enters `(initramfs)`, this is usally due to the fact that the initramfs hasn't been updated yet|correctly.

So, decrypt your LUKS partition directly from initramfs:
```sh
(initramfs) cryptsetup luksOpen /dev/sda3 crypt_raspi
# Continue booting...   (initramfs) exit
```
If your passphrase is wrong, double-check whether your passphrase is compatible with the US Layout of the keyboard!

Log into your system and rewrite the initramfs (there shouldn't be any errors):
```sh
sudo update-initramfs -c -k all
sudo reboot now
```
After another reboot there should be a prompt for the passphrase. 