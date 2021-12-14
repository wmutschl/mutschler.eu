---
title: 'Ubuntu Desktop 20.04: installation guide with btrfs-luks-RAID1 full disk encryption including /boot and auto-apt snapshots with Timeshift'
#linktitle: Ubuntu 20.04 btrfs-luks-raid1
summary: In this guide I will walk you through the installation procedure to get an Ubuntu 20.04 system with a luks-encrypted partition for the root filesystem (including /boot) formatted with btrfs that contains a subvolume @ for / and a subvolume @home for /home. The system is set up in a RAID1 managed by the btrfs filesystem. I will show how to optimize the btrfs mount options and how to add key-files to type the luks passphrase only once for each disk for GRUB. I will also cover how to setup encrypted swap partitions. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. Moreover, using grub-btrfs all snapshots can be accessed and booted into from the GRUB menu. Due to the RAID1 managed by btrfs you get redundancy of your data.
toc: true
type: book
#date: "2020-05-21"
draft: false
weight: 39
---
***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/mutschler.eu). Pull requests are very much appreciated.***



## Overview 
Since a couple of months, I am exclusively using btrfs as my filesystem on all my systems, see: [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Ubuntu 20.04 with the following structure:

- a btrfs-inside-luks partition for the root filesystem (including `/boot`) on two hard disks in a RAID1 managed by btrfs. 
   - the root filesystem contains a subvolume `@` for `/` and a subvolume `@home` for `/home` with only one passphrase prompt from GRUB
- an encrypted swap partition on each disk
- an unencrypted EFI partition for the GRUB bootloader duplicated on both disks
- automatic system snapshots and easy rollback similar to *zsys* using:
   - [Timeshift](https://github.com/teejee2008/timeshift) which will regularly take (almost instant) snapshots of the system
   - [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) which will automatically run Timeshift on any apt operation and also keep a backup of your EFI partition inside the snapshot
   - [grub-btrfs](https://github.com/Antynea/grub-btrfs) which will automatically create GRUB entries for all your btrfs snapshots
- If you don't need RAID1, follow this guide: [Ubuntu 20.04 btrfs-luks](../ubuntu-btrfs-20-04)

With this setup you basically get the same comfort of Ubuntu's 20.04's ZFS and *zsys* initiative, but with much more flexibility and comfort due to the awesome [Timeshift](https://github.com/teejee2008/timeshift) program, which saved my bacon quite a few times. This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).

**If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift/).**
In the video, I also show what to do if your RAID1 is broken.

## Step 0: General remarks
**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**

So, let's spin up a virtual machine with 4 cores, 8 GB RAM, and two 64GB disk using e.g. my fork of the awesome bash script [quickemu](https://github.com/wmutschl/quickemu) to automatically create 2 disks. I can confirm that the installation works equally well on my Dell Precision 7520 (RAID1 between a SSD and NVME) and on my KVM server (RAID1 between two HDD).

This tutorial is made with [Ubuntu 20.04 Focal Fossa](http://releases.ubuntu.com/focal/) copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor). Other versions of Ubuntu or distributions that use the Ubiquity installer (like Linux Mint) also work, see my other [installation guides](../../install-guides).

## Step 1: Boot the install, check UEFI mode and open an interactive root shell
Since most modern PCs have UEFI, I will cover only the UEFI installation (see the [References](../../references/#btrfs-installation-guides) on how to deal with Legacy installs). So, boot the installation medium in UEFI mode, choose your language and click `Try Ubuntu`. Once the Live Desktop environment has started we need to use a Terminal shell command-line to issue a series of commands to prepare the target device before executing the installer itself. As I have a German Keyboard, I first go to `Settings -- Region & Language` and set my keyboard layout.

Then, open a terminal (<kbd>CTRL</kbd>+<kbd>ALT</kbd>+<kbd>T</kbd>) and run the following command:
```bash
mount | grep efivars
# efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)
```
to detect whether we are in UEFI mode. Now switch to an interactive root session:
```bash
sudo -i
```
You might find maximizing the terminal window is helpful for working with the command-line. Do not close this terminal window during the whole installation process until we are finished with everything.

## Step 2: Prepare partitions manually

### Create partition table and layout

First find out the name of your drive. For me the installation target device is called `vda` and I will use `vdb` for the RAID1 managed by btrfs:
```bash
lsblk
# NAME  MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# loop0   7:0    0   1.9G  1 loop /rofs
# loop1   7:1    0  27.1M  1 loop /snap/snapd/7264
# loop2   7:2    0    55M  1 loop /snap/core18/1705
# loop3   7:3    0 240.8M  1 loop /snap/gnome-3-34-1804/24
# loop4   7:4    0  62.1M  1 loop /snap/gtk-common-themes/1506
# loop5   7:5    0  49.8M  1 loop /snap/snap-store/433
# sr0    11:0    1   2.5G  0 rom  /cdrom
# sr1    11:1    1  1024M  0 rom  
# sr2    11:2    1  1024M  0 rom  
# vda   252:0    0    64G  0 disk 
# vdb   252:16   0    64G  0 disk 
```
You can also open `gparted` or have a look into the `/dev` folder to make sure what your hard drives are called. In most cases they are called `sda` and `sdb` for normal SSD and HDD, whereas for NVME storage the naming is `nvme0` and `nvme1`. Also note that there are no partitions or data on my hard drive, you should always double check which partition layout fits your use case, particularly if you dual-boot with other systems.

We'll now create the following partition layout on `vda` and `vdb`:

1. a 512 MiB FAT32 EFI partition for the GRUB bootloader
2. a 4 GiB partition for encrypted swap use
3. a luks1 encrypted partition which will be our root btrfs filesystem

Some remarks:

- `/boot` will reside on the encrypted luks1 partition. The GRUB bootloader is able to decrypt luks1 at boot time. Alternatively, you could create an encrypted luks1 partition for `/boot` and a luks2 encrypted partition for the root filesystem.
- With btrfs I do not need any other partitions for e.g. `/home`, as we will use subvolumes instead. 
- As we plan to use RAID1 managed by btrfs, we cannot use swapfiles as these are not supported in RAID1.

Let's use `parted` for this (feel free to use `gparted` accordingly):
```bash
parted /dev/vda
  mklabel gpt
  mkpart primary 1MiB 513MiB
  mkpart primary 513MiB 4609MiB
  mkpart primary 4609MiB 100%
  print
  # Model: Virtio Block Device (virtblk)
  # Disk /dev/vda: 68.7GB
  # Sector size (logical/physical): 512B/512B
  # Partition Table: gpt
  # Disk Flags: 
  # 
  # Number  Start   End     Size    File system  Name     Flags
  #  1      1049kB  538MB   537MB                primary
  #  2      538MB   4833MB  4295MB               primary
  #  3      4833MB  68.7GB  63.9GB               primary
  quit
```
Do not set names or flags, as in my experience the Ubiquity installer has some problems with that.

And the same commands for `vdb`:
```bash
parted /dev/vdb
  mklabel gpt
  mkpart primary 1MiB 513MiB
  mkpart primary 513MiB 4609MiB
  mkpart primary 4609MiB 100%
  print
  # Model: Virtio Block Device (virtblk)
  # Disk /dev/vdb: 68.7GB
  # Sector size (logical/physical): 512B/512B
  # Partition Table: gpt
  # Disk Flags: 
  # 
  # Number  Start   End     Size    File system  Name     Flags
  #  1      1049kB  538MB   537MB                primary
  #  2      538MB   4833MB  4295MB               primary
  #  3      4833MB  68.7GB  63.9GB               primary
  quit
```

### Create luks1 partition and btrfs root filesystem

The default luks (Linux Unified Key Setup) format used by the cryptsetup tool has changed since the release of Ubuntu 18.04 Bionic. 18.04 used version 1 ("luks1") but more recent Ubuntu releases default to version 2 ("luks2") and check that `/boot` is not located inside an encrypted partition. GRUB is able to decrypt luks version 1 at boot time, but Ubiquity does not allow this by default. Note that if you want to use luks version 2 you should create an encrypted `/boot` partition using version 1, whereas the root filesystem can then be formatted using version 2. Either way, we need to prepare the luks1 partition or else GRUB will not be able to unlock the encrypted device. Note that most Linux distributions also default to version 1 if you do a full disk encryption (e.g. Manjaro Architect).

```bash
cryptsetup luksFormat --type=luks1 /dev/vda3
# WARNING!
# ========
# This will overwrite data on /dev/vda3 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vda3: 
# Verify passphrase:

cryptsetup luksFormat --type=luks1 /dev/vdb3
# WARNING!
# ========
# This will overwrite data on /dev/vdb3 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vdb3: 
# Verify passphrase:
```
Use very good passwords here. Now map the encrypted partitions to devices called `crypt_vda` and `crypt_vdb`, which will contain our root filesystem:

```bash
cryptsetup luksOpen /dev/vda3 crypt_vda
# Enter passphrase for /dev/vda3:
cryptsetup luksOpen /dev/vdb3 crypt_vdb
# Enter passphrase for /dev/vdb3:
ls /dev/mapper/
# control  crypt_vda crypt_vdb
```

We need to pre-format `crypt_vda`, which will be the installation target for root during the graphical installer, because, in my experience, the Ubiquity installer messes up and complains about devices with the same name being mounted twice. After the installation we create the RAID1 with btrfs between `crypt_vda` and `crypt_vdb`.

```bash
mkfs.btrfs /dev/mapper/crypt_vda
# btrfs-progs v5.4.1 
# See http://btrfs.wiki.kernel.org for more information.
# Label:              (null)
# UUID:               f9a73348-8e30-4265-a909-4e99ae7b380b
# Node size:          16384
# Sector size:        4096
# Filesystem size:    59.50GiB
# Block group profiles:
#   Data:             single            8.00MiB
#   Metadata:         DUP               1.00GiB
#   System:           DUP               8.00MiB
# SSD detected:       no
# Incompat features:  extref, skinny-metadata
# Checksum:           crc32c
# Number of devices:  1
# Devices:
#    ID        SIZE  PATH
#     1    59.50GiB  /dev/mapper/crypt_vda
```
Note that the SSD is not detected for me here, because I am running this in a Virtual Machine, but I will still pretend that I am on a SSD.

## Step 3 (optional): Optimize mount options for SSD or NVME drives
Unfortunately, the Ubiquity installer does not set good mount options for btrfs on SSD or NVME drives, so you should change this for optimized performance and durability. I have found that there is some general agreement to use the following mount options:

- `ssd`: use SSD specific options for optimal use on SSD and NVME
- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate.
- Lastly the pass flag for fschk in the `fstab` is useless for btrfs and should be set to 0.

We need to change two configuration files:

- `/usr/lib/partman/mount.d/70btrfs`
- `/usr/lib/partman/fstab.d/btrfs`

 So let's use an editor to change the following:

```bash
nano /usr/lib/partman/mount.d/70btrfs
# line 24: options="${options:+$options,}subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd"
# line 31: options="${options:+$options,}subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd"

nano /usr/lib/partman/fstab.d/btrfs
# line 30: pass=0
# line 31: home_options="${options:+$options,}subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd"
# line 32: options="${options:+$options,}subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd"
# line 36: pass=0
# line 37: options="${options:+$options,}subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd"
# line 40: pass=0
# line 56: echo "$home_path" "$home_mp" btrfs "$home_options" 0 0
```

## Step 4: Install Ubuntu using the Ubiquity installer without the bootloader

Now let's run the installation process, but without installing the bootloader, as we want to put `/boot` on an encrypted partition which is actually not allowed by Ubiquity. So we need to run the installer with:
```bash
ubiquity --no-bootloader
```
Choose the installation language, keyboard layout, Normal or Minimal installation, check the boxes of the Other options according to your needs. In the "Installation type" options choose "Something Else" and the manual partitioner will start:

* Select /dev/vda1, press the `Change` button. Choose `Use as` 'EFI System Partition'. 
* Select /dev/vda2, press the `Change` button. Choose `Use as` 'swap area' to create a swap partition. We will encrypt this partition later in the `crypttab`.
* Select the root filesystem device for formatting (/dev/mapper/crypt_vda type btrfs on top), press the `Change` button. Choose `Use as` 'btrfs journaling filesystem', check `Format the partition` and use '/' as `Mount point`.
* If you have other partitions, check their types and use; particularly,deactivate other EFI partitions.

Recheck everything, press the `Install Now` button to write the changes to the disk and hit the `Continue button`. Select the time zone and fill out your user name and password. If your installation is successful choose the `Continue Testing` option. **DO NOT REBOOT!**, but return to your terminal.

## Step 5: Post-Installation steps

### Create a chroot environment and enter your system

Return to the terminal and create a chroot (change-root) environment to work directly inside your newly installed operating system:

```bash
mount -o subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/crypt_vda /mnt
for i in /dev /dev/pts /proc /sys /run; do sudo mount -B $i /mnt$i; done
sudo cp /etc/resolv.conf /mnt/etc/
sudo chroot /mnt
```
Now you are actually inside your system, so let's mount all other partitions and have a look at the btrfs subvolumes:

```bash
mount -av
# /                        : ignored
# /boot/efi                : successfully mounted
# /home                    : successfully mounted
# none                     : ignored

btrfs subvolume list /
# ID 256 gen 195 top level 5 path @
# ID 258 gen 22 top level 5 path @home
```
Looks great. Note that the subvolume `@` is mounted to `/`, whereas the subvolume `@home` is mounted to `/home`.

### Create RAID 1 for root filesystem using btrfs balance
Currently btrfs uses only one device `/dev/mapper/crypt_vda`, So let's add our other encrypted device `/dev/mapper/crypt_vdb` to it:
```bash
btrfs filesystem show /
# Label: none  uuid: d02e5c1d-292b-4a6e-9d44-c93572db897b
# 	Total devices 1 FS bytes used 2.88GiB
# 	devid    1 size 59.50GiB used 7.02GiB path /dev/mapper/crypt_vda

btrfs device add /dev/mapper/crypt_vdb /

btrfs filesystem show /
# Label: none  uuid: d02e5c1d-292b-4a6e-9d44-c93572db897b
# 	  Total devices 2 FS bytes used 2.88GiB
# 	  devid    1 size 59.50GiB used 7.02GiB path /dev/mapper/crypt_vda
#  	  devid    2 size 59.50GiB used 0.00B path /dev/mapper/crypt_vdb

btrfs filesystem usage /
# Overall:
#     Device size:		 118.99GiB
#     Device allocated:	   7.02GiB
#     Device unallocated:	 111.97GiB
#     Device missing:		     0.00B
#     Used:			   3.04GiB
#     Free (estimated):	 112.25GiB	(min: 56.27GiB)
#     Data ratio:		      1.00
#     Metadata ratio:		      2.00
#     Global reserve:		  10.17MiB	(used: 0.00B)
# 
# Data,single: Size:3.01GiB, Used:2.72GiB (90.51%)
#    /dev/mapper/crypt_vda	   3.01GiB
# 
# Metadata,DUP: Size:2.00GiB, Used:160.73MiB (7.85%)
#    /dev/mapper/crypt_vda	   4.00GiB
# 
# System,DUP: Size:8.00MiB, Used:16.00KiB (0.20%)
#    /dev/mapper/crypt_vda	  16.00MiB
# 
# Unallocated:
#    /dev/mapper/crypt_vda	  52.47GiB
#    /dev/mapper/crypt_vdb	  59.50GiB
```
Note, however, that on the second device there is no data yet (see the "single" and "DUP" flags of the above "usage" command). We need to move the data chunks around to have a working RAID1 and btrfs has a balance command just for this case: "A balance passes all data in the filesystem through the allocator again. It is primarly intended to rebalance the data in the filesystem across the devices when a device eis added or removed. A balance will regenerate missing copies for the redundant *RAID* levels, if a device has failed". 
```bash
btrfs balance start -dconvert=raid1 -mconvert=raid1 /
# Done, had to relocate 9 out of 9 chunks

btrfs filesystem usage /
# Overall:
#     Device size:		 118.99GiB
#     Device allocated:	  10.06GiB
#     Device unallocated:	 108.93GiB
#     Device missing:		     0.00B
#     Used:			   5.76GiB
#     Free (estimated):	  54.74GiB	(min: 54.74GiB)
#     Data ratio:		      2.00
#     Metadata ratio:		      2.00
#     Global reserve:		  11.81MiB	(used: 0.00B)
# 
# Data,RAID1: Size:3.00GiB, Used:2.72GiB (90.73%)
#    /dev/mapper/crypt_vda	   3.00GiB
#    /dev/mapper/crypt_vdb	   3.00GiB
# 
# Metadata,RAID1: Size:2.00GiB, Used:162.38MiB (7.93%)
#    /dev/mapper/crypt_vda	   2.00GiB
#    /dev/mapper/crypt_vdb	   2.00GiB
# 
# System,RAID1: Size:32.00MiB, Used:16.00KiB (0.05%)
#    /dev/mapper/crypt_vda	  32.00MiB
#    /dev/mapper/crypt_vdb	  32.00MiB
# 
# Unallocated:
#    /dev/mapper/crypt_vda	  54.46GiB
#    /dev/mapper/crypt_vdb	  54.46GiB
```
You can monitor the progress in a new terminal using `sudo btrfs balance status /mnt`. Sometimes, one gets an ERROR:
```bash
ERROR: error during balancing '/': No space left on device
There may be more info in syslog - try dmesg | tail
```
and the output of `sudo btrfs filesystem usage /` still shows "Data,single" or "Metadata,single" (instead of the "RAID1" tag like above), then you should try to run with different values for "dusage" and "musage", starting with e.g. 80:
```bash
btrfs balance start -dconvert=raid1 -mconvert=raid1 -dusage=80 -musage=80 /
# Done, had to relocate 7 out of 9 chunks
btrfs filesystem usage /
# Overall:
#     Device size:		 118.99GiB
#     Device allocated:	  10.06GiB
#     Device unallocated:	 108.93GiB
#     Device missing:		     0.00B
#     Used:			   5.76GiB
#     Free (estimated):	  54.74GiB	(min: 54.74GiB)
#     Data ratio:		      2.00
#     Metadata ratio:		      2.00
#     Global reserve:		  11.81MiB	(used: 0.00B)
# 
# Data,RAID1: Size:3.00GiB, Used:2.72GiB (90.73%)
#    /dev/mapper/crypt_vda	   3.00GiB
#    /dev/mapper/crypt_vdb	   3.00GiB
# 
# Metadata,RAID1: Size:2.00GiB, Used:162.38MiB (7.93%)
#    /dev/mapper/crypt_vda	   2.00GiB
#    /dev/mapper/crypt_vdb	   2.00GiB
# 
# System,RAID1: Size:32.00MiB, Used:16.00KiB (0.05%)
#    /dev/mapper/crypt_vda	  32.00MiB
#    /dev/mapper/crypt_vdb	  32.00MiB
# 
# Unallocated:
#    /dev/mapper/crypt_vda	  54.46GiB
#    /dev/mapper/crypt_vdb	  54.46GiB
```
and try to lower values for dusage and musage by 5 (one at a time) in case of errors, until there is the "RAID1" tag everywhere and all chunks are reallocated. Just to make sure, I rerun the balance command from above:
```bash
btrfs balance start -dconvert=raid1 -mconvert=raid1 /
# Done, had to relocate 5 out of 5 chunks
```
Note also that you cannot have a swapfile in a RAID1, so deactivate and delete it, if you have one for some reason.


### Create crypttab
We need to create the `crypttab` manually:
```bash
export UUID_VDA3=$(blkid -s UUID -o value /dev/vda3) #this is an environmental variable
export UUID_VDB3=$(blkid -s UUID -o value /dev/vdb3) #this is an environmental variable
echo "crypt_vda UUID=${UUID_VDA3} none luks" >> /etc/crypttab
echo "crypt_vdb UUID=${UUID_VDB3} none luks" >> /etc/crypttab

cat /etc/crypttab
# crypt_vda UUID=d8a7cab6-c875-4e65-b711-3ac2e2763ada none luks
# crypt_vdb UUID=06d53b48-6731-4926-a680-1b9b00a0e420 none luks
```
Note that the UUID is from the luks partitions /dev/vda3 and /dev/vdb3, not from the device mappers `/dev/mapper/crypt_vda` or `/dev/mapper/crypt_vdb`! You can get all UUID using `blkid`.


### Encrypted swap
There are many ways to encrypt the swap partition, a good reference is [dm-crypt/Swap encryption](https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption). 

As I have no use for hibernation or suspend-to-disk, I will simply use a random password to decrypt the swap partition using the `crypttab`:
```bash
mkswap /dev/vda2
# mkswap: error: /dev/vda2 is mounted; will not make swapspace
mkswap /dev/vdb2
# Setting up swapspace version 1, size = 4 GiB (4294963200 bytes)
# no label, UUID=f608784e-4497-4eac-8a7a-26c3415630dc

export UUID_SWAP_VDA=$(blkid -s UUID -o value /dev/vda2)
export UUID_SWAP_VDB=$(blkid -s UUID -o value /dev/vdb2)
echo "cryptswap_vda UUID=${UUID_SWAP_VDA} /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512" >> /etc/crypttab
echo "cryptswap_vdb UUID=${UUID_SWAP_VDB} /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512" >> /etc/crypttab

cat /etc/crypttab
# crypt_vda UUID=d8a7cab6-c875-4e65-b711-3ac2e2763ada none luks
# crypt_vdb UUID=06d53b48-6731-4926-a680-1b9b00a0e420 none luks
# cryptswap_vda UUID=361e5a10-29df-4561-b4f2-a88335f316ce /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# cryptswap_vdb UUID=f608784e-4497-4eac-8a7a-26c3415630dc /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
```

We also need to adapt the fstab accordingly:
```bash
sed -i "/UUID=${UUID_SWAP_VDA}/d" /etc/fstab
echo "/dev/mapper/cryptswap_vda none swap defaults,pri=1 0 0" >> /etc/fstab
echo "/dev/mapper/cryptswap_vdb none swap defaults,pri=1 0 0" >> /etc/fstab
cat /etc/fstab
# /dev/mapper/crypt_vda /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# UUID=0685-B0C8  /boot/efi       vfat    umask=0077      0       1
# /dev/mapper/crypt_vda /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# /dev/mapper/cryptswap_vda none swap defaults,pri=1 0 0
# /dev/mapper/cryptswap_vdb none swap defaults,pri=1 0 0
```
The sed command simply removed the previous line containing the swap partition. There you go, you have two encrypted swap partitions.

Also, let's use UUIDs instead of /dev/mapper/crypt_vda in the fstab:
```bash
sed -i "s|/dev/mapper/crypt_vda|$(blkid -s UUID -o value /dev/mapper/crypt_vda)|" /etc/fstab
cat /etc/fstab
# UUID=d02e5c1d-292b-4a6e-9d44-c93572db897b /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# UUID=0685-B0C8  /boot/efi       vfat    umask=0077      0       1
# UUID=d02e5c1d-292b-4a6e-9d44-c93572db897b /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# /dev/mapper/cryptswap_vda none swap defaults,pri=1 0 0
# /dev/mapper/cryptswap_vdb none swap defaults,pri=1 0 0
```

### Add a key-file to type luks passphrase only once (optional, but recommended)

The device holding the kernel (and the initramfs image) is unlocked by GRUB, but the root device needs to be unlocked again at initramfs stage, regardless whether it’s the same device or not, so you'll get a second prompt for your passphrase. This is because GRUB boots with the given vmlinuz and initramfs images; in other words, all devices are locked, and the root device needs to be unlocked again. To avoid extra passphrase prompts at initramfs stage, a workaround is to unlock via key files stored into the initramfs image. This can also be used to unlock any additional luks partitions you want on your disk. Since the initramfs image now resides on an encrypted device, this still provides protection for data at rest. After all for luks the volume key can already be found by user space in the Device Mapper table, so one could argue that including key files to the initramfs image – created with restrictive permissions – doesn’t change the threat model for luks devices. Note that this is exactly what e.g. the Manjaro architect installer does as well. 

Long story short, let's create a key-file, secure it, and add it to our luks volumes:

```bash
mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
# 1+0 records in
# 1+0 records out
# 4096 bytes (4.1 kB, 4.0 KiB) copied, 0.000928939 s, 4.4 MB/s
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile
cryptsetup luksAddKey /dev/vda3 /etc/luks/boot_os.keyfile
# Enter any existing passphrase: 
cryptsetup luksDump /dev/vda3 | grep "Key Slot"
# Key Slot 0: ENABLED
# Key Slot 1: ENABLED
# Key Slot 2: DISABLED
# Key Slot 3: DISABLED
# Key Slot 4: DISABLED
# Key Slot 5: DISABLED
# Key Slot 6: DISABLED
# Key Slot 7: DISABLED
cryptsetup luksAddKey /dev/vdb3 /etc/luks/boot_os.keyfile
# Enter any existing passphrase: 
cryptsetup luksDump /dev/vdb3 | grep "Key Slot"
# Key Slot 0: ENABLED
# Key Slot 1: ENABLED
# Key Slot 2: DISABLED
# Key Slot 3: DISABLED
# Key Slot 4: DISABLED
# Key Slot 5: DISABLED
# Key Slot 6: DISABLED
# Key Slot 7: DISABLED
```

Note that "Key Slot 0" contains our passphrase, whereas "Key Slot 1" contains the key-file. Let's restrict the pattern of keyfiles and avoid leaking key material for the initramfs hook:

```bash
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf
```
These commands will harden the security options in the intiramfs configuration file and hook.

Next, add the keyfile to your `crypttab`:

```bash
sed -i "s|none|/etc/luks/boot_os.keyfile|" /etc/crypttab # this replaces none with /etc/luks/boot_os.keyfile

cat /etc/crypttab
# crypt_vda UUID=d8a7cab6-c875-4e65-b711-3ac2e2763ada /etc/luks/boot_os.keyfile luks
# crypt_vdb UUID=06d53b48-6731-4926-a680-1b9b00a0e420 /etc/luks/boot_os.keyfile luks
# cryptswap_vda UUID=361e5a10-29df-4561-b4f2-a88335f316ce /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# cryptswap_vdb UUID=f608784e-4497-4eac-8a7a-26c3415630dc /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
```


### Install the EFI bootloader

Now it is time to finalize the setup and install the GRUB bootloader. First we need to make it capable to unlock luks1-type partitions by setting `GRUB_ENABLE_CRYPTODISK=y` in `/etc/default/grub`. Then we install the bootloader and update GRUB. Just in case, I also reinstall the generic kernel ("linux-generic" and "linux-headers-generic") and also install the Hardware Enablement kernel ("linux-generic-hwe-20.04" "linux-headers-generic-hwe-20.04"):

```bash
echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub

apt install -y --reinstall grub-efi-amd64-signed linux-generic linux-headers-generic linux-generic-hwe-20.04 linux-headers-generic-hwe-20.04
# --- SOME APT INSTALLATION OUTPUT ---

update-initramfs -c -k all
# update-initramfs: Generating /boot/initrd.img-5.4.0-26-generic
# update-initramfs: Generating /boot/initrd.img-5.4.0-31-generic

grub-install /dev/vda
# Installing for x86_64-efi platform.
# Installation finished. No error reported.

update-grub
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/init-select.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-5.4.0-31-generic
# Found initrd image: /boot/initrd.img-5.4.0-31-generic
# Found linux image: /boot/vmlinuz-5.4.0-26-generic
# Found initrd image: /boot/initrd.img-5.4.0-26-generic
# Adding boot menu entry for UEFI Firmware Settings
# done
```

Lastly, double-check that the initramfs image has restrictive permissions and includes the keyfile:

```bash
stat -L -c "%A  %n" /boot/initrd.img
# -rw-------  /boot/initrd.img
lsinitramfs /boot/initrd.img | grep "^cryptroot/keyfiles/"
# cryptroot/keyfiles/cryptdata.key
```
Note that cryptsetup-initramfs may rename key files inside the initramfs.


## Step 6: Reboot, some checks, and update system

Now, it is time to exit the chroot - cross your fingers - and reboot the system:

```bash
exit
# exit
reboot now
```

If all went well you should see a single passphrase prompt (YAY!) from GRUB for both your disks:
```
Enter the passphrase for hd0,gpt3 (some very long number):
....
Enter the passphrase for hd1,gpt3 (some very long number):
```
where you enter the luks passphrase to unlock GRUB, which then either asks you again for your passphrase or uses the key-file to unlock `/dev/vda3` and `/dev/vdb3` and then map it to `/dev/mapper/crypt_vda` and `/dev/mapper/crypt_vdb`. If you added a key-file you don't need to type your passwords again. Note that if you mistyped the password for GRUB, you must restart the computer and retry.

Now let's click through the welcome screen and open up a terminal to see whether everything is set up correctly:

```bash
sudo cat /etc/crypttab
# crypt_vda UUID=d8a7cab6-c875-4e65-b711-3ac2e2763ada /etc/luks/boot_os.keyfile luks
# crypt_vdb UUID=06d53b48-6731-4926-a680-1b9b00a0e420 /etc/luks/boot_os.keyfile luks
# cryptswap_vda UUID=361e5a10-29df-4561-b4f2-a88335f316ce /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
# cryptswap_vdb UUID=f608784e-4497-4eac-8a7a-26c3415630dc /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512

sudo cat /etc/fstab
# UUID=d02e5c1d-292b-4a6e-9d44-c93572db897b /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# UUID=0685-B0C8  /boot/efi       vfat    umask=0077      0       1
# UUID=d02e5c1d-292b-4a6e-9d44-c93572db897b /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# /dev/mapper/cryptswap_vda none swap defaults,pri=1 0 0
# /dev/mapper/cryptswap_vdb none swap defaults,pri=1 0 0

sudo mount -av
# /                        : ignored
# /boot/efi                : already mounted
# /home                    : already mounted
# none                     : ignored
# none                     : ignored

sudo mount -v | grep /dev/mapper
# /dev/mapper/crypt_vda on / type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=256,subvol=/@)
# /dev/mapper/crypt_vda on /home type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=258,subvol=/@home)

sudo swapon
# NAME      TYPE      SIZE USED PRIO
# /dev/dm-2 partition   4G   0B    1
# /dev/dm-3 partition   4G   0B    1

sudo btrfs filesystem show /
# Label: none  uuid: d02e5c1d-292b-4a6e-9d44-c93572db897b
# 	Total devices 2 FS bytes used 2.92GiB
# 	devid    1 size 59.50GiB used 4.03GiB path /dev/mapper/crypt_vda
# 	devid    2 size 59.50GiB used 4.03GiB path /dev/mapper/crypt_vdb

sudo btrfs subvolume list /
# ID 256 gen 403 top level 5 path @
# ID 258 gen 403 top level 5 path @home
```

Look's good.

Let's update the system and reboot one more time:

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

## Step 7: Duplicate EFI partition to the second disk
Open an interactive sudo terminal, duplicate the efi partition to the second disk, unmount the current efi partition and mount the one from the second disk:
```bash
sudo -i
umount /boot/efi
dd if=/dev/vda1 of=/dev/vdb1 bs=1024 status=progress
# 491181056 bytes (491 MB, 468 MiB) copied, 6 s, 81,9 MB/s
# 524288+0 records in
# 524288+0 records out
# 536870912 bytes (537 MB, 512 MiB) copied, 9,07637 s, 59,2 MB/s
mount /dev/vdb1 /boot/efi
```
Reinstall the GRUB boot manager to `vdb1`:
```bash
apt install -y --reinstall grub-efi-amd64-signed linux-generic linux-headers-generic linux-generic-hwe-20.04 linux-headers-generic-hwe-20.04
# --- SOME APT INSTALLATION OUTPUT ---

update-initramfs -c -k all
# update-initramfs: Generating /boot/initrd.img-5.4.0-26-generic
# cryptsetup: WARNING: Resume target cryptswap_vda uses a key file
# update-initramfs: Generating /boot/initrd.img-5.4.0-31-generic
# cryptsetup: WARNING: Resume target cryptswap_vda uses a key file

grub-install /dev/vdb
# Installing for x86_64-efi platform.
# Installation finished. No error reported.

update-grub
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/init-select.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-5.4.0-31-generic
# Found initrd image: /boot/initrd.img-5.4.0-31-generic
# Found linux image: /boot/vmlinuz-5.4.0-26-generic
# Found initrd image: /boot/initrd.img-5.4.0-26-generic
# Adding boot menu entry for UEFI Firmware Settings
# done
```

Now, you should reboot and check whether both EFI partitions work and are bootable.


## Step 8: Install Timeshift, timeshift-autosnap-apt and grub-btrfs

Open a terminal and install some dependencies:
```bash
sudo apt install -y btrfs-progs git make
```
Install Timeshift and configure it directly via the GUI:
```bash
sudo apt install timeshift
sudo timeshift-gtk
```
   * Select btrfs as the “Snapshot Type”; continue with “Next”
   * Choose your btrfs system partition as “Snapshot Location”; continue with “Next”
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
# @  @home  timeshift-btrfs
```
Note that `/run/timeshift/backup/@` contains your `/` folder and `/run/timeshift/backup/@home` contains your `/home` folder.

Now let's install *timeshift-autosnap-apt* and *grub-btrfs* from GitHub
```bash
git clone https://github.com/wmutschl/timeshift-autosnap-apt.git /home/$USER/timeshift-autosnap-apt
cd /home/$USER/timeshift-autosnap-apt
sudo make install

git clone https://github.com/Antynea/grub-btrfs.git /home/$USER/grub-btrfs
cd /home/$USER/grub-btrfs
sudo make install
```

After this, optionally, make changes to the configuration files:
```bash
sudo nano /etc/timeshift-autosnap-apt.conf
sudo nano /etc/default/grub-btrfs/config
```
For example, as we don't have a dedicated /boot partition, we can set `snapshotBoot=false` in the `timeshift-autosnap-apt-conf` file to not rsync the `/boot` directory to `/boot.backup`. Note that the EFI partition is still rsynced into your snapshot to `/boot.backup/efi`. For *grub-btrfs*, I change `GRUB_BTRFS_SUBMENUNAME` to "My BTRFS Snapshots".

Check if everything is working:
```bash
sudo timeshift-autosnap-apt
# Rsyncing /boot/efi into the filesystem before the call to timeshift.
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-16-45
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-16-45/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-16-45/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-16-45/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-05-22_11-16-45': ondemand
# ------------------------------------------------------------------------------
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/init-select.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-5.4.0-31-generic
# Found initrd image: /boot/initrd.img-5.4.0-31-generic
# Found linux image: /boot/vmlinuz-5.4.0-26-generic
# Found initrd image: /boot/initrd.img-5.4.0-26-generic
# Adding boot menu entry for UEFI Firmware Settings
# ###### - Grub-btrfs: Snapshot detection started - ######
# # Info: Separate boot partition not detected 
# # Found snapshot: 2020-05-22 11:16:45 | timeshift-btrfs/snapshots/2020-05-22_11-16-45/@
# # Found snapshot: 2020-05-22 11:15:10 | timeshift-btrfs/snapshots/2020-05-22_11-15-10/@
# # Found 2 snapshot(s)
# ###### - Grub-btrfs: Snapshot detection ended   - ######
# done
```

Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift* and *grub-btrfs* creates the corresponding boot menu entries (actually it creates boot menu entries for all subvolumes of your system). For example:

```bash
sudo apt install rolldice
# Reading package lists... Done
# Building dependency tree       
# Reading state information... Done
# The following NEW packages will be installed:
#   rolldice
# 0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
# Need to get 9.628 B of archives.
# After this operation, 31,7 kB of additional disk space will be used.
# Get:1 http://de.archive.ubuntu.com/ubuntu focal/universe amd64 rolldice amd64 1.16-1build1 [9.628 B]
# Fetched 9.628 B in 0s (137 kB/s)
# Rsyncing /boot/efi into the filesystem before the call to timeshift.
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-17-36
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-17-36/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-17-36/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-22_11-17-36/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-05-22_11-17-36': ondemand
# ------------------------------------------------------------------------------
# Sourcing file `/etc/default/grub'
# Sourcing file `/etc/default/grub.d/init-select.cfg'
# Generating grub configuration file ...
# Found linux image: /boot/vmlinuz-5.4.0-31-generic
# Found initrd image: /boot/initrd.img-5.4.0-31-generic
# Found linux image: /boot/vmlinuz-5.4.0-26-generic
# Found initrd image: /boot/initrd.img-5.4.0-26-generic
# Adding boot menu entry for UEFI Firmware Settings
# ###### - Grub-btrfs: Snapshot detection started - ######
# # Info: Separate boot partition not detected 
# # Found snapshot: 2020-05-22 11:17:36 | timeshift-btrfs/snapshots/2020-05-22_11-17-36/@
# # Found snapshot: 2020-05-22 11:16:45 | timeshift-btrfs/snapshots/2020-05-22_11-16-45/@
# # Found snapshot: 2020-05-22 11:15:10 | timeshift-btrfs/snapshots/2020-05-22_11-15-10/@
# # Found 3 snapshot(s)
# ###### - Grub-btrfs: Snapshot detection ended   - ######
# done
# Selecting previously unselected package rolldice.
# (Reading database ... 185770 files and directories currently installed.)
# Preparing to unpack .../rolldice_1.16-1build1_amd64.deb ...
# Unpacking rolldice (1.16-1build1) ...
# Setting up rolldice (1.16-1build1) ...
# Processing triggers for man-db (2.9.1-1) ...
```

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**
**If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift/).**


### Step 10 (WIP): Keep efi partitions in sync
To Do list: 

- [ ] mount both efi partitions via fstab
- [ ] add dpkg hook similar to timeshift-autosnap-apt
- [ ] alternatively show how to reinstall EFI partition

Note that if you use timeshift-autosnap-apt you always have a backup of your efi parition inside any btrfs snapshot in the folder `/boot.backup/efi/`.


### Emergency scenario: RAID1 is broken
#### [WIP] efi is broken
see Repair bootloader in the [References](../../references/#btrfs-installation-guides)....

#### vda is broken
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

#### vdb is broken
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
