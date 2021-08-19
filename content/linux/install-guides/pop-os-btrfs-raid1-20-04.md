---
title: 'Pop!_OS 20.04: installation guide with btrfs-LVM-luks-RAID1 and auto-apt snapshots with Timeshift'
#linktitle: Pop!_OS 20.04 btrfs-luks-raid1
summary: In this guide I will walk you through the installation procedure to get a Pop!_OS 20.04 system with a luks-encrypted partition which contains a LVM with a logical volume for the root filesystem that is formatted with btrfs and contains a subvolume @ for / and a subvolume @home for /home. The system is set up in a RAID1 managed by the btrfs filesystem. I will show how to optimize the btrfs mount options and how to setup encrypted swap partitions which work with hibernation. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. The recovery system of Pop!_OS is also installed to both disks and accessible via the systemd bootloaders. Due to the RAID1 managed by btrfs you get redundancy of your data.
toc: true
type: book
#date: "2020-04-21"
draft: false
weight: 29
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

```md
{{< youtube teD1bQ7rn9c >}}
```
*Note that this written guide is an updated version of the video and contains much more information.*


## Overview 
Since a couple of months, I am exclusively using btrfs as my filesystem on all my systems, see [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Pop!_OS 20.04 with the following structure:

- a btrfs-LVM-inside-luks partition for the root filesystem on two hard disks in a RAID1 managed by btrfs
  - the btrfs logical volume contains a subvolume `@` for `/` and a subvolume `@home` for `/home`. Note that the Pop!_OS installer does not create any subvolumes on btrfs, so we need to do this manually.
- an encrypted swap partition
- an unencrypted EFI partition for the systemd bootloader duplicated on both disks
- an unencrypted partition for the Pop!_OS recovery system duplicated on both disks
- automatic system snapshots and easy rollback similar to *zsys* using:
   - [Timeshift](https://github.com/teejee2008/timeshift) which will regularly take (almost instant) snapshots of the system
   - [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) which will automatically run Timeshift on any APT operation and also keep a backup of your EFI partition inside the snapshot
- If you don't need RAID1, follow this guide: [Pop!_OS 20.04 btrfs-luks](../pop-os-btrfs-20-04)

With this setup you basically get the same comfort of Ubuntu's 20.04's ZFS and *zsys* initiative, but with much more flexibility and comfort due to the awesome [Timeshift](https://github.com/teejee2008/timeshift) program, which saved my bacon quite a few times. This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).

**If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift/).**
In the video, I also show what to do if your RAID1 is broken.

## Step 0: General remarks
**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**

So, let's spin up a virtual machine with 4 cores, 8 GB RAM, and two 64GB disk using e.g. my fork of the awesome bash script [quickemu](https://github.com/wmutschl/quickemu) to automatically create 2 disks. I can confirm that the installation works equally well on my Dell Precision 7520 (RAID1 between a SSD and NVME).

This tutorial is made with Pop!_OS 20.04 from https://system76.com/pop copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor). Other versions of Pop!_OS and other distributions that use Systemd boot manager should also work, see my other [installation guides](../../install-guides).

## Step 1: Boot the install, check UEFI mode and open an interactive root shell
Since most modern PCs have UEFI, I will cover only the UEFI installation (see the [References](../../references/#btrfs-installation-guides) on how to deal with Legacy installs). So, boot the installation medium in UEFI mode and choose `Try or install Pop!_OS`. Once the Live Desktop environment has started choose your language, region, and keyboard layout, then hit `Try Demo Mode`. Open a terminal (<kbd>META</kbd> + <kbd>T</kbd>) and run the following command:
```bash
mount | grep efivars
# efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)
```
to detect whether you are in UEFI mode. Now switch to an interactive root session:
```bash
sudo -i
```
You might find maximizing the terminal window is helpful for working with the command-line. Do not close this terminal window during the whole installation process until we are finished with everything.

## Step 2: Prepare partitions manually

### Create partition table and layout

First find out the name of your drive. For me the installation target device is called `vda` and I will use `vdb` for the RAID1 managed by btrfs:

```bash
lsblk
# NAME  MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
# loop0   7:0    0    2G  1 loop /rofs
# sr0    11:0    1  2.1G  0 rom  /cdrom
# sr1    11:1    1 1024M  0 rom  
# sr2    11:2    1 1024M  0 rom  
# vda   252:0    0   64G  0 disk 
# vdb   252:16   0   64G  0 disk 
```
You can also open `gparted` or have a look into the `/dev` folder to make sure what your hard drives are called. In most cases they are called `sda` and `sdb` for normal SSD and HDD, whereas for NVME storage the naming is `nvme0` and `nvme1`. Also note that there are no partitions or data on my hard drive, you should always double check which partition layout fits your use case, particularly if you dual-boot with other systems.

We'll now create a disk table and add three partitions on `vda` and `vdb`:
1. a 498 MiB FAT32 EFI partition for the systemd bootloader
2. a 4 GiB FAT32 partition for the Pop!_OS recovery system
3. a 4 GiB partition for encrypted swap use
4. a luks2 encrypted partition which contains a LVM with one logical volume formatted with btrfs, which will be our root filesystem

Some remarks:

- The LVM is actually a bit of an overkill for my typical use case, but otherwise the installer cannot access the luks partition.
- `/boot` will reside on the encrypted partition. The systemd bootloader is able to decrypt this at boot time.
- With btrfs I do not need any other partitions for e.g. `/home`, as we will use subvolumes instead. 
- As we plan to use RAID1 managed by btrfs, we cannot use swapfiles as these are not supported in RAID1.

Let's use `parted` for this (feel free to use `gparted` accordingly):

```bash
parted /dev/vda
  mklabel gpt
  mkpart primary fat32 2MiB 500MiB
  mkpart primary fat32 500MiB 4596MiB
  mkpart primary linux-swap 4596MiB 8692MiB
  mkpart primary 8692MiB 100%
  set 1 bios_grub on
  set 1 esp on
  set 3 swap on
  print
# Model: Virtio Block Device (virtblk)
# Disk /dev/vda: 68.7GB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# 
# Number  Start   End     Size    File system     Name     Flags
#  1      2097kB  524MB   522MB   fat32           primary  boot, esp
#  2      524MB   4819MB  4295MB  fat32           primary
#  3      4819MB  9114MB  4295MB  linux-swap(v1)  primary  swap
#  4      9114MB  68.7GB  59.6GB                  primary
  quit
```

And the same commands for `vdb`:
```bash
parted /dev/vdb
  mklabel gpt
  mkpart primary fat32 2MiB 500MiB
  mkpart primary fat32 500MiB 4596MiB
  mkpart primary linux-swap 4596MiB 8692MiB
  mkpart primary 8692MiB 100%
  set 1 bios_grub on
  set 1 esp on
  set 3 swap on
  print
# Model: Virtio Block Device (virtblk)
# Disk /dev/vdb: 68.7GB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# 
# Number  Start   End     Size    File system     Name     Flags
#  1      2097kB  524MB   522MB   fat32           primary  boot, esp
#  2      524MB   4819MB  4295MB  fat32           primary
#  3      4819MB  9114MB  4295MB  linux-swap(v1)  primary  swap
#  4      9114MB  68.7GB  59.6GB                  primary
  quit
```


### Create luks2 partitions, LVM and btrfs root filesystems

Pop!_OS uses the systemd bootloader, which can handle luks type 2 encryption just fine at boot time, so we can use the default options of `cryptsetup luksFormat` to format our `vda4` and `vdb4` partitions and map them to devices called `crypt_vda` and `crypt_vdb`:

```bash
cryptsetup luksFormat /dev/vda4
# WARNING!
# ========
# This will overwrite data on /dev/vda4 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vda4: 
# Verify passphrase:
cryptsetup luksFormat /dev/vdb4
# WARNING!
# ========
# This will overwrite data on /dev/vdb4 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vdb4: 
# Verify passphrase:

cryptsetup luksOpen /dev/vda4 crypt_vda
# Enter passphrase for /dev/vda4:
cryptsetup luksOpen /dev/vdb4 crypt_vdb
# Enter passphrase for /dev/vdb4:

ls /dev/mapper
# control  crypt_vda  crypt_vdb
```
Use very good passwords here. Now we need to create the LVM for the Pop!_OS installer:

- make `crypt_vda` and `crypt_vdb` physical volumes
- add new volume groups called `data_vda` and `data_vdb`
- create a logical volume inside both volume groups named `root`


These are also the steps the POP!_OS installer performs when you click `Clean install`, albeit with ext4 as the filesystem and another logical volume for encrypted swap. So here are the commands:

```bash
pvcreate /dev/mapper/crypt_vda
# Physical volume "/dev/mapper/crypt_vda" successfully created
pvcreate /dev/mapper/crypt_vdb
# Physical volume "/dev/mapper/crypt_vdb" successfully created

vgcreate data_vda /dev/mapper/crypt_vda
# Volume group "data_vda" successfully created
vgcreate data_vdb /dev/mapper/crypt_vdb
# Volume group "data_vdb" successfully created

lvcreate -n root -l 100%FREE data_vda
# Logical volume "root" created.
lvcreate -n root -l 100%FREE data_vdb
# Logical volume "root" created.

ls /dev/mapper/
# control  crypt_vda  crypt_vdb  data_vda-root  data_vdb-root
cryptsetup luksClose /dev/mapper/data_vda-root
cryptsetup luksClose /dev/mapper/data_vdb-root
cryptsetup luksClose /dev/mapper/crypt_vda
cryptsetup luksClose /dev/mapper/crypt_vdb
ls /dev/mapper
# control
```
`data_vda-root` will be the installation target for root during the graphical installer. We will use the Pop!_OS installer to format it to btrfs and install the system to it. After the installation we create the RAID1 with btrfs between `data_vda-root` and `data_vdb-root`, and also create two subvolumes: 

- `@` for `/`
- `@home` for `/home`
This is due to the fact that the Pop!_OS installer does not create any subvolumes by default, so we will do that manually. 

## Step 3: Install POP!_OS using the graphical installer

Now let's return to the installation process choose `Custom (Advanced)`. You will see your partitioned hard disk:

- Click on the first partition on vda, activate `Use partition`, activate `Format`, Use as `Boot /boot/efi`, Filesystem: `fat32`.
- Click on the second partition on vda, activate `Use partition`, activate `Format`, Use as `Custom` and enter `/recovery`, Filesystem: `fat32`.
- Click on the third partition on vda, activate `Use partition`, Use as `Swap`.
- Click on the fourth and largest partition on vda. A `Decrypt This Partition` dialog opens, enter your luks password and change the name to `crypt_vda`, hit `Decrypt`. A new line is displayed `LVM data_vda /dev/mapper/data_vda`. Click on this partition, activate `Use partition`, activate `Format`, Use as `Root (/)` , Filesystem: `btrfs`.
- Click on the fourth and largest partition on vdb. A `Decrypt This Partition` dialog opens, enter your luks password and change the name to `crypt_vdb`, hit `Decrypt`. A new line is displayed `LVM data_vdb /dev/mapper/data_vdb`.
- If you have other partitions, check their types and use; particularly, deactivate other EFI partitions.

Recheck everything (check the partitions where there is a black checkmark) and hit `Erase and Install` to write the changes to the disk. Once the installer finishes do NOT **Restart Device**, but return to your terminal.

## Step 4: Post-Installation steps

### Mount the btrfs top-level root filesystem

Let's mount our root partition (the top-level btrfs volume always has root-id 5), but with mount options that optimize performance and durability on SSD or NVME drives:
```bash
cryptsetup luksOpen /dev/vda4 crypt_vda
# Enter passphrase for /dev/vda4
cryptsetup luksOpen /dev/vdb4 crypt_vdb
# Enter passphrase for /dev/vdb4
mount -o defaults,subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/data_vda-root /mnt
```
I have found that there is some general agreement to use the following mount options, namely:
- `ssd`: use SSD specific options for optimal use on SSD and NVME
- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders (noatime also includes nodiratime)
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro's minimal iso)
- `compress=zstd`: compress allows us to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some phoronix test cases, zstd seems to be the better performing candidate.

### Create RAID 1 for root filesystem using btrfs balance
Currently btrfs uses only one device `/dev/mapper/data_vda-root`, so let's add our other encrypted device `/dev/mapper/data_vdb-root`:
```bash
btrfs filesystem show /mnt
# Label: none  uuid: c277ed84-e32f-4204-a211-1d80596e6e15
# 	Total devices 1 FS bytes used 5.08GiB
# 	devid    1 size 55.49GiB used 8.02GiB path /dev/mapper/data_vda-root

btrfs device add /dev/mapper/data_vdb-root /mnt

btrfs filesystem show /mnt
# Label: none  uuid: c277ed84-e32f-4204-a211-1d80596e6e15
# 	Total devices 2 FS bytes used 5.08GiB
# 	devid    1 size 55.49GiB used 8.02GiB path /dev/mapper/data_vda-root
# 	devid    2 size 55.49GiB used 0.00B path /dev/mapper/data_vdb-root

btrfs filesystem usage /mnt
# Overall:
#     Device size:		 110.98GiB
#     Device allocated:	   8.02GiB
#     Device unallocated:	 102.96GiB
#     Device missing:		     0.00B
#     Used:			   5.27GiB
#     Free (estimated):	 104.07GiB	(min: 52.59GiB)
#     Data ratio:		   1.00
#     Metadata ratio:		   2.00
#     Global reserve:		  14.70MiB	(used: 0.00B)
# 
# Data,single: Size:6.01GiB, Used:4.90GiB (81.52%)
#    /dev/mapper/data_vda-root	   6.01GiB
# 
# Metadata,DUP: Size:1.00GiB, Used:191.64MiB (18.71%)
#    /dev/mapper/data_vda-root	   2.00GiB
# 
# System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
#    /dev/mapper/data_vda-root	  16.00MiB
# 
# Unallocated:
# /dev/mapper/data_vda-root	  47.47GiB
# /dev/mapper/data_vdb-root	  55.49GiB
```
Note, however, that on the second device there is no data yet (see the "single" and "DUP" flags of the above "usage" command). We need to move the data chunks around to have a working RAID1 and btrfs has a balance command just for this case: "A balance passes all data in the filesystem through the allocator again. It is primarly intended to rebalance the data in the filesystem across the devices when a device eis added or removed. A balance will regenerate missing copies for the redundant *RAID* levels, if a device has failed". 
```bash
btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt
# Done, had to relocate 9 out of 9 chunks

btrfs filesystem usage /mnt
# Overall:
#     Device size:		 110.98GiB
#     Device allocated:	  18.06GiB
#     Device unallocated:	  92.92GiB
#     Device missing:		   0.00B
#     Used:			  10.18GiB
#     Free (estimated):	  48.56GiB	(min: 48.56GiB)
#     Data ratio:		   2.00
#     Metadata ratio:		   2.00
#     Global reserve:		  18.05MiB	(used: 0.00B)
# 
# Data,RAID1: Size:7.00GiB, Used:4.90GiB (69.97%)
#    /dev/mapper/data_vda-root	   7.00GiB
#    /dev/mapper/data_vdb-root	   7.00GiB
# 
# Metadata,RAID1: Size:2.00GiB, Used:194.98MiB (9.52%)
#    /dev/mapper/data_vda-root	   2.00GiB
#    /dev/mapper/data_vdb-root	   2.00GiB
# 
# System,RAID1: Size:32.00MiB, Used:16.00KiB (0.05%)
#    /dev/mapper/data_vda-root	  32.00MiB
#    /dev/mapper/data_vdb-root	  32.00MiB
# 
# Unallocated:
#    /dev/mapper/data_vda-root	  46.46GiB
#    /dev/mapper/data_vdb-root	  46.46GiB
```
You can monitor the progress in a new terminal using `sudo btrfs balance status /mnt`. Rarely, one gets an ERROR "out of space" or the output of `sudo btrfs filesystem usage /mnt` still shows "Data,single" or "Metadata,single" (instead of the "RAID1" tag like above), then you should try to run with different values for "dusage" and "musage", starting with e.g. 90:
```bash
btrfs balance start -dconvert=raid1 -mconvert=raid1 -dusage=95 -musage=95 /mnt
btrfs filesystem usage /mnt
```
and try to lower values for dusage and musage by 5 (one at a time), until there is the "RAID1" tag everywhere and all chunks are reallocated. Note also that you cannot have a swapfile in a RAID1, so deactivate and delete it, if you have one for some reason.

### Create btrfs subvolumes `@` and `@home`

Now we will first create the subvolume `@` and move all files and folders from the top-level filesystem into it. Note that as we use the optimized mount options like compression, these will be applied during the moving process:
```bash
cd /mnt
btrfs subvolume create /mnt/@
# Create subvolume '/mnt/@'
ls | grep -v @ | xargs mv -t @
ls /mnt
# @
cd /
```
Now let's create another subvolume `@home` in order to mount `/home` to it. Note that the Pop!_OS installer has not created a user yet, so there is nothing in `/home` we need to copy over.
```bash
btrfs subvolume create /mnt/@home
# Create subvolume '/mnt/@home'
btrfs subvolume list /mnt
# ID 269 gen 118 top level 5 path @
# ID 270 gen 118 top level 5 path @home
```

Now we need to adapt the mount options in `fstab` with a text editor, e.g.:
```bash
nano /mnt/@/etc/fstab
```
 or use these `sed` and `echo` commands:
```bash
sed -i '/cryptswap/d' /mnt/@/etc/fstab #temporarily remove the cryptswap line
sed -i 's/defaults/defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd/' /mnt/@/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/data_vda-root)   /home   btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0 0" >> /mnt/@/etc/fstab
echo "/dev/mapper/cryptswap  none  swap  defaults  0  0" >> /mnt/@/etc/fstab #add the cryptswap file back
```
Either way your `fstab` should look like this:
```bash
cat /mnt/@/etc/fstab
# PARTUUID=7109bb96-1c90-48bf-b290-a475996aa97b  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=6316f309-81a6-476b-b804-ae315d5e5ae3  /recovery  vfat  umask=0077  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15   /home   btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0 0
# /dev/mapper/cryptswap  none  swap  defaults  0  0
```
Note that the mount options for `@` and `@home` are the same.


### Create a chroot environment and enter your system

Now, let's create a chroot environment, which enables you to work directly inside your newly installed OS, without actually rebooting. For this, unmount the top-level root filesystem from `/mnt` and remount the subvolume `@` which we created for `/` to `/mnt`:
```bash
cd /
umount -l /mnt
mount -o defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/data_vda-root /mnt
ls /mnt
# bin   dev  home           lib    lib64   media  opt   recovery  run   srv  tmp  var
# boot  etc  installer.log  lib32  libx32  mnt    proc  root      sbin  sys  usr
```
Then the following commands put us into our system using chroot:
```bash
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo cp /etc/resolv.conf /mnt/etc/
sudo chroot /mnt
```

Cool, you are now inside your system and we can check whether our `fstab` mounts everything correctly:
```bash
mount -av
# /boot/efi                : successfully mounted
# /recovery                : successfully mounted
# /                        : ignored
# /home                    : successfully mounted
# none                     : ignored
```
Looks good! Now we need to adapt some other stuff.

### Adjust configuration of crypttab, systemd bootloader and kernelstub
We need to adjust settings for the `crypttab` and the configuration files of the systemd bootloader and the kernelstub. Also we need to make sure these settings are not overwritten, if we e.g. install new kernels or update modules. Let's do this in our chroot environment.

1. Add our second RAID1 drive to the `crypttab`:
```bash
echo "crypt_vdb UUID=$(blkid -s UUID -o value /dev/vdb4) none luks" >> /etc/crypttab
cat /etc/crypttab
# cryptswap UUID=03019356-3691-4002-a013-be15f291cde2 /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# crypt_vda UUID=9fc916b2-bdd8-4fbd-b557-4c4366f8cd63 none luks
# crypt_vdb UUID=93fc3643-a687-4a1c-9859-409b090448b9 none luks
```

2. Add a timeout to the systemd boot menu in order to easily access the recovery partition:
```bash
echo "timeout 2" >> /boot/efi/loader/loader.conf
cat /boot/efi/loader/loader.conf 
# default Pop_OS-current
# timeout 2
```

3. Add `rootflags=subvol=@` to last line of `Pop_OS_current.conf` either using a text editor or the following command
```bash
sed -i 's/splash/splash rootflags=subvol=@/' /boot/efi/loader/entries/Pop_OS-current.conf
cat /boot/efi/loader/entries/Pop_OS-current.conf
# title Pop!_OS
# linux /EFI/Pop_OS-c277ed84-e32f-4204-a211-1d80596e6e15/vmlinuz.efi
# initrd /EFI/Pop_OS-c277ed84-e32f-4204-a211-1d80596e6e15/initrd.img
# options root=UUID=c277ed84-e32f-4204-a211-1d80596e6e15 ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@
```

4. Lastly, we need to add `rootflags=subvol=@` to the `"user"` kernel options of the kernelstub configuration file:
```bash
nano /etc/kernelstub/configuration
# add rootflags=subvol=@ to "user" kernel options
# don't forget the comma after "splash"

cat /etc/kernelstub/configuration
# {
# "default": {
#     "kernel_options": [
#       "quiet",
#       "splash"
#     ],
#     "esp_path": "/boot/efi",
#     "setup_loader": false,
#     "manage_mode": false,
#     "force_update": false,
#     "live_mode": false,
#     "config_rev": 3
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
#     "config_rev": 3
#   }
# }
```

5. Install `btrfs-progs`

```bash
apt install btrfs-progs
# Reading package lists... Done
# Building dependency tree       
# Reading state information... Done
# The following additional packages will be installed:
#   liblzo2-2
# Suggested packages:
#   duperemove
# The following NEW packages will be installed:
#   btrfs-progs liblzo2-2
# 0 upgraded, 2 newly installed, 0 to remove and 0 not upgraded.
# Need to get 705 kB of archives.
# After this operation, 4292 kB of additional disk space will be used.
# Do you want to continue? [Y/n] Y
# Get:1 http://us.archive.ubuntu.com/ubuntu focal/main amd64 liblzo2-2 amd64 2.10-2 [50.8 kB]
# Get:2 http://us.archive.ubuntu.com/ubuntu focal/main amd64 btrfs-progs amd64 5.4.1-2 [654 kB]
# Fetched 705 kB in 1s (693 kB/s)  
# Selecting previously unselected package liblzo2-2:amd64.
# (Reading database ... 208003 files and directories currently installed.)
# Preparing to unpack .../liblzo2-2_2.10-2_amd64.deb ...
# Unpacking liblzo2-2:amd64 (2.10-2) ...
# Selecting previously unselected package btrfs-progs.
# Preparing to unpack .../btrfs-progs_5.4.1-2_amd64.deb ...
# Unpacking btrfs-progs (5.4.1-2) ...
# Setting up liblzo2-2:amd64 (2.10-2) ...
# Setting up btrfs-progs (5.4.1-2) ...
# update-initramfs: deferring update (trigger activated)
# Processing triggers for man-db (2.9.1-1) ...
# Processing triggers for initramfs-tools (0.136ubuntu6) ...
# update-initramfs: Generating /boot/initrd.img-5.4.0-7624-generic
# kernelstub.Config    : INFO     Looking for configuration...
# kernelstub           : INFO     System information: 
# 
#     OS:..................Pop!_OS 20.04
#     Root partition:....../dev/dm-1
#     Root FS UUID:........c277ed84-e32f-4204-a211-1d80596e6e15
#     ESP Path:............/boot/efi
#     ESP Partition:......./dev/vda1
#     ESP Partition #:.....1
#     NVRAM entry #:.......-1
#     Boot Variable #:.....0000
#     Kernel Boot Options:.quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@
#     Kernel Image Path:.../boot/vmlinuz-5.4.0-7624-generic
#     Initrd Image Path:.../boot/initrd.img-5.4.0-7624-generic
#     Force-overwrite:.....False
# 
# kernelstub.Installer : INFO     Copying Kernel into ESP
# kernelstub.Installer : INFO     Copying initrd.img into ESP
# kernelstub.Installer : INFO     Setting up loader.conf configuration
# kernelstub.Installer : INFO     Making entry file for Pop!_OS
# kernelstub.Installer : INFO     Backing up old kernel
# kernelstub.Installer : INFO     No old kernel found, skipping
```

Note that this has also updated the initramfs, but to just be sure, run it again:
```bash
update-initramfs -c -k all
```

## Step 5: Reboot, some checks, and update system

Now, it is time to exit the chroot - cross your fingers - and reboot the system:

```bash
exit
# exit
reboot now
```

If all went well you should see a passphrase prompt for `crypt_vda` and one for `crypt_vdb`, where you enter the corresponding luks passphrases and your system boots. 

Now let's click through the welcome screen and create a user account. Let's open up a terminal to see whether everything is set up correctly:

```bash
sudo cat /etc/crypttab
# cryptswap UUID=03019356-3691-4002-a013-be15f291cde2 /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# crypt_vda UUID=9fc916b2-bdd8-4fbd-b557-4c4366f8cd63 none luks
# crypt_vdb UUID=93fc3643-a687-4a1c-9859-409b090448b9 none luks

sudo cat /etc/fstab
# PARTUUID=7109bb96-1c90-48bf-b290-a475996aa97b  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=6316f309-81a6-476b-b804-ae315d5e5ae3  /recovery  vfat  umask=0077  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15   /home   btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0 0
# /dev/mapper/cryptswap  none  swap  defaults  0  0

sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# /                        : ignored
# /home                    : already mounted
# none                     : ignored

sudo mount -v | grep data_vd
# /dev/mapper/data_vda-root on / type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=269,subvol=/@)
# /dev/mapper/data_vda-root on /home type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=270,subvol=/@home)

sudo swapon
# NAME      TYPE      SIZE USED PRIO
# /dev/dm-4 partition   4G   0B   -2

sudo btrfs filesystem show /
# Label: none  uuid: c277ed84-e32f-4204-a211-1d80596e6e15
# 	Total devices 2 FS bytes used 4.45GiB
# 	devid    1 size 55.49GiB used 7.03GiB path /dev/mapper/data_vda-root
#       devid    2 size 55.49GiB used 7.03GiB path /dev/mapper/data_vdb-root

sudo btrfs subvolume list /
# ID 269 gen 538 top level 5 path @
# ID 270 gen 528 top level 5 path @home
```
If all look's good, let's update and upgrade the system:

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
```
Optionally, if you installed on a SSD and NVME, enable `fstrim.timer` as we did not add `discard` to the `crypttab`. This is due to the fact that [Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard) is quite new, but 20.04 still runs kernel 5.4, it is better to enable the `fstrim.timer` systemd service:
```bash
sudo systemctl enable fstrim.timer
```

Now reboot:
```bash
sudo reboot now
```

## Step 6: Create degraded boot entry
1. Let's go into root mode and export the UUID and PARTUUID of our recovery partitions into environmental variables for easy use later on:
```bash
sudo -i
export UUID_vda2=$(blkid -s UUID -o value /dev/vda2)
export PARTUUID_vda2=$(blkid -s PARTUUID -o value /dev/vda2)
export UUID_vdb2=$(blkid -s UUID -o value /dev/vdb2)
export PARTUUID_vdb2=$(blkid -s PARTUUID -o value /dev/vdb2)
export UUID_root=$(blkid -s UUID -o value /dev/mapper/data_vda-root)
```

Let's create a boot entry in case the RAID1 is broken, i.e. use degraded mode as rootflag:

```bash
cat <<EOF > /boot/efi/loader/entries/Pop_OS-degraded.conf
title Pop!_OS (degraded)
linux /EFI/Pop_OS-${UUID_root}/vmlinuz.efi
initrd /EFI/Pop_OS-${UUID_root}/initrd.img
options root=UUID=${UUID_root} ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@,degraded
EOF

cat /boot/efi/loader/entries/Pop_OS-degraded.conf
# title Pop!_OS (degraded)
# linux /EFI/Pop_OS-c277ed84-e32f-4204-a211-1d80596e6e15/vmlinuz.efi
# initrd /EFI/Pop_OS-c277ed84-e32f-4204-a211-1d80596e6e15/initrd.img
# options root=UUID=c277ed84-e32f-4204-a211-1d80596e6e15 ro quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@,degraded
```
Note that `/dev/mapper/data_vda-root` and `/dev/mapper/data_vdb-root` have the same UUID.


## Step 7: Make duplicate of recovery partition and create separate boot entries

Now let's clone the recovery partition `vda2` to `vdb2`:
```bash
dd if=/dev/vda2 of=/dev/vdb2 bs=1024 status=progress
# 4248138752 bytes (4.2 GB, 4.0 GiB) copied, 66 s, 64.4 MB/s 
# 4194303+1 records in
# 4194303+1 records out
# 4294966784 bytes (4.3 GB, 4.0 GiB) copied, 71.2853 s, 60.3 MB/s
```
and create two boot entries called "Pop!_OS recovery (vda)" and "Pop!_OS recovery (vdb)":

```bash
cat <<EOF > /boot/efi/loader/entries/Recovery-vda.conf
title Pop!_OS recovery (vda)
linux /EFI/Recovery-${UUID_vda2}/vmlinuz.efi
initrd /EFI/Recovery-${UUID_vda2}/initrd.gz
options  boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-${UUID_vda2} live-media=/dev/disk/by-partuuid/${PARTUUID_vda2} noprompt 
EOF
cat /boot/efi/loader/entries/Recovery-vda.conf 
# title Pop!_OS recovery (vda)
# linux /EFI/Recovery-C419-37C6/vmlinuz.efi
# initrd /EFI/Recovery-C419-37C6/initrd.gz
# options  boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-C419-37C6 live-media=/dev/disk/by-partuuid/6316f309-81a6-476b-b804-ae315d5e5ae3 noprompt 

cat <<EOF > /boot/efi/loader/entries/Recovery-vdb.conf
title Pop!_OS recovery (vdb)
linux /EFI/Recovery-${UUID_vdb2}/vmlinuz.efi
initrd /EFI/Recovery-${UUID_vdb2}/initrd.gz
options  boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-${UUID_vdb2} live-media=/dev/disk/by-partuuid/${PARTUUID_vdb2} noprompt 
EOF
cat /boot/efi/loader/entries/Recovery-vdb.conf
# title Pop!_OS recovery (vdb)
# linux /EFI/Recovery-C419-37C6/vmlinuz.efi
# initrd /EFI/Recovery-C419-37C6/initrd.gz
# options  boot=casper hostname=recovery userfullname=Recovery username=recovery live-media-path=/casper-C419-37C6 live-media=/dev/disk/by-partuuid/3560ffd1-39f0-44da-9c3b-a5d98ea43f08 noprompt
```
Now, you should update the initramfs and reboot.
```bash
update-initramfs -c -k all
reboot now
```
Don't boot into your normal system but check whether both recovery partitions work. If that is the case, boot back into your system and continue with the next step.

## Step 8: Make duplicate of EFI
Open an interactive sudo terminal, duplicate the efi partition to the second disk, unmount the current efi partition and mount the one from the second disk:
```bash
sudo -i
umount /boot/efi
dd if=/dev/vda1 of=/dev/vdb1 bs=1024 status=progress
# 459621376 bytes (460 MB, 438 MiB) copied, 6 s, 76.6 MB/s
# 509951+1 records in
# 509951+1 records out
# 522190336 bytes (522 MB, 498 MiB) copied, 9.58114 s, 54.5 MB/s
mount /dev/vdb1 /boot/efi
```
Reinstall the systemd boot manager to `vdb1`:
```bash
apt install --reinstall linux-generic linux-headers-generic
# Reading package lists... Done
# Building dependency tree       
# Reading state information... Done
# 0 upgraded, 0 newly installed, 2 reinstalled, 0 to remove and 0 not upgraded.
# Need to get 503 kB of archives.
# After this operation, 0 B of additional disk space will be used.
# Get:1 http://ppa.launchpad.net/system76/pop/ubuntu focal/main amd64 linux-generic amd64 5.4.0-7624.28~1586790353~20.04~9e10e31 [252 kB]
# Get:2 http://ppa.launchpad.net/system76/pop/ubuntu focal/main amd64 linux-headers-generic amd64 5.4.0-7624.28~1586790353~20.04~9e10e31 [252 kB]
# Fetched 503 kB in 0s (1,291 kB/s)          
# (Reading database ... 172366 files and directories currently installed.)
# Preparing to unpack .../linux-generic_5.4.0-7624.28~1586790353~20.04~9e10e31_amd64.deb ...
# Unpacking linux-generic (5.4.0-7624.28~1586790353~20.04~9e10e31) over (5.4.0-7624.28~1586790353~20.04~9e10e31) ...
# Preparing to unpack .../linux-headers-generic_5.4.0-7624.28~1586790353~20.04~9e10e31_amd64.deb ...
# Unpacking linux-headers-generic (5.4.0-7624.28~1586790353~20.04~9e10e31) over (5.4.0-7624.28~1586790353~20.04~9e10e31) ...
# Setting up linux-headers-generic (5.4.0-7624.28~1586790353~20.04~9e10e31) ...
# Setting up linux-generic (5.4.0-7624.28~1586790353~20.04~9e10e31) ...

update-initramfs -c -k all
# update-initramfs: Generating /boot/initrd.img-5.4.0-7624-generic
# cryptsetup: WARNING: Resume target cryptswap uses a key file
# kernelstub.Config    : INFO     Looking for configuration...
# kernelstub           : INFO     System information: 
# 
#     OS:..................Pop!_OS 20.04
#     Root partition:....../dev/dm-1
#     Root FS UUID:........c277ed84-e32f-4204-a211-1d80596e6e15
#     ESP Path:............/boot/efi
#     ESP Partition:......./dev/vda1
#     ESP Partition #:.....1
#     NVRAM entry #:.......-1
#     Boot Variable #:.....0000
#     Kernel Boot Options:.quiet loglevel=0 systemd.show_status=false splash rootflags=subvol=@
#     Kernel Image Path:.../boot/vmlinuz-5.4.0-7624-generic
#     Initrd Image Path:.../boot/initrd.img-5.4.0-7624-generic
#     Force-overwrite:.....False
# 
# kernelstub.Installer : INFO     Copying Kernel into ESP
# kernelstub.Installer : INFO     Copying initrd.img into ESP
# kernelstub.Installer : INFO     Setting up loader.conf configuration
# kernelstub.Installer : INFO     Making entry file for Pop!_OS
# kernelstub.Installer : INFO     Backing up old kernel
# kernelstub.Installer : INFO     No old kernel found, skipping

bootctl --path=/boot/efi install
```

Now, you should reboot and check whether both EFI partitions work.

## Step 9: Install Timeshift and timeshift-autosnap-apt

Open a terminal and install some dependencies:
```bash
sudo apt install -y git make
```

Install Timeshift and configure it directly via the GUI:
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
  
*Timeshift* will now check every hour if snapshots ("hourly", "daily", "weekly", "monthly", "boot") need to be created or deleted. Note that "boot" snapshots will not be created directly but about 10 minutes after a system startup.

*Timeshift* puts all snapshots into `/run/timeshift/backup`. Conveniently, the real root (subvolid 5) of your btrfs partition is also mounted here, so it is easy to view, create, delete and move around snapshots manually.

```bash
ls /run/timeshift/backup
# @  @home  @swap  timeshift-btrfs
```
Note that `/run/timeshift/backup/@` contains your `/` folder, `/run/timeshift/backup/@home` contains your `/home` folder, `/run/timeshift/backup/@swap` contains your `/swap` folder.

Now let's install *timeshift-autosnap-apt* from GitHub
```bash
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
# Rsyncing /boot/efi into the filesystem before the call to timeshift.
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-43-29
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-43-29/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-43-29/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-43-29/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-05-06_23-43-29': ondemand
```

Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift*. Note that if you use this you always have a backup of your efi parition inside any btrfs snapshot in the folder `/boot.backup/efi/`.

## Step 10 (WIP): Keep efi partitions in sync
To Do list: 

- [ ] mount both efi partitions via fstab
- [ ] add dpkg hook similar to timeshift-autosnap-apt
- [ ] alternatively show how to reinstall EFI partition

Note that if you use timeshift-autosnap-apt you always have a backup of your efi parition inside any btrfs snapshot in the folder `/boot.backup/efi/`.

## Emergency scenario: RAID1 is broken
### [WIP] efi is broken
see Repair bootloader in the [References](../../references/#btrfs-installation-guides)....

### vda is broken
Let's assume `vda` is broken (to this end I shutdown the virtual machine and add an empty `vda`). Now we need to open the "EFI BOOT MANAGER IN BIOS" and select to boot from the EFI partition on `vda`. The system will not boot, but we have our recovery system on `vdb`, so let's boot into it. Then, we need to chroot in degraded mode into the system, change PARTUUID in the fstab, and remove the bad drive from the crypttab:
```bash
sudo -i
cryptsetup luksOpen /dev/vdb4 crypt_vdb
mount -o subvol=@,degraded /dev/mapper/data_vdb-root /mnt
mount /dev/vdb1 /mnt/boot/efi
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo cp /etc/resolv.conf /mnt/etc/
sudo chroot /mnt

# get PARTUUID
echo $(blkid -s PARTUUID -o value /dev/vdb1)
# df1701f7-6e8b-4db1-8192-3a7931e3a905
echo $(blkid -s PARTUUID -o value /dev/vdb2)
# 3560ffd1-39f0-44da-9c3b-a5d98ea43f08
nano /etc/fstab
# USE df1701f7-6e8b-4db1-8192-3a7931e3a905 FOR /boot/efi
# USE 3560ffd1-39f0-44da-9c3b-a5d98ea43f08 FOR /recovery
cat /etc/fstab
# PARTUUID=df1701f7-6e8b-4db1-8192-3a7931e3a905  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=3560ffd1-39f0-44da-9c3b-a5d98ea43f08  /recovery  vfat  umask=0077  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
# UUID=c277ed84-e32f-4204-a211-1d80596e6e15   /home   btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0 0
# /dev/mapper/cryptswap  none  swap  defaults  0  0

mkswap /dev/vdb3
# Setting up swapspace version 1, size = 4 GiB (4294963200 bytes)
# no label, UUID=a6a9ec65-a225-4185-8edd-f9dd3c243a2a

nano /etc/crypttab
# UNCOMMENT THE NOT WORKING DEVICE AND CHANGE UUID of cryptswap
cat /etc/crypttab
# cryptswap UUID=a6a9ec65-a225-4185-8edd-f9dd3c243a2a /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# #crypt_vda UUID=9fc916b2-bdd8-4fbd-b557-4c4366f8cd63 none luks
# crypt_vdb UUID=93fc3643-a687-4a1c-9859-409b090448b9 none luks

update-initramfs -c -k all

exit
reboot now
```
Choose "POP!_OS (degraded)" in the boot menu and you can boot into your system and repair it!

### vdb is broken
Let's assume `vdb` is broken (to this end I shutdown the virtual machine and added a empty `vdb`). 
Now we need to open the "EFI BOOT MANAGER IN BIOS" and select to boot from the EFI partition on `vdb`. The system will not boot, but we have our recovery system on `vda`, so let's boot into it. Then, we need to chroot in degraded mode into the system and remove the bad drive from the crypttab:
```bash
sudo -i
cryptsetup luksOpen /dev/vda4 crypt_vda
mount -o subvol=@,degraded /dev/mapper/data_vda-root /mnt
mount /dev/vda1 /mnt/boot/efi
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo cp /etc/resolv.conf /mnt/etc/
sudo chroot /mnt

# NO NEED TO CHANGE THE FSTAB

nano /etc/crypttab
# UNCOMMENT THE NOT WORKING DEVICE
cat /etc/crypttab
# cryptswap UUID=03019356-3691-4002-a013-be15f291cde2 /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# crypt_vda UUID=9fc916b2-bdd8-4fbd-b557-4c4366f8cd63 none luks
# #crypt_vdb UUID=93fc3643-a687-4a1c-9859-409b090448b9 none luks

update-initramfs -c -k all

exit
reboot now
```
Choose POP!_OS (degraded) in the boot menu and you can boot into your system and repair it!

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**
**If you ever need to rollback your system, checkout my [Recovery and system rollback with Timeshift](../../timeshift/).**
