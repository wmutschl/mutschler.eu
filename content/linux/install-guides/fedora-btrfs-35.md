---
title: 'DRAFT: Fedora Workstation 35: installation guide with btrfs-luks full disk encryption (optionally including /boot) and automatic btrfs snapshots and backups with BTRBK'
#linktitle: Fedora 35 btrfs-luks
#summary: In this guide I will walk you through the installation procedure to get a Fedora workstation 35 system with a luks-encrypted partition for the root filesystem (optionally including /boot) formatted with btrfs. I will show how to optimize the btrfs mount options and, in case /boot is on the encrypted partition, how to add a key-file to type the luks passphrase only once. BTRBK is then used and configured to regularly take both btrfs snapshots of the system as well as send/receive those snapshots to a backup disk. 
toc: true
type: book
#date: "2021-12-14"
draft: false
weight: 46
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***

## Overview 

Since Fedora switched their default filesystem to btrfs I decided to give it a go as I am exclusively using btrfs on all my systems, see: [Why I (still) like btrfs](../../btrfs/). Fedora's automatic installation routine with encryption is actually almost perfect for me except some changes regarding the btrfs mount options.

So, in this guide I will show how to install Fedora 35 with the following structure:

- an unencrypted EFI partition for the GRUB bootloader
- a btrfs-inside-luks partition for the root filesystem containing the default subvolumes `root` for `/` and `home` for `/home`.[^1]
- there is no need for a swap partition as Fedora creates a [SwapOnZram](https://fedoraproject.org/wiki/Changes/SwapOnZRAM) during start-up
- automatic system snapshots and backups using [BTRBK](https://github.com/digint/btrbk) which will regularly take (almost instant) btrfs snapshots of the system and send/receive these to a backup disk given a chosen retention policy.
- Optionally, I will also show how to encrypt the `/boot` partition, so you get a full-disk-encryption-system (including `/boot`) and only one passphrase prompt from GRUB.
   
[^1]: Note that in a previous guide for [Fedora 33](../fedora-btrfs-33) I showed how to rename the subvolumes to `@` and `@home` in order to make [Timeshift](https://github.com/teejee2008/timeshift) work properly. However, in this guide, I will focus on BTRBK instead of Timeshift as it provides an automatic way to not only make snapshots (like Timeshift) but also to make backups to another disk via btrfs send/receive.

**If you ever need to rollback your system, checkout [Restoring backups with BTRBK](https://github.com/digint/btrbk#restoring-backups).**


## Step 0: General remarks
**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**

So, let's spin up a virtual machine with 4 cores, 8 GB RAM, and a 64GB disk using e.g. the awesome [quickemu](https://github.com/quickemu-project/quickemu) project. I can confirm that the installation works equally well on my Dell XPS 13 9360 and my Dell Precision 7520. In the following, however, I outline the steps for my Dell Precision 7520 with a NVME drive which I use for the system files and another SSD which is used for btrfs backups.

This tutorial is made with Fedora 35 Workstation from https://getfedora.org/de/workstation/download/ copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor).


## Step 1: Graphical installer with automatic configuration and encryption
Boot the installation medium in UEFI mode and choose `Install to Hard Drive`. Choose your language, Keyboard, Time & Date setting. Note that the `Done` button is in the top left corner. Then hit `Installation Destination`. Choose your harddisk and

- select `Automatic` under `Storage Configuration`
- `Encrypt my data` under `Encryption`

Click `Done` and enter your disk encryption passphrase, choose a good one. If there is still data on your disk, you need to choose `Reclaim space` and remove existing file systems that you don't need anymore. I usually hit `Delete all`. After you've finished select `Reclaim space`. You will return to the Installation Summary screen. Click `Begin Installation` (in the lower right corner). When the installation process is finished, select `Finish Installation`. Reboot your system and go through the welcome screen. I also enable `Third-party repositories` already.

Let's update the system (either via software center or the terminal):

```sh
sudo dnf upgrade
flatpak update
```

Reboot one more time:
```sh
sudo reboot now
```

## Step 2 (optional): Understand the partition layout and installation structure
This is just for your nerdy side if you want to familiarize yourself with some commands that are useful when working with btrfs, partition layouts, and mount points.

So, let's open a terminal and have a look on the default partition layout:
```sh
sudo lsblk
# NAME                                          MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
# sda                                             8:0    0 465.8G  0 disk  
# └─sda1                                          8:1    0 465.8G  0 part  
# zram0                                         252:0    0     8G  0 disk  [SWAP]
# nvme0n1                                       259:0    0 476.9G  0 disk  
# ├─nvme0n1p1                                   259:1    0   600M  0 part  /boot/efi
# ├─nvme0n1p2                                   259:2    0     1G  0 part  /boot
# └─nvme0n1p3                                   259:3    0 475.4G  0 part  
#   └─luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac 253:0    0 475.3G  0 crypt /home
                                                                         /
sudo parted /dev/nvme0n1 unit MiB print
# Model: PM961 NVMe SAMSUNG 512GB (nvme)
# Disk /dev/nvme0n1: 488386MiB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# 
# Number  Start    End        Size       File system  Name                  Flags
#  1      1.00MiB  601MiB     600MiB     fat32        EFI System Partition  boot, esp
#  2      601MiB   1625MiB    1024MiB    ext4
#  3      1625MiB  488386MiB  486761MiB

sudo blkid
# /dev/nvme0n1p3: UUID="8bf48ffa-78e1-4a16-ad9e-301b7199d8ac" TYPE="crypto_LUKS" PARTUUID="16845b99-3bf4-4b22-9afb-095a16c12b67"
# /dev/nvme0n1p1: UUID="4882-915D" BLOCK_SIZE="512" TYPE="vfat" PARTLABEL="EFI System Partition" PARTUUID="6f530168-0cb2-4f89-9b7e-318f92b6b60f"
# /dev/nvme0n1p2: UUID="c791c518-83e5-4dd5-8cdf-a47621f9019b" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="13e37336-cf10-4df6-aecf-2781050aeb79"
# /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac: LABEL="fedora_localhost-live" UUID="df2d4761-d84b-4fea-af88-2dd5d7eeca4c" UUID_SUB="a0a703f9-31e6-4cb6-973d-2e1e9b935c85" BLOCK_SIZE="4096" TYPE="btrfs"
# /dev/sda1: UUID="87278135-9aec-4da7-9fe4-fca1ecf2aeb7" TYPE="crypto_LUKS" PARTLABEL="BACKUP" PARTUUID="582af379-1f24-49df-8097-eecc6dba85d5"
# /dev/zram0: LABEL="zram0" UUID="62d6119a-a230-4561-8b97-665a19d13267" TYPE="swap"
```
In my case `sda` is an internal SSD that I use for [my backup strategy](../../backup/#5-dell-precision-7520-linux), whereas `zram0` is the swap partition. The system is installed to `nvme0n1` and it has 3 partitions:

1. a 600 MiB FAT32 EFI partition
1. a 1024 MiB EXT4 partition for /boot
1. a 486761MiB partition that contains the luks2 encrypted system files

Let's have a closer look at the luks2-encrypted partition:

```sh
sudo cryptsetup luksDump /dev/nvme0n1p3
# LUKS header information
# Version:       	2
# Epoch:         	3
# Metadata area: 	16384 [bytes]
# Keyslots area: 	16744448 [bytes]
# UUID:          	8bf48ffa-78e1-4a16-ad9e-301b7199d8ac
# Label:         	(no label)
# Subsystem:     	(no subsystem)
# Flags:       		(no flags)
# 
# Data segments:
#   0: crypt
# 	offset: 16777216 [bytes]
# 	length: (whole device)
# 	cipher: aes-xts-plain64
# 	sector: 512 [bytes]
# 
# Keyslots:
#   0: luks2
# 	Key:        512 bits
# 	Priority:   normal
# 	Cipher:     aes-xts-plain64
# 	Cipher key: 512 bits
# 	PBKDF:      argon2id
# 	Time cost:  9
# 	Memory:     1048576
# 	Threads:    4
# 	Salt:       8e 3d 51 bb 28 42 8c 9e 3c 56 35 ec 74 c5 65 7f
#              9f e9 53 29 fb 3b 43 b0 33 cf 2f e1 07 bc 7b c3 
# 	AF stripes: 4000
# 	AF hash:    sha256
# 	Area offset:32768 [bytes]
# 	Area length:258048 [bytes]
# 	Digest ID:  0
# Tokens:
# Digests:
#   0: pbkdf2
# 	Hash:       sha256
# 	Iterations: 130290
#       Salt:     40 a3 2b 1a 57 3e e0 76 4f b9 e5 67 13 3f 3f 1f 
#  	            46 f1 04 d3 3d 52 01 76 34 53 13 ee da 62 0a 9c 
#  	Digest:     3f 5a dc 3b 61 10 75 a0 e6 d0 0c f9 91 d2 e4 17 
#  	            2c 2b 63 f4 47 38 24 67 bc 56 23 9e 92 89 30 6b
```
So this basically uses the default options to encrypt a partition with luks v2 (e.g. `cryptsetup luksFormat /dev/nvme0n1p3`). Let's have a look what is inside the encrypted partition:

```sh
sudo cat /etc/crypttab
# luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac UUID=8bf48ffa-78e1-4a16-ad9e-301b7199d8ac none discard

ls /dev/mapper
# control  luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac

sudo lsblk /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac -f
# NAME               FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
# luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac
#                    btrfs        fedora_localhost-live
#                                       df2d4761-d84b-4fea-af88-2dd5d7eeca4c  470.5G     1% /home
#                                                                                           /

sudo btrfs filesystem usage /
# Overall:
#     Device size:		      475.34GiB
#     Device allocated:		   5.02GiB
#     Device unallocated:		470.32GiB
#     Device missing:		   0.00B
#     Used:			            4.01GiB
#     Free (estimated):		   470.47GiB	(min: 470.47GiB)
#     Free (statfs, df):		470.47GiB
#     Data ratio:			      1.00
#     Metadata ratio:		   1.00
#     Global reserve:		   10.75MiB	(used: 0.00B)
#     Multiple profiles:		no
# 
# Data,single: Size:4.01GiB, Used:3.85GiB (96.09%)
#    /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac	   4.01GiB
# 
# Metadata,single: Size:1.01GiB, Used:167.72MiB (16.25%)
#    /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac	   1.01GiB
# 
# System,single: Size:4.00MiB, Used:16.00KiB (0.39%)
#    /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac	   4.00MiB
# 
# Unallocated:
#    /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac	 470.32GiB

sudo btrfs device usage /
# /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac, ID: 1
#    Device size:           475.34GiB
#    Device slack:              0.00B
#    Data,single:             4.01GiB
#    Metadata,single:         1.01GiB
#    System,single:           4.00MiB
#    Unallocated:           470.32GiB


sudo btrfs subvolume list /
# ID 256 gen 51 top level 5 path home
# ID 257 gen 52 top level 5 path root
# ID 262 gen 26 top level 257 path var/lib/machines
``` 

From the `crypttab` we see that the mapped luks device is named `luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac` where the number is the UUID of `/dev/nvme0n1p3`. The crypt is formatted with btrfs and contains three subvolumes

1. `home`: this is where `/home` is mounted to
1. `root`: this is where `/` is mounted to
1. `var/lib/machines` this is a nested subvolume to exclude virtual machine files (which tend to change all the times) from snapshots of `home` and `root`

This is also evident from the fstab:

```sh 
sudo cat /etc/fstab
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /                       btrfs   subvol=root,compress=zstd:1,x-systemd.device-timeout=0 0 0
# UUID=c791c518-83e5-4dd5-8cdf-a47621f9019b /boot                   ext4    defaults        1 2
# UUID=4882-915D          /boot/efi               vfat    umask=0077,shortname=winnt 0 2
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /home                   btrfs   subvol=home,compress=zstd:1,x-systemd.device-timeout=0 0 0
```
where `UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c` is the UUID of the mapped device `/dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac`. Note that by default the only optimized mount option is `zstd:1` which turns on compression.

Lastly, swap is using 8GB of ZRAM:

```sh
sudo swapon
# NAME       TYPE      SIZE USED PRIO
# /dev/zram0 partition   8G   0B  100
```


## Step 3: Post-Installation steps

### Step 3a: Mount the btrfs top-level filesystem to /btrfs_pool

Let's mount our the top-level btrfs volume (which has always id 5) to a mount point `/btrfs_pool` using the fstab:

```sh
sudo mkdir /btrfs_pool
echo "UUID=$(blkid -s UUID -o value /dev/mapper/luks-$(blkid -s UUID -o value /dev/nvme0n1p3))  /btrfs_pool  btrfs  subvolid=5,compress=zstd:1,x-systemd.device-timeout=0 0 0" | sudo tee -a /etc/fstab

cat /etc/fstab
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /                       btrfs   subvol=root,compress=zstd:1,x-systemd.device-timeout=0 0 0
# UUID=c791c518-83e5-4dd5-8cdf-a47621f9019b /boot                   ext4    defaults        1 2
# UUID=4882-915D                            /boot/efi               vfat    umask=0077,shortname=winnt 0 2
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /home                   btrfs   subvol=home,compress=zstd:1,x-systemd.device-timeout=0 0 0
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /btrfs_pool             btrfs   subvolid=5,compress=zstd:1,x-systemd.device-timeout=0 0 0

sudo mount -av
# /                        : ignored
# /boot                    : already mounted
# /boot/efi                : already mounted
# /home                    : already mounted
# mount: /btrfs_pool does not contain SELinux labels.
#        You just mounted a file system that supports labels which does not
#        contain labels, onto an SELinux box. It is likely that confined
#        applications will generate AVC messages and not be allowed access to
#        this file system.  For more details see restorecon(8) and mount(8).
# /btrfs_pool              : successfully mounted

ls /btrfs_pool
# home root
```
I am not sure what the `SELinux labels` warning means or how to avoid that, so if do you, let me know. I guess after the reboot this should not be a problem as you cannot have different mount options on the same partition (see below the `seclabel` mount option is set). Anyways, we can access our subvolumes from `/btrfs_pool`.


### Step 3b (optionally): use optimized mount options
As the development of BTRFS continues and Fedora keeps pushing improvements upstream, I only change three mount options to optimize performance and durability on SSD or NVME drives:

- `ssd`: use SSD specific options for optimal use on SSD and NVME (this is probably redundant as BTRFS detects SSDs and NVMes automatically)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate. Fedora has started to use v1, I will use v3.
- `discard=async`: [Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard)

Let's make these changes with a text editor, e.g. `sudo nano /etc/fstab` or use these `sed` commands which replace the mount options
```sh
sudo sed -i 's/compress=zstd:1/ssd,compress=zstd,discard=async/' /etc/fstab
```

Either way your `fstab` should look like this:
```sh
cat /etc/fstab
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /            btrfs   subvol=root,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0  0 0
# UUID=c791c518-83e5-4dd5-8cdf-a47621f9019b /boot        ext4    defaults                                                                1 2
# UUID=4882-915D                            /boot/efi    vfat    umask=0077,shortname=winnt                                              0 2
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /home        btrfs   subvol=home,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0  0 0
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c /btrfs_pool  btrfs   subvolid=5,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0   0 0
```

Let's reboot to see whether this worked. So after the restart, check the following:
```sh
sudo mount -v | grep /dev/mapper
# /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac on / type btrfs (rw,relatime,seclabel,compress=zstd:3,ssd,discard=async,space_cache,subvolid=257,subvol=/root)
# /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac on /btrfs_pool type btrfs (rw,relatime,seclabel,compress=zstd:3,ssd,discard=async,space_cache,subvolid=5,subvol=/)
# /dev/mapper/luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac on /home type btrfs (rw,relatime,seclabel,compress=zstd:3,ssd,discard=async,space_cache,subvolid=256,subvol=/home)
```
This should reflect the changes you just made in the fstab. Note that you cannot have different mount options for your subvolumes on the same partition.

## Step 4: automatic snapshots and backups with btrfs using BTRBK

### Step 4a: preparations
If you haven't done already, create a mount point `/btrfs_pool` for the top-level root of my btrfs partition (see above) as BTRBK needs a folder or subvolume to store the snapshots under the top-level. Let's call this folder `_btrbk_snap`:
```sh
sudo mkdir /btrfs_pool/_btrbk_snap
ls /btrfs_pool
# _btrbk_snap home root
```
Note that `_btrbk_snap` is a folder, whereas `home` and `root` are subvolumes.

### Step 4b: install and configure BTRBK for snapshots
Install BTRBK from the repos:
```sh
sudo dnf install -y btrbk
```
Next I create the following configuration file:
```sh
mkdir -p $HOME/scripts
nano $HOME/scripts/precision-btrbk.conf
```
My configuration file (just for snapshots, I'll cover the configuration file with a target for send/receive backups below) looks like this:
```sh
transaction_log         /var/log/btrbk.log
lockfile                /var/lock/btrbk.lock
timestamp_format        long

snapshot_dir            _btrbk_snap
snapshot_preserve_min   3h
snapshot_preserve       6h 5d 3w 1m

volume /btrfs_pool
  snapshot_create  always
  subvolume root
  subvolume home
```
This looks into `/btrfs_pool` and creates snapshots for the subvolumes `root` and `home` into the directory `/btrfs_pool/_btrbk_snap`. All snapshots are preserved for at least 3 hours, while the usual retention policy is to keep 6 hourly, 5 daily, 3 weekly and 1 monthly snapshot. Let's test this:

```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf dryrun
# --------------------------------------------------------------------------------
# Backup Summary (btrbk command line client, version 0.28.3)
# 
#     Date:   Tue Dec 14 10:34:23 2021
#     Config: /home/wmutschl/scripts/precision-btrbk.conf
#     Dryrun: YES
# 
# Legend:
#     ===  up-to-date subvolume (source snapshot)
#     +++  created subvolume (source snapshot)
#     ---  deleted subvolume
#     ***  received subvolume (non-incremental)
#     >>>  received subvolume (incremental)
# --------------------------------------------------------------------------------
# /btrfs_pool/root
# +++ /btrfs_pool/_btrbk_snap/root.20211214T1034
# 
# /btrfs_pool/home
# +++ /btrfs_pool/_btrbk_snap/home.20211214T1034
# 
# NOTE: Dryrun was active, none of the operations above were actually executed!
```
If there was no error, let's actually run this to create our first snapshots (this should take a fraction of a second, that's the beauty of copy-on-write snapshots) and see whether they are stored correctly:
```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf run

ls /btrfs_pool/_btrbk_snap
# home.20211214T1035  root.20211214T1035

sudo btrfs subvolume list /
# ID 256 gen 118 top level 5 path home
# ID 257 gen 119 top level 5 path root
# ID 262 gen 101 top level 257 path var/lib/machines
# ID 266 gen 117 top level 5 path _btrbk_snap/root.20211214T1035
# ID 267 gen 118 top level 5 path _btrbk_snap/home.20211214T1035
```
Now you can always revert your system to `root.20211214T1035` or restore your home files from `home.20211214T1035`. Note that BTRBK by default creates read-only snapshots, so if you want to restore your whole system to a certain snapshot you need to follow the [restore backups with BTRBK guide](https://github.com/digint/btrbk#restoring-backups).

### Step 4c: create systemd timer for BTRBK to run every hour
On servers that run constantly I usually use the `crontab` for automatic snapshots with BTRBK; however, on my laptop I use a systemd timer instead. First let's check the timer and service that is shipped with BTRBK:
```sh
sudo systemctl status btrbk.service
# ○ btrbk.service - btrbk backup
#      Loaded: loaded (/usr/lib/systemd/system/btrbk.service; static)
#      Active: inactive (dead)
#        Docs: man:btrbk(1)

sudo systemctl status btrbk.timer
# ○ btrbk.timer - btrbk daily backup
#      Loaded: loaded (/usr/lib/systemd/system/btrbk.timer; disabled; vendor preset: disabled)
#      Active: inactive (dead)
#     Trigger: n/a
#    Triggers: ● btrbk.service
```

Now let's make some small changes to the timer `sudo nano /lib/systemd/system/btrbk.timer` to make it `hourly`:
```sh
[Unit]
Description=btrbk hourly snapshots and backup

[Timer]
OnCalendar=hourly
AccuracySec=10min
Persistent=true

[Install]
WantedBy=multi-user.target
```

and to the service `sudo nano /lib/systemd/system/btrbk.service` to make use of the custom configuration file that we created:
```sh
[Unit]
Description=btrbk snapshots and backup
Documentation=man:btrbk(1)

[Service]
Type=oneshot
ExecStart=/usr/sbin/btrbk -c /home/wmutschl/scripts/precision-btrbk.conf run
```

Make sure the permissions are correct:
```sh
sudo chmod 644 /lib/systemd/system/btrbk.timer
sudo chmod 644 /lib/systemd/system/btrbk.service
```
and checkout if it works (tip: you can exit the log outputs by writing `:q` or hitting `CTRL+C`):
```sh
sudo systemctl start btrbk.service
sudo systemctl status btrbk.service
# ○ btrbk.service - btrbk snapshots and backup
#      Loaded: loaded (/usr/lib/systemd/system/btrbk.service; static)
#      Active: inactive (dead)
#        Docs: man:btrbk(1)
# 
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]:     ---  deleted subvolume
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]:     ***  received subvolume (non-incremental)
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]:     >>>  received subvolume (incremental)
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]: # ---------------------------------------------------------------------->
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]: /btrfs_pool/root
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]: +++ /btrfs_pool/_btrbk_snap/root.20211214T1044
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]: /btrfs_pool/home
# Dec 14 10:44:17 fedora.fritz.box btrbk[26497]: +++ /btrfs_pool/_btrbk_snap/home.20211214T1044
# Dec 14 10:44:17 fedora.fritz.box systemd[1]: btrbk.service: Deactivated successfully.
# Dec 14 10:44:17 fedora.fritz.box systemd[1]: Finished btrbk snapshots and backup.

cat /var/log/btrbk.log
# 2021-12-14T10:44:17+0100 startup v0.28.3 - - - # btrbk command line client, version 0.28.3
# 2021-12-14T10:44:17+0100 snapshot starting /btrfs_pool/_btrbk_snap/root.20211214T1044 /btrfs_pool/root - -
# 2021-12-14T10:44:17+0100 snapshot success /btrfs_pool/_btrbk_snap/root.20211214T1044 /btrfs_pool/root - -
# 2021-12-14T10:44:17+0100 snapshot starting /btrfs_pool/_btrbk_snap/home.20211214T1044 /btrfs_pool/home - -
# 2021-12-14T10:44:17+0100 snapshot success /btrfs_pool/_btrbk_snap/home.20211214T1044 /btrfs_pool/home - -
# 2021-12-14T10:44:17+0100 finished success - - - -

ls /btrfs_pool/_btrbk_snap
# home.20211214T1035  home.20211214T1044  root.20211214T1035  root.20211214T1044
```
Check if snapshots are created and if any errors occured. If all is well, then enable the timer:
```sh
sudo systemctl enable btrbk.timer
# Created symlink /etc/systemd/system/multi-user.target.wants/btrbk.timer → /usr/lib/systemd/system/btrbk.timer.
sudo systemctl start btrbk.timer
sudo systemctl daemon-reload
sudo systemctl list-timers --all
```
You should see the following line (tip: you can exit by inserting `:q` or clicking `CTRL+C`):
```sh
NEXT                        LEFT          LAST                        PASSED       UNIT                         ACTIVATES                     
Tue 2021-12-14 11:00:00 CET 13min left    n/a                         n/a          btrbk.timer                  btrbk.service
```
Recheck the hourly timer after an hour (or 13min in my case) to make sure everything is working:
```sh
sudo systemctl list-timers --all
cat /var/log/btrbk.log
ls /btrfs_pool/_btrbk_snap
```
Make sure the snapshots are created without errors.

## Step 5 (optional): Mount an encrypted backup disk as btrfs send/receive target
I use my internal SSD as a backup disk to receive the incremental btrfs snapshots. The steps, however, also work with an external USB disk.

### Step 5a: Preparations
So let's create a GPT table on it, create an encrypted partition and format it with the btrfs filesystem. I usually use GParted (`sudo dnf install gparted`); however, you can also use command-line tools like `parted`, e.g.:
```sh
sudo parted /dev/sda mklabel gpt
# Warning: The existing disk label on /dev/sda will be destroyed and all data on this disk will
# be lost. Do you want to continue?
# Yes/No? Yes                                                               
# Information: You may need to update /etc/fstab.
sudo parted /dev/sda mkpart primary 1MiB 100%
# Information: You may need to update /etc/fstab.
sudo parted /dev/sda name 1 BACKUP
sudo parted /dev/sda unit MiB print
# Model: ATA Samsung SSD 840 (scsi)
# Disk /dev/sda: 476940MiB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# Number  Start    End        Size       File system  Name    Flags
#  1      1.00MiB  476940MiB  476939MiB               BACKUP

sudo cryptsetup luksFormat /dev/sda1
# WARNING: Device /dev/sda1 already contains a 'crypto_LUKS' superblock signature.
# WARNING!
# ========
# This will overwrite data on /dev/sda1 irrevocably.
# Are you sure? (Type 'yes' in capital letters): YES
# Enter passphrase for /dev/sda1: 
# Verify passphrase: 
```
**If you set the same passphrase as for your system disk, then you won't have to enter the passphrase twice at boot (otherwise you need to create keyfiles, see appendix). This is what I usually do.** 

Anyways, lets continue:
```sh
sudo cryptsetup luksOpen /dev/sda1 cryptbackup
# Enter passphrase for /dev/sda1: 

sudo mkfs.btrfs /dev/mapper/cryptbackup 
# btrfs-progs v5.15.1 
# See http://btrfs.wiki.kernel.org for more information.
# 
# NOTE: several default settings have changed in version 5.15, please make sure
#       this does not affect your deployments:
#       - DUP for metadata (-m dup)
#       - enabled no-holes (-O no-holes)
#       - enabled free-space-tree (-R free-space-tree)
# 
# Label:              (null)
# UUID:               94b22aac-7697-4b2b-af88-c32870807984
# Node size:          16384
# Sector size:        4096
# Filesystem size:    465.75GiB
# Block group profiles:
#   Data:             single            8.00MiB
#   Metadata:         DUP               1.00GiB
#   System:           DUP               8.00MiB
# SSD detected:       yes
# Zoned device:       no
# Incompat features:  extref, skinny-metadata, no-holes
# Runtime features:   free-space-tree
# Checksum:           crc32c
# Number of devices:  1
# Devices:
#    ID        SIZE  PATH
#     1   465.75GiB  /dev/mapper/cryptbackup
```

Let's create a mount point `/btrfs_backup` for this disk and update the fstab to mount this at boot:
```sh
sudo mkdir /btrfs_backup
```
Of course if you are using an external USB drive then skip this and the below changes to the fstab and to the crypttab. The mount point of your external disk will be in `/media/run/$USER/` and you can simply save the passphrase to your keyring to automatically unlock it when connecting it to your system. If you work with an internal backup disk, then continue.

So, next I add an entry to the fstab to mount this at boot time:
```sh
sudo blkid
echo "UUID=$(blkid -s UUID -o value /dev/mapper/cryptbackup)  /btrfs_backup  btrfs  subvolid=5,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0,x-systemd.after=/   0 0" | sudo tee -a /etc/fstab

cat /etc/fstab
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c  /              btrfs   subvol=root,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0                    0 0
# UUID=c791c518-83e5-4dd5-8cdf-a47621f9019b  /boot          ext4    defaults                                                                                  1 2
# UUID=4882-915D                             /boot/efi      vfat    umask=0077,shortname=winnt                                                                0 2
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c  /home          btrfs   subvol=home,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0                    0 0
# UUID=df2d4761-d84b-4fea-af88-2dd5d7eeca4c  /btrfs_pool    btrfs   subvolid=5,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0                     0 0
# UUID=94b22aac-7697-4b2b-af88-c32870807984  /btrfs_backup  btrfs   subvolid=5,ssd,compress=zstd,discard=async,x-systemd.device-timeout=0,x-systemd.after=/   0 0

sudo mount -av
# /btrfs_backup            : successfully mounted
```

Next, we need to make the crypttab aware of the encrypted backup disk:
```sh
sudo blkid
echo "cryptbackup UUID=$(blkid -s UUID -o value /dev/sda1) none discard" | sudo tee -a /etc/crypttab

sudo cat /etc/crypttab
# luks-8bf48ffa-78e1-4a16-ad9e-301b7199d8ac UUID=8bf48ffa-78e1-4a16-ad9e-301b7199d8ac none discard
# cryptbackup                               UUID=47b0e8eb-51c8-40ad-8006-186f965236a2 none discard
```
Update the initramfs:
```sh
sudo dracut --force --regenerate-all
```
Before we continue, let's test this by restarting the system. 
```sh
sudo reboot now
```
If you chose the same passphrase as for your system disk, you should be only asked once for a luks passphrase. Note that you can always change the passphrase in Gnome Disks by selecting the luks partition and the symbol for options will give you an option to change the passphrase. If you want to use different passphrases then have a look in the appendix how to create keyfiles and add them to the crypttab. If you are using an external USB drive then these steps can be skipped and you can simply add the luks passphrase to your keyring to automatically unlock it when it is connected; the mount point will be in `/media/run/$USER/`.

### Step 5b: Add target for btrfs send/receive in BTRBK configuration file
We need to add `/btrfs_backup` as a target with a retention policy in our custom BTRBK configuration file: `nano $HOME/scripts/precision-btrbk.conf`:
```sh
transaction_log         /var/log/btrbk.log
lockfile                /var/lock/btrbk.lock
timestamp_format        long

snapshot_dir            _btrbk_snap
snapshot_preserve_min   3h
snapshot_preserve       6h 5d 3w 1m
target_preserve_min     3h
target_preserve         24h 31d 52w

volume /btrfs_pool
  snapshot_create  always
  target send-receive /btrfs_backup
  subvolume root
  subvolume home
```
For external disks, there is an `on-demand` flag you can set, see the [example configuration for backups to a usb disk](https://github.com/digint/btrbk#example-backups-to-usb-disk).

Either way, let's run BTRBK in dry mode first:

```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf dryrun
# WARNING: Failed to parse subvolume detail "Send transid: 0" for: /btrfs_pool
# WARNING: Failed to parse subvolume detail "Send time: 2021-12-14 09:23:35 +0100" for: /btrfs_pool
# WARNING: Failed to parse subvolume detail "Receive transid: 0" for: /btrfs_pool
# WARNING: Failed to parse subvolume detail "Receive time: -" for: /btrfs_pool
# WARNING: Failed to parse subvolume detail "Send transid: 0" for: /btrfs_backup
# WARNING: Failed to parse subvolume detail "Send time: 2021-12-14 10:56:21 +0100" for: /btrfs_backup
# WARNING: Failed to parse subvolume detail "Receive transid: 0" for: /btrfs_backup
# WARNING: Failed to parse subvolume detail "Receive time: -" for: /btrfs_backup
# --------------------------------------------------------------------------------
# Backup Summary (btrbk command line client, version 0.28.3)
# 
#     Date:   Tue Dec 14 11:23:24 2021
#     Config: /home/wmutschl/scripts/precision-btrbk.conf
#     Dryrun: YES
# 
# Legend:
#     ===  up-to-date subvolume (source snapshot)
#     +++  created subvolume (source snapshot)
#     ---  deleted subvolume
#     ***  received subvolume (non-incremental)
#     >>>  received subvolume (incremental)
# --------------------------------------------------------------------------------
# /btrfs_pool/root
# +++ /btrfs_pool/_btrbk_snap/root.20211214T1123
# *** /btrfs_backup/root.20211214T1035
# >>> /btrfs_backup/root.20211214T1044
# >>> /btrfs_backup/root.20211214T1100
# >>> /btrfs_backup/root.20211214T1123
# 
# /btrfs_pool/home
# +++ /btrfs_pool/_btrbk_snap/home.20211214T1123
# *** /btrfs_backup/home.20211214T1035
# >>> /btrfs_backup/home.20211214T1044
# >>> /btrfs_backup/home.20211214T1100
# >>> /btrfs_backup/home.20211214T1123
# 
# NOTE: Dryrun was active, none of the operations above were actually executed!
```
You can see that the first snapshots are sent in full, whereas the remaining ones are sent incrementially and therefore will be very fast. If there was no error (you can ignore the Warnings), run it:
```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf run --progress
```
This might take a short while (I am using an NVME and a SSD so no problem), because the initial backup is transferred to your backup disk. All other snapshots will be sent and received incrementially.

Check if all snapshots are both in `/btrfs_pool/_btrbk_snap` and `/btrfs_backup`:
```sh
sudo btrfs subvolume list /btrfs_pool/_btrbk_snap
# ID 256 gen 168 top level 5 path home
# ID 257 gen 169 top level 5 path root
# ID 262 gen 159 top level 257 path root/var/lib/machines
# ID 266 gen 117 top level 5 path _btrbk_snap/root.20211214T1035
# ID 267 gen 118 top level 5 path _btrbk_snap/home.20211214T1035
# ID 270 gen 128 top level 5 path _btrbk_snap/root.20211214T1044
# ID 271 gen 129 top level 5 path _btrbk_snap/home.20211214T1044
# ID 272 gen 140 top level 5 path _btrbk_snap/root.20211214T1100
# ID 273 gen 141 top level 5 path _btrbk_snap/home.20211214T1100
# ID 274 gen 167 top level 5 path _btrbk_snap/root.20211214T1126
# ID 275 gen 169 top level 5 path _btrbk_snap/home.20211214T1126

sudo btrfs subvolume list /btrfs_backup
# ID 256 gen 20 top level 5 path root.20211214T1035
# ID 257 gen 23 top level 5 path root.20211214T1044
# ID 258 gen 26 top level 5 path root.20211214T1100
# ID 259 gen 41 top level 5 path root.20211214T1126
# ID 260 gen 32 top level 5 path home.20211214T1035
# ID 261 gen 35 top level 5 path home.20211214T1044
# ID 262 gen 38 top level 5 path home.20211214T1100
# ID 263 gen 41 top level 5 path home.20211214T1126
```
Re-run btrbk to see that (as no files have been changed on the disk) the next snapshots and send/receive backups are instant:
```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf run --progress
```

## Final remarks
That's it. Remember to check in the next couple of hours or days whether the systemd timer works and both snapshots as well as backups are created according to your retention policy.

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**

**Check out my [Fedora post-installation steps](../fedora-post-install).**

## Appendix (NOT YET-JUST SOME NOTES)

I want my system to automatically unlock my backup disk such that I need to type my luks passphrase only once (this step is optional, but recommended). So let's create a key-file, secure it, and add it to our luks partition of the backup disk:

```sh
sudo mkdir /etc/luks
sudo dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
# 1+0 records in
# 1+0 records out
# 4096 bytes (4.1 kB, 4.0 KiB) copied, 0.000928939 s, 4.4 MB/s
sudo chmod u=rx,go-rwx /etc/luks
sudo chmod u=r,go-rwx /etc/luks/boot_os.keyfile
sudo cryptsetup luksAddKey /dev/sda1 /etc/luks/boot_os.keyfile
# Enter any existing passphrase: 
```

Let's restrict the pattern of keyfiles and avoid leaking key material for the initramfs hook:

```sh
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" | sudo tee -a /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" | sudo tee -a /etc/initramfs-tools/initramfs.conf
```
These commands will harden the security options in the intiramfs configuration file and hook (*not sure if this is also needed for systemd bootloader?!?*).

Next, add the keyfile to your `crypttab`:

```sh
echo "cryptbackup UUID=$(blkid -s UUID -o value /dev/sda1) /etc/luks/boot_os.keyfile luks,discard" | sudo tee -a /etc/crypttab

cat /etc/crypttab
# cryptdata UUID=c5b8099a-f035-47fb-939f-fa4ea770a403 none luks,discard
# cryptswap UUID=52de8233-c50b-4873-b586-9ab313d28b56 /dev/urandom swap,plain,offset=1024,cipher=aes-xts-plain64,size=512
# cryptbackup UUID=87278135-9aec-4da7-9fe4-fca1ecf2aeb7 /etc/luks/boot_os.keyfile luks,discard
```
and update the initramfs:
```sh
sudo update-initramfs -u -k all
```











## (NOT YET-JUST SOME NOTES)
### STEP 5 (OPTIONAL): Full disk encryption including `/boot`
I actually like to use a Yubikey as a second factor to unlock my luks partition, for this I need an unencrypted `/boot` partition (see my [Things to do after installing Fedora](../fedora-post-install)), so I usually skip this step. 

If your needs are different, then it is also possible to fully encrypt your system based upon [security_modules in Grub2](https://fedoraproject.org/wiki/Changes/Include_security_modules_in_efi_Grub2), i.e. to also put `/boot` inside a luks container and let GRUB unlock this first and pass on the passphrase to unlock your root partition as well. If you want this, then follow on and open up a terminal with an interactive root shell:
```sh
sudo -i
```

### Backup the files in your boot partition
The boot partition is on `/dev/vda2`, whereas the efi partition is on `/dev/vda1`. Let's backup the boot partition:
```sh
umount /boot/efi
rsync -avuP /boot/ /boot.bak/
```

### Create luks1 partition for boot
GRUB is able to decrypt luks version 1 partitions at boot time, but by default version 2 is used in cryptsetup. So we need to prepare the luks1 partition or else GRUB will not be able to unlock the encrypted device. Note that most Linux distributions also default to version 1 if you do a full disk encryption (e.g. Manjaro Architect). This step is still work-in-progress as I need to figure out how to prompt only once for the passphrase.

```sh
umount /boot
cryptsetup luksFormat --type=luks1 /dev/vda2
# WARNING!
# ========
# This will overwrite data on /dev/vda2 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vda2: 
# Verify passphrase:
```
Now map the encrypted partition to a device called `crypt-boot` and choose a filesystem (e.g. ext4 or btrfs)

```sh
cryptsetup luksOpen /dev/vda2 crypt-boot
# Enter passphrase for /dev/vda2:

ls /dev/mapper/
# control  crypt-boot  luks-6e7e8f26-4f38-468e-aa2c-9ddaaad4aedf

mkfs.btrfs /dev/mapper/crypt-boot
```

### Correct fstab, crypttab and restore boot backup files
Let's find out the new UUID of our encrypted boot partition:
```sh
blkid | grep crypt-boot
# dev/mapper/crypt-boot: UUID="3f75f101-bbe7-4850-9b33-a2196807fb01" UUID_SUB="984444d1-66fb-4d09-9586-8cb876653c28" BLOCK_SIZE="4096" TYPE="btrfs"
```
and replace the old UUID of the boot partition with the new one in /etc/fstab, also making sure that btrfs is the filesystem:
```sh
nano /etc/fstab
# UUID=11fa3de5-bfb4-4227-a5ee-d8a3d2d2304a /                       btrfs   subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async,x-systemd.device-timeout=0      0 0
# UUID=3f75f101-bbe7-4850-9b33-a2196807fb01 /boot                   btrfs   defaults         0 0
# UUID=4FD9-A843                            /boot/efi               vfat    umask=0077,shortname=winnt                                                                              0 2
# UUID=11fa3de5-bfb4-4227-a5ee-d8a3d2d2304a /home                   btrfs   subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async,x-systemd.device-timeout=0  0 0
# UUID=11fa3de5-bfb4-4227-a5ee-d8a3d2d2304a /btrfs_pool             btrfs   subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async,x-systemd.device-timeout=0    0 0
```

Also add an entry for the crypt-boot container to /etc/crypttab:
```sh
blkid | grep vda2
# UUID="84fbddb8-984c-4dda-b5b7-27a49864b5f8" TYPE="crypto_LUKS" PARTUUID="e4007823-54ac-4bce.929d-7616a04f59a8"

nano /etc/crypttab
# luks-6e7e8f26-4f38-468e-aa2c-9ddaaad4aedf UUID=6e7e8f26-4f38-468e-aa2c-9ddaaad4aedf none discard
# crypt-boot                                UUID=84fbddb8-984c-4dda-b5b7-27a49864b5f8 none discard
```

Let's remount the boot partition, restore the backup, and mount the efi partition:
```sh
mount /boot
rsync -avuP /boot.bak/ /boot/
mount /boot/efi
```

### Enable cryptodisk in GRUB
```sh
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
```

### Regenerate the initram disk and Grub
```sh
dracut --force --regenerate-all --verbose
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

### Reboot and check whether this works
Grub should ask for the password for the boot partition and then for the root partition. You will then also need to reenter your password for the root partition. If the system then starts, the change is successful, but we need to simplify the passphrase situation using a keyfile for filesystem root (or clevis package and a tpm).

### Get rid of additional passphrase prompts [WIP]
Not yet... Write me an email, if you know how!



We need to let GRUB know about the changes as well:
```sh
grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

## Step 3: Reboot, some checks, and update system
Cross your fingers and reboot:
```sh
reboot now
```
Now let's open up a terminal to see whether everything is set up correctly:












