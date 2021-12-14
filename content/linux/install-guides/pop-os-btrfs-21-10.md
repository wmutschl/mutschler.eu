---
title: 'Pop!_OS 21.10: installation guide with btrfs-LVM-luks and auto snapshots with BTRBK'
#linktitle: Pop!_OS 21.10 btrfs-luks
summary: In this guide I will walk you through the installation procedure to get a Pop!_OS 21.10 system with a luks-encrypted partition which contains a LVM with a logical volume for the root filesystem that is formatted with btrfs and contains a subvolume @ for / and a subvolume @home for /home. I will show how to optimize the btrfs mount options and how to setup an encrypted swap partition which works with hibernation. This layout enables one to use BTRBK which will regularly take snapshots of the system and optionally on any apt operation. The recovery system of Pop!_OS is also installed to the disk and accessible via the systemd bootloader.
toc: true
type: book
#date: "2021-12-13"
draft: false
weight: 26
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***



## Overview 
I am exclusively using btrfs as my filesystem on all my Linux systems, see [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Pop!_OS 21.10 with the following structure:

- an unencrypted EFI partition for the systemd bootloader
- an unencrypted partition for the Pop!_OS recovery system
- an encrypted swap partition which works with hibernation
- a btrfs-LVM-inside-luks partition for the root filesystem
  - the btrfs logical volume contains a subvolume `@` for `/` and a subvolume `@home` for `/home`. Note that the Pop!_OS installer does not create any subvolumes on btrfs, so we need to do this manually.
- automatic system snapshots and easy rollback similar to *zsys* using [BTRBK](https://github.com/digint/btrbk) which will regularly take (almost instant) snapshots of the system and (optionally) also on any apt operation

This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).


## Step 0: General remarks
This tutorial is made with Pop!_OS 21.10 from https://system76.com/pop copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor). Other versions of Pop!_OS and other distributions that use Systemd boot manager might also work, but sometimes require additional steps (see my other [installation guides](../../install-guides)).

**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**
For instance, you can spin up a virtual machine with 4 cores, 8 GB RAM, and a 64GB disk using e.g. the awesome [quickemu](https://github.com/quickemu-project/quickemu) project. 

In the following, however, I outline the steps for my Dell Precision 7520 with a NVME drive which I use for the system files and another SSD which is used for btrfs backups.

## Step 1a: Boot the install and perform a `Clean Install` with encryption
In previous installation guides I prepared the partitions manually; however, as I am basically using the same layout as the automatic POP!_OS installer with the only difference that I want to use btrfs instead of EXT4 as the filesystem, I simply perform the installation twice. The first one is the automatic `Clean Install` with encryption. When this finishes, do NOT `Restart Device` or `Shut Down` but instead right-click in the dock on the `Install Pop!_OS` app and select `Quit`. 

If you want to see the structure of the installation keep reading, otherwise go to the next step to perform the second Installation.

## Step 1b (optional): Understand the partition layout and installation structure
So, let's open a terminal and have a look on the default partition layout:
```sh
sudo lsblk
# NAME          MAJ:MIN RM    SIZE RO TYPE MOUNTPOINT
# loop0           7:0    0    2.8G  1 loop /rofs
# sda             8:0    0  465.8G  0 disk 
# └─sda1          8:1    0  465.8G  0 part 
# sdb             8:16   1    3.7G  0 disk 
# ├─sdb1          8:17   1    2.9G  0 part /cdrom
# ├─sdb2          8:18   1      4M  0 part 
# └─sdb3          8:19   1  843.5M  0 part /var/crash
# nvme0n1       259:0    0  476.9G  0 disk
# ├─nvme0n1p1   259:1    0    498M  0 part
# ├─nvme0n1p2   259:2    0      4G  0 part 
# └─nvme0n1p3   259:3    0  468.4G  0 part
# ├─nvme0n1p4   259:4    0      4G  0 part

sudo parted /dev/nvme0n1 unit MiB print
# Model: PM961 NVMe SAMSUNG 512GB (nvme)
# Disk /dev/nvme0n1: 488386MiB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# 
# Number  Start      End        Size       File system    Name      Flags
#  1      2.00MiB    500MiB     498MiB     fat32          EFI       boot, esp
#  2      500MiB     4596MiB    4096MiB    fat32          recovery  msftdata
#  3      4596MiB    484288MiB  479692MiB
#  4      484288MiB  488384MiB  4096MiB    linux-swap(v1)           swap
```
In my case `sda` is an internal SSD that I use for [my backup strategy](../../backup/#5-dell-precision-7520-linux), whereas `sdb` is the flash drive that contains the installation files. So, for me the installation target device is called `nvme0n1` and it has 4 partitions:

1. a 498 MiB FAT32 EFI partition for the systemd bootloader
1. a 4096 MiB FAT32 partition for the Pop!_OS recovery system
1. a 479692MiB partition that contains the luks2 encrypted system files
1. a 4096 MiB swap partition for (encrypted) swap use

Let's have a closer look at the luks2-encrypted partition:

```sh
sudo cryptsetup luksDump /dev/nvme0n1p3
# LUKS header information
# Version:       	2
# Epoch:         	3
# Metadata area: 	16384 [bytes]
# Keyslots area: 	16744448 [bytes]
# UUID:          	e7e986dd-19b7-4535-98bf-8ba1760921f1
# Label:         	(no label)
# Subsystem:     	(no subsystem)
# Flags:       	(no flags)
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
# 	PBKDF:      argon2i
# 	Time cost:  7
# 	Memory:     1048576
# 	Threads:    4
# 	Salt:       53 34 4d ce b8 9d 9b 3c f3 94 bc f1 b4 36 5e d1 
# 	            e9 fb d1 f2 1e 5b a4 fb 42 12 23 f6 80 ad 9f c9 
# 	AF stripes: 4000
# 	AF hash:    sha256
# 	Area offset:32768 [bytes]
# 	Area length:258048 [bytes]
# 	Digest ID:  0
# Tokens:
# Digests:
#   0: pbkdf2
# 	Hash:       sha256
# 	Iterations: 126030
# 	Salt:       94 24 79 20 76 1b d3 72 6f 9f d9 0b 24 fe 92 db 
# 	            ac 16 47 67 29 ef 11 7c 56 2d 44 9e 31 ac e4 26 
# 	Digest:     b4 22 72 ae be 9c e1 82 2b d5 33 ae 01 db da a8 
# 	            35 23 0b 85 55 ac 00 ee 2f 43 e2 de 73 10 21 13 
```
So this basically uses the default options to encrypt a partition with luks (e.g. `cryptsetup luksFormat /dev/nvme0n1p3`). Let's have a look what is inside the encrypted partition:

```sh
sudo cryptsetup luksOpen /dev/nvme0n1p3 cryptdata
# Enter passphrase for /dev/nvme0n1p3:
ls /dev/mapper
# control  cryptdata  data-root
sudo pvs
#  PV                    VG   Fmt  Attr PSize    PFree
#  /dev/mapper/cryptdata data lvm2 a--  <468.43g    0 
sudo vgs
#  VG   #PV #LV #SN Attr   VSize    VFree
#  data   1   1   0 wz--n- <468.43g    0 
sudo lvs
#  LV   VG   Attr       LSize    Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
#  root data -wi-a----- <468.43g
sudo lsblk /dev/mapper/data-root -f
# NAME      FSTYPE FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINT
# data-root ext4   1.0         05f227c9-b2d5-4a8e-a297-9eaa58b45906
``` 
By default POP!_OS uses Logical Volume Management (LVM), where our encrypted partition (called `cryptdata`) is a physical volume that contains a volume group called `data`. Inside the volume group there is a logical volume called `root` that contains our system files. This so-called `root partition` is formatted with ext4. The LVM is actually a bit of an overkill for my personal use case, but I'll stick to it as otherwise the installer cannot access the luks2 partition.

Okay, let's close everything:
```sh
sudo cryptsetup luksClose /dev/mapper/data-root
sudo cryptsetup luksClose /dev/mapper/cryptdata
ls /dev/mapper
# control
```
and do the second install.


## Step 2: Install Pop!_OS using the `Custom (Advanced)` option
Now let's open again the installer from the dock, select the region, language and keyboard layout. Then choose `Custom (Advanced)`. You will see your partitioned hard disk:

- Click on the first partition, activate `Use partition`, activate `Format`, Use as `Boot /boot/efi`, Filesystem: `fat32`.
- Click on the second partition, activate `Use partition`, activate `Format`, Use as `Custom` and enter `/recovery`, Filesystem: `fat32`.
- Click on the third and largest partition. A `Decrypt This Partition` dialog opens, enter your luks password and hit `Decrypt`. A new line is displayed `LVM data`. Click on this partition, activate `Use partition`, activate `Format`, Use as `Root (/)` , Filesystem: `btrfs`.
- Click on the fourth partition, activate `Use partition`, Use as `Swap`.

*If you have other partitions, check their types and use; particularly, deactivate other EFI partitions.*

Recheck everything (check the partitions where there is a black checkmark) and hit `Erase and Install`. Follow the steps to create a user account and to write the changes to the disk. Once the installer finishes do NOT **Restart Device**.

## Step 3: Post-Installation steps

Open a terminal and switch to an interactive root session:
```bash
sudo -i
```
You might find maximizing the terminal window is helpful for working with the command-line.
### Mount the btrfs top-level root filesystem

Let's mount our root partition (the top-level btrfs volume always has root-id 5), but with mount options that optimize performance and durability on SSD or NVME drives:
```bash
cryptsetup luksOpen /dev/nvme0n1p3 cryptdata
# Enter passphrase for /dev/nvme0n1p3
mount -o subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async /dev/mapper/data-root /mnt
```
 I have found that there is some general agreement to use the following mount options, namely:

- `ssd`: use SSD specific options for optimal use on SSD and NVME
- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro's minimal iso)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms; however, zstd has become the best performing candidate.
- `discard=async`: [Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard)

We will later also append these mount options to the fstab, but it is good practice to already make use of these optimizations for moving the system files into subvolumes.

### Create btrfs subvolumes `@` and `@home`

Now we will first create the subvolume `@` and move all files and folders from the top-level filesystem into `@`. Note that as we use the optimized mount options like compression, these will be already applied during the moving process:
```bash
btrfs subvolume create /mnt/@
# Create subvolume '/mnt/@'
cd /mnt
ls | grep -v @ | xargs mv -t @ #move all files and folders to /mnt/@
ls -a /mnt
# . .. @
```
Now let's create another subvolume called `@home` and move the user folder from `/mnt/@/home/` into `@home`:
```bash
btrfs subvolume create /mnt/@home
# Create subvolume '/mnt/@home'
mv /mnt/@/home/* /mnt/@home/
ls -a /mnt/@/home
# . ..
ls -a /mnt/@home
# . .. wmutschl

btrfs subvolume list /mnt
# ID 264 gen 339 top level 5 path @
# ID 265 gen 340 top level 5 path @home
```

### Changes to fstab
We need to adapt the `fstab` to
- mount `/` to the `@` subvolume
- mount `/home` to the `@home` subvolume
- make use of optimized btrfs mount options

So open it with a text editor, e.g.:
```bash
nano /mnt/@/etc/fstab
```
or use these `sed` commands
```bash
sed -i 's/btrfs  defaults/btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async/' /mnt/@/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/data-root)  /home  btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0" >> /mnt/@/etc/fstab
```
Either way your `fstab` should look like this:
```bash
cat /mnt/@/etc/fstab
# PARTUUID=6b533522-0c33-4f44-890f-4be275c5b06f  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=45bb9da4-9571-40bc-8f20-468332234a62  /recovery  vfat  umask=0077  0  0
# /dev/mapper/cryptswap  none  swap  defaults  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /home  btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
```
Note that your PARTUUID and UUID numbers will be different. The last two lines for `/` and `/home` are the important ones.

### Changes to crypttab
As we use `discard=async`, we need to add `discard` to the `crypttab`:

```sh
sed -i 's/luks/luks,discard/' /mnt/@/etc/crypttab
cat /mnt/@/etc/crypttab
# cryptdata UUID=c5b8099a-f035-47fb-939f-fa4ea770a403 none luks,discard
# cryptswap UUID=52de8233-c50b-4873-b586-9ab313d28b56 /dev/urandom swap,plain,offset=1024,cipher=aes-xts-plain64,size=512
```

### Adjust configuration of kernelstub
We need to adjust some settings for the systemd boot manager and also make sure these settings are not overwritten if we install or update kernels and modules. Namely, we need to add `rootflags=subvol=@` to the `"user"` kernel options of the kernelstub configuration file:

```bash
nano /mnt/@/etc/kernelstub/configuration
```
Here you need to add `rootflags=subvol=@` to the `"user"` kernel options. That is, your configuration file should look like this:
```sh
cat /mnt/@/etc/kernelstub/configuration
# {
#   "default": {
#     "kernel_options": [
#       "quiet",
#       "splash"
#     ],
#     "esp_path": "/boot/efi",
#     "setup_loader": false,
#     "manage_mode": false,
#     "force_update": false,
#     "live_mode": false,
#     "config_rev":3
#   },
#   "user": {
#     "kernel_options": [
#       "quiet",
#       "loglevel=0",
#       "systemd.show_status=false",
#       "splash",
#       "rootflags=subvol=@"
#     ],
#     "esp_path": "/boot/efi",
#     "setup_loader": true,
#     "manage_mode": true,
#     "force_update": false,
#     "live_mode": false,
#     "config_rev":3
#   }
# }
```
**VERY IMPORTANTLY: Don't forget the comma after `"splash"` (in the line above your added `"rootflags=subvol=@"` option) , otherwise you get errors when you later run `update-initramfs` (see below)!**


### Adjust configuration of systemd bootloader
We need to adjust some settings for the systemd boot manager, so let's mount our EFI partition
```bash
mount /dev/nvme0n1p1 /mnt/@/boot/efi
```

Add `rootflags=subvol=@` to last line of `Pop_OS_current.conf` either using a text editor or the following command
```bash
sed -i 's/splash/splash rootflags=subvol=@/' /mnt/@/boot/efi/loader/entries/Pop_OS-current.conf
cat /mnt/@/boot/efi/loader/entries/Pop_OS-current.conf
# title Pop!_OS
# linux /EFI/Pop_OS-UUID_of_data-root/vmlinuz.efi
# initrd /EFI/Pop_OS-UUID_of_data-root/initrd.img
# options root=UUID=UUID_of_data-root ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@
```
where `UUID_of_data-root` is the UUID of /dev/mapper/data-root.

Optionally, add a timeout to the systemd boot menu in order to easily access the recovery partition:
```bash
echo "timeout 2" >> /mnt/@/boot/efi/loader/loader.conf
cat /mnt/@/boot/efi/loader/loader.conf 
# default Pop_OS-current
# timeout 2
```



### Create a chroot environment and update initramfs

Now, let's create a chroot environment, which enables you to work directly inside your newly installed OS, without actually rebooting. For this, unmount the top-level root filesystem from `/mnt` and remount the subvolume `@` which we created for `/` to `/mnt`:
```bash
cd /
umount -l /mnt
mount -o defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async /dev/mapper/data-root /mnt
```
Then the following commands will put us into our system using chroot:
```bash
for i in /dev /dev/pts /proc /sys /run; do mount -B $i /mnt$i; done
chroot /mnt
```

Cool, you are now inside your system and we can check whether our `fstab` mounts everything correctly:
```bash
mount -av
# /boot/efi                : successfully mounted
# /recovery                : successfully mounted
# none                     : ignored
# /                        : ignored
# /home                    : successfully mounted
```
Looks good! Now we need to update the initramfs to make it aware of our changes:
```bash
update-initramfs -c -k all
```

Note that if you run into errors like this:
```sh
update-initramfs: Generating /boot/initrd.img-5.11.0-7620-generic
kernelstub.Config    : INFO     Looking for configuration...
Traceback (most recent call last):
  File "/usr/bin/kernelstub", line 244, in <module>
    main()
  File "/usr/bin/kernelstub", line 241, in main
    kernelstub.main(args)
  File "/usr/lib/python3/dist-packages/kernelstub/application.py", line 142, in main
    config = Config.Config()
  File "/usr/lib/python3/dist-packages/kernelstub/config.py", line 50, in __init__
    self.config = self.load_config()
  File "/usr/lib/python3/dist-packages/kernelstub/config.py", line 60, in load_config
    self.config = json.load(config_file)
  File "/usr/lib/python3.9/json/__init__.py", line 293, in load
    return loads(fp.read(),
  File "/usr/lib/python3.9/json/__init__.py", line 346, in loads
    return _default_decoder.decode(s)
  File "/usr/lib/python3.9/json/decoder.py", line 337, in decode
    obj, end = self.raw_decode(s, idx=_w(s, 0).end())
  File "/usr/lib/python3.9/json/decoder.py", line 353, in raw_decode
    obj, end = self.scan_once(s, idx)
json.decoder.JSONDecodeError: Expecting ',' delimiter: line 20 column 7 (char 363)
run-parts: /etc/initramfs/post-update.d//zz-kernelstub exited with return code 1
```
you probably forgot a comma after `"splash"` in the `/etc/kernelstub/configuration` file (see above).

## Step 4: Reboot, some checks, and update system

Now, it is time to exit the chroot - cross your fingers - and reboot the system:

```bash
exit
# exit
reboot now
```

If all went well you should see a single passphrase prompt (YAY!), where you enter the luks passphrase and your system boots. 

Now let's click through the welcome screen and open a terminal to see whether everything is set up correctly:

```bash
sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# none                     : ignored
# /                        : ignored
# /home                    : already mounted

sudo mount -v | grep /dev/mapper
# /dev/mapper/data-root on / type btrfs (rw,noatime,compress=zstd:3,ssd,discard=async,space_cache,commit=120,subvolid=265,subvol=/@)
# /dev/mapper/data-root on /home type btrfs (rw,noatime,compress=zstd:3,ssd,discard=async,space_cache,commit=120,subvolid=266,subvol=/@home)

sudo swapon
# NAME      TYPE      SIZE USED PRIO
# /dev/dm-2 partition   4G   0B   -2

sudo btrfs filesystem show /
# Label: none  uuid: 591dae2e-37ce-42c9-8ceb-5b124658ca6a
# 	Total devices 1 FS bytes used 8.15GiB
# 	devid    1 size 468.43GiB used 10.02GiB path /dev/mapper/data-root

sudo btrfs subvolume list /
# ID 265 gen 82 top level 5 path @
# ID 266 gen 82 top level 5 path @home
```

If all look's good, let's update and upgrade the system:

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
flatpak update
```

If you installed on a SSD or NVME, enable `fstrim.timer` as [both fstrim and discard=async mount option can peacefully co-exist](https://www.phoronix.com/scan.php?page=news_item&px=Fedora-Btrfs-Opts-Discard-Comp):
```sh
sudo systemctl enable fstrim.timer
```
Again, for [SSD trimming to work properly](https://www.heise.de/ct/hotline/Linux-Verschluesselte-SSD-trimmen-2405875.html), it is important that you add `discard` to your `crypttab` (see above). Also check whether you find `issue_discards=1` in `/etc/lvm/lvm.conf` (which should be correct by default):
```sh
sudo grep "issue_discards" /etc/lvm/lvm.conf 
# 	# Configuration option devices/issue_discards.
# 	issue_discards = 1
```

Now reboot:
```bash
sudo reboot now
```


## Step 5: automatic snapshots and backups with btrfs using BTRBK

### Step 5a: preparations
First I create a mount point `/btrfs_pool` for the top-level root of my btrfs partition:
```sh
sudo mkdir /btrfs_pool
```
Next I add an entry to the fstab to mount this at boot time:
```sh
echo "UUID=$(blkid -s UUID -o value /dev/mapper/data-root)  /btrfs_pool  btrfs  defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0" | sudo tee -a /etc/fstab
cat /etc/fstab
# PARTUUID=6b533522-0c33-4f44-890f-4be275c5b06f  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=45bb9da4-9571-40bc-8f20-468332234a62  /recovery  vfat  umask=0077  0  0
# /dev/mapper/cryptswap  none  swap  defaults  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /home  btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /btrfs_pool  btrfs  defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
```
The last line is added which mounts the top-level (subvolid=5, NOT subvol!) to `/btrfs_pool`. Let's try the fstab and mount everything:
```sh
sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# none                     : ignored
# /                        : ignored
# /home                    : already mounted
# /btrfs_pool              : successfully mounted
```
BTRBK needs a folder under the top-level where it stores the snapshots, let's call this folder `_btrbk_snap` and create it:
```sh
sudo mkdir /btrfs_pool/_btrbk_snap
ls /btrfs_pool
# @  _btrbk_snap  @home
```

### Step 5b: install and configure BTRBK
Install BTRBK from the repos:
```bash
sudo apt install -y btrbk
```
Next I create the following configuration file:
```sh
mkdir -p $HOME/scripts
nano $HOME/scripts/precision-btrbk.conf
```
My configuration file (just for snapshots) looks like this:
```sh
transaction_log         /var/log/btrbk.log
lockfile                /var/lock/btrbk.lock
timestamp_format        long

snapshot_dir            _btrbk_snap
snapshot_preserve_min   3h
snapshot_preserve       6h 5d 3w 1m

volume /btrfs_pool
  snapshot_create  always
  subvolume @
  subvolume @home
```
This looks into `/btrfs_pool` and creates snapshots for the subvolumes `@` and `@home` into the directory `/btrfs_pool/_btrbk_snap`. All snapshots are preserved for at least 3 hours, while the usual retention strategy is to keep 6 hourly, 5 daily, 3 weekly and 1 monthly snapshot. Let's test this:

```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf dryrun
# --------------------------------------------------------------------------------
# Backup Summary (btrbk command line client, version 0.27.1)
#     Date:   Mon Dec 13 21:10:45 2021
#     Config: /home/wmutschl/scripts/precision-btrbk.conf
#     Dryrun: YES
# Legend:
#     ===  up-to-date subvolume (source snapshot)
#     +++  created subvolume (source snapshot)
#     ---  deleted subvolume
#     ***  received subvolume (non-incremental)
#     >>>  received subvolume (incremental)
# --------------------------------------------------------------------------------
# /btrfs_pool/@
# +++ /btrfs_pool/_btrbk_snap/@.20211213T2110
# /btrfs_pool/@home
# +++ /btrfs_pool/_btrbk_snap/@home.20211213T2110
# 
# NOTE: Dryrun was active, none of the operations above were actually executed!
```
If there was no error, let's actually run this to create our first snapshots (this should take a fraction of a second) and see whether they are stored correctly:
```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf run
# --------------------------------------------------------------------------------
# Backup Summary (btrbk command line client, version 0.27.1)
#     Date:   Mon Dec 13 21:10:59 2021
#     Config: /home/wmutschl/scripts/precision-btrbk.conf
# 
# Legend:
#     ===  up-to-date subvolume (source snapshot)
#     +++  created subvolume (source snapshot)
#     ---  deleted subvolume
#     ***  received subvolume (non-incremental)
#     >>>  received subvolume (incremental)
# --------------------------------------------------------------------------------
# /btrfs_pool/@
# +++ /btrfs_pool/_btrbk_snap/@.20211213T2110
# 
# /btrfs_pool/@home
# +++ /btrfs_pool/_btrbk_snap/@home.20211213T2110

ls /btrfs_pool/_btrbk_snap
# @.20211213T2110  @home.20211213T2110

sudo btrfs subvolume list /
# ID 265 gen 153 top level 5 path @
# ID 266 gen 154 top level 5 path @home
# ID 269 gen 154 top level 5 path _btrbk_snap/@.20211213T2110
# ID 270 gen 154 top level 5 path _btrbk_snap/@home.20211213T2110
```

### Step 5c: create systemd timer for BTRBK to run every hour
On servers that run constantly I usually use the `crontab` for automatic snapshots with BTRBK; however, on my laptop I use a systemd timer instead. First let's adapt/create the btrbk timer: `sudo nano /lib/systemd/system/btrbk.timer` which looks like this:
```sh
[Unit]
Description=btrbk hourly snapshots and backup

[Timer]
OnCalendar=hourly
AccuracySec=10min
Persistent=true

[Install]
WantedBy=timers.target
```

Second let's adapt the service `sudo nano /lib/systemd/system/btrbk.service` which looks like this:
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
and checkout if it works (tip: you can exit the log outputs by writing `:q` or hitting `CTRL+C`)):
```
sudo systemctl start btrbk.service
sudo systemctl status btrbk.service
# ○ btrbk.service - btrbk snapshots and backup
#      Loaded: loaded (/lib/systemd/system/btrbk.service; static)
#      Active: inactive (dead)
#        Docs: man:btrbk(1)
# 
# Dec 13 21:24:22 pop-os btrbk[6699]:     ---  deleted subvolume
# Dec 13 21:24:22 pop-os btrbk[6699]:     ***  received subvolume (non-incremental)
# Dec 13 21:24:22 pop-os btrbk[6699]:     >>>  received subvolume (incremental)
# Dec 13 21:24:22 pop-os btrbk[6699]: --------------------------------------------------------->
# Dec 13 21:24:22 pop-os btrbk[6699]: /btrfs_pool/@
# Dec 13 21:24:22 pop-os btrbk[6699]: +++ /btrfs_pool/_btrbk_snap/@.20211213T2124
# Dec 13 21:24:22 pop-os btrbk[6699]: /btrfs_pool/@home
# Dec 13 21:24:22 pop-os btrbk[6699]: +++ /btrfs_pool/_btrbk_snap/@home.20211213T2124
# Dec 13 21:24:22 pop-os systemd[1]: btrfs-btrbk-systemd.service: Deactivated successfully.
# Dec 13 21:24:22 pop-os systemd[1]: Finished btrbk snapshots and backup.

cat /var/log/btrbk.log
# 2021-12-13T21:24:22+0100 startup v0.27.1 - - - # btrbk command line client, version 0.27.1
# 2021-12-13T21:24:22+0100 snapshot starting /btrfs_pool/_btrbk_snap/@.20211213T2124 /btrfs_pool/@ - -
# 2021-12-13T21:24:22+0100 snapshot success /btrfs_pool/_btrbk_snap/@.20211213T2124 /btrfs_pool/@ - -
# 2021-12-13T21:24:22+0100 snapshot starting /btrfs_pool/_btrbk_snap/@home.20211213T2124 /btrfs_pool/@home - -
# 2021-12-13T21:24:22+0100 snapshot success /btrfs_pool/_btrbk_snap/@home.20211213T2124 /btrfs_pool/@home - -
# 2021-12-13T21:24:22+0100 finished success - - - -

ls /btrfs_pool/_btrbk_snap
# @.20211213T2110  @home.20211213T2110
# @.20211213T2124  @home.20211213T2124
```
Check if snapshots are created and if any errors occured. If all is well, then enable the timer:
```
sudo systemctl enable btrbk.timer
# Created symlink /etc/systemd/system/timers.target.wants/btrbk.timer → /lib/systemd/system/btrbk.timer.
sudo systemctl start btrbk.timer
sudo systemctl daemon-reload
sudo systemctl list-timers --all
```
You should see the following line (tip: you can exit by inserting `:q` or clicking `CTRL+C`):
```
NEXT                        LEFT          LAST                        PASSED       UNIT           ACTIVATES                     
Mon 2021-12-13 22:00:00 CET 33min left    n/a                         n/a          btrbk.timer    btrbk.service
```
Recheck the hourly timer after an hour (or 33min in my case) to make sure everything is working:
```
sudo systemctl list-timers --all
cat /var/log/btrbk.log
ls /btrfs_pool/_btrbk_snap
```
Make sure the snapshots are created without errors.

### Step 5d (optional): Mount an encrypted backup disk as btrfs send/receive target
I use the internal SSD as a backup disk to receive the incremental btrfs snapshots. So let's create a GPT table on it, create an encrypted partition and format it with the btrfs filesystem. I usually use GParted for this (after installing it); however, you can also use command-line tools like `parted`, e.g.:
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
sudo cryptsetup luksOpen /dev/sda1 cryptbackup
# Enter passphrase for /dev/sda1: 

sudo mkfs.btrfs /dev/mapper/cryptbackup 
# btrfs-progs v5.10.1 
# See http://btrfs.wiki.kernel.org for more information.
# 
# Detected a SSD, turning off metadata duplication.  Mkfs with -m dup if you want to force metadata duplication.
# Label:              (null)
# UUID:               6f462de9-8148-4b61-b390-c1b9038cb367
# Node size:          16384
# Sector size:        4096
# Filesystem size:    465.75GiB
# Block group profiles:
#   Data:             single            8.00MiB
#   Metadata:         single            8.00MiB
#   System:           single            4.00MiB
# SSD detected:       yes
# Incompat features:  extref, skinny-metadata
# Runtime features:   
# Checksum:           crc32c
# Number of devices:  1
# Devices:
#    ID        SIZE  PATH
#     1   465.75GiB  /dev/mapper/cryptbackup
```

Let's create a mount point `/btrfs_backup` for this disk and update the fstab:

```sh
sudo mkdir /btrfs_backup
```
Next I add an entry to the fstab to mount this at boot time:
```sh
echo "UUID=$(blkid -s UUID -o value /dev/mapper/cryptbackup)  /btrfs_backup  btrfs  defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0" | sudo tee -a /etc/fstab
cat /etc/fstab
# PARTUUID=6b533522-0c33-4f44-890f-4be275c5b06f  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=45bb9da4-9571-40bc-8f20-468332234a62  /recovery  vfat  umask=0077  0  0
# /dev/mapper/cryptswap  none  swap  defaults  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async  0  0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /home  btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
# UUID=591dae2e-37ce-42c9-8ceb-5b124658ca6a  /btrfs_pool  btrfs  defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
# UUID=6f462de9-8148-4b61-b390-c1b9038cb367  /btrfs_backup  btrfs  defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async   0 0
```
The last line is added which mounts the top-level (subvolid=5, NOT subvol!) to `/btrfs_backup`. Let's try the fstab and mount everything:
```sh
sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# none                     : ignored
# /                        : ignored
# /home                    : already mounted
# /btrfs_pool              : successfully mounted
# /btrfs_backup            : successfully mounted
```

I want my system to automatically unlock my backup disk such that I need to type my luks passphrase only once (this step is optional, but recommended). So let's create a key-file, secure it, and add it to our luks partition of the backup disk:

```bash
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

```bash
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" | sudo tee -a /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" | sudo tee -a /etc/initramfs-tools/initramfs.conf
```
These commands will harden the security options in the intiramfs configuration file and hook (*not sure if this is also needed for systemd bootloader?!?*).

Next, add the keyfile to your `crypttab`:

```bash
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

BTRBK needs folders under the top-level of your backup disk where it stores the received snapshots, let's call these folders `@` and `@home` and create it:
```sh
sudo mkdir /btrfs_backup/@
sudo mkdir /btrfs_backup/@home
ls /btrfs_backup
# @  @home
```

We need to also change the configuration file used for BTRBK: `nano $HOME/scripts/precision-btrbk.conf`:
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
  subvolume @
  subvolume @home
```

Let's first run it in dry mode:

```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf dryrun
```
If there was no error, run it:
```sh
sudo btrbk -c $HOME/scripts/precision-btrbk.conf run --progress
```
This will take a while, because the initial backup is transferred to your backup disk. All other snapshots will be sent and received incrementially.


### Step 5e (optional): Automatic snapshots for any apt operation

TBA


Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *btrbk* will create a snapshot of your system, but these won't be sent to your backup disk right away, but only every hour.

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**

**Check out my [Pop!_OS post-installation steps](../pop-os-post-install).**

**If you ever need to rollback your system, checkout my [Recovery and system rollback](../../timeshift).**