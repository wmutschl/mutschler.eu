---
title: Pop!_OS 21.04 with btrfs-LVM-luks installation guide and auto-apt snapshots with Timeshift
linktitle: Pop!_OS 21.04 btrfs-luks
toc: true
type: book
date: "2021-07-10T00:00:00+01:00"
draft: false

weight: 11
---

```md
{{< youtube mAd8AYPa5XE >}}
```
*Note that this written guide is an updated version of the video and contains much more information.*

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

## Overview 
Since a couple of months, I am exclusively using btrfs as my filesystem on all my systems, see [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Pop!_OS 20.04 with the following structure:

- a btrfs-LVM-inside-luks partition for the root filesystem
  - the btrfs logical volume contains a subvolume `@` for `/`, a subvolume `@home` for `/home`, and another subvolume `@swap` for the swapfile. Note that the Pop!_OS installer does not create any subvolumes on btrfs, so we need to do this manually.
- an unencrypted EFI partition for the systemd bootloader
- an unencrypted partition for the Pop!_OS recovery system
- automatic system snapshots and easy rollback similar to *zsys* using:
   - [Timeshift](https://github.com/teejee2008/timeshift) which will regularly take (almost instant) snapshots of the system
   - [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) which will automatically run Timeshift on any apt operation and also keep a backup of your EFI partition inside the snapshot
- If you need RAID1, follow this guide: [Pop!_OS 20.04 btrfs-luks-raid1](../pop-os-btrfs-raid1)

With this setup you basically get the same comfort of Ubuntu's 20.04's ZFS and *zsys* initiative, but with much more flexibility and comfort due to the awesome [Timeshift](https://github.com/teejee2008/timeshift) program, which saved my bacon quite a few times. This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).

**If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift).**


## Step 0: General remarks
**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**

So, let's spin up a virtual machine with 4 cores, 8 GB RAM, and a 64GB disk using e.g. the awesome bash script [quickemu](https://github.com/wimpysworld/quickemu). I can confirm that the installation works equally well on my Dell XPS 13 9360 and my Dell Precision 7520. 

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

First find out the name of your drive. For me the installation target device is called `vda`:
```bash
lsblk
# NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# loop0    7:0    0     2G  1 loop /rofs
# sr0     11:0    1   2.1G  0 rom  /cdrom
# sr1     11:1    1  1024M  0 rom
# sr2     11:2    1  1024M  0 rom
# vda   252:0     0    64G  0 disk
```
You can also open `gparted` or have a look into the `/dev` folder to make sure what your hard drives are called. In most cases they are called `sda` for normal SSD and HDD, whereas for NVME storage the naming is `nvme0`. Also note that there are no partitions or data on my hard drive, you should always double check which partition layout fits your use case, particularly if you dual-boot with other systems.

We'll now create a disk table and add three partitions on `vda`:

1. a 512 MiB FAT32 EFI partition for the systemd bootloader
2. a 4 GiB FAT32 partition for the Pop!_OS recovery system
3. a luks2 encrypted partition which contains a LVM with one logical volume formatted with btrfs, which will be our root filesystem

Some remarks:

- The LVM is actually a bit of an overkill for my typical use case, but otherwise the installer cannot access the luks partition.
- `/boot` will reside on the encrypted partition. The systemd bootloader is able to decrypt this at boot time.
- With btrfs I do not need any other partitions for e.g. `/home`, as we will use subvolumes instead. 
- I will show how to correctly create a swapfile on btrfs inside its own subvolume `@swap`. If you plan to use RAID1, swapfiles are not supported, and you should set up a swap partition instead. In my other [pop-os-btrfs-luks-raid1 guide](../pop-os-btrfs-raid1) I cover how to create an encrypted swap partition on Pop!_OS (actually the installer will do that for you).

Let's use `parted` for this (feel free to use `gparted` accordingly):
```bash
parted /dev/vda
  mklabel gpt
  mkpart primary fat32 1MiB 513MiB
  mkpart primary fat32 513MiB 4609MiB
  mkpart primary 4609MiB 100%
  name 1 EFI
  name 2 RECOVERY
  name 3 CRYPTDATA
  set 1 esp on
  print
# Model: Virtio Block Device (virtblk)
# Disk /dev/vda: 68.7GB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 

# Number  Start    End       Size      File system  Name       Flags
#  1      1049kB   538MB     537MB     fat32        EFI        esp
#  2      538MB    4833MB    4295MB    fat32        RECOVERY
#  3      4833MB   68.7GB    63.9GB                 CRYPTDATA
  quit
```

### Create luks2 partition, LVM and btrfs root filesystem

Pop!_OS uses the systemd bootloader, which can handle luks type 2 encryption just fine at boot time, so we can use the default options of `cryptsetup luksFormat` to format our vda3 partition and map it to a device called `cryptdata`, which will contain our LVM:

```bash
cryptsetup luksFormat /dev/vda3
# WARNING!
# ========
# This will overwrite data on /dev/vda3 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/vda3: 
# Verify passphrase:
cryptsetup luksOpen /dev/vda3 cryptdata
# Enter passphrase for /dev/vda3:
ls /dev/mapper
# control cryptdata
```
Use a very good password here. Now we need to create the LVM for the Pop!_OS installer, i.e. 

- make `cryptdata` a physical volume
- add a new volume group and call it also `data`
- create a logical volume `root` for our root partition

These are also the steps the Pop!_OS installer performs when you click `Clean install`, albeit with ext4 as the filesystem and an encrypted swap partition. So here are the commands:

```bash
pvcreate /dev/mapper/cryptdata
# Physical volume "/dev/mapper/cryptdata" successfully created
vgcreate data /dev/mapper/cryptdata
# Volume group "data" successfully created
lvcreate -n root -l 100%FREE data
# Logical volume "root" created.
ls /dev/mapper/
# control cryptdata data-root
cryptsetup luksClose /dev/mapper/data-root
cryptsetup luksClose /dev/mapper/cryptdata
ls /dev/mapper
# control
```
`data-root` is our root partition which we'll use for the root filesystem. We will use the Pop!_OS installer to format it to btrfs and after the installation create three subvolumes: 

- `@` for `/`
- `@home` for `/home`
- `@swap` for `/swap` which contains the swapfile

Apart from `@swap`, this is the typical btrfs layout used by Ubiquity, Calamares or Manjaro Architect installer. Pop!_OS, however, does not create any subvolumes by default, so we will do that manually.

## Step 3: Install Pop!_OS using the graphical installer

Now let's return to the installation process choose `Custom (Advanced)`. You will see your partitioned hard disk:

- Click on the first partition, activate `Use partition`, activate `Format`, Use as `Boot /boot/efi`, Filesystem: `fat32`.
- Click on the second partition, activate `Use partition`, activate `Format`, Use as `Custom` and enter `/recovery`, Filesystem: `fat32`.
- Click on the third and largest partition. A `Decrypt This Partition` dialog opens, enter your luks password and hit `Decrypt`. A new line is displayed `LVM cryptdata /dev/mapper/data-root`. Click on this partition, activate `Use partition`, activate `Format`, Use as `Root (/)` , Filesystem: `btrfs`.
* If you have other partitions, check their types and use; particularly, deactivate other EFI partitions.

Note that btrfs can handle a swapfile quite easily since kernel 5.0.x as long as it is in its own subvolume (otherwise we cannot take snapshots of `@`). We will change this after the installation process finishes. Alternatively or additionally, you can use a dedicated partition for swap.

Recheck everything (check the partitions where there is a black checkmark) and hit `Erase and Install` to write the changes to the disk. Once the installer finishes do NOT **Restart Device**, but return to your terminal.

## Step 4: Post-Installation steps

### Mount the btrfs top-level root filesystem

Let's mount our root partition (the top-level btrfs volume always has root-id 5), but with mount options that optimize performance and durability on SSD or NVME drives:
```bash
cryptsetup luksOpen /dev/vda3 cryptdata
# Enter passphrase for /dev/vda3
mount -o subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/data-root /mnt
```
 I have found that there is some general agreement to use the following mount options, namely:

- `ssd`: use SSD specific options for optimal use on SSD and NVME
- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro's minimal iso)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate.


### Create btrfs subvolumes `@`, `@home` and `@swap`

Now we will first create the subvolume `@` and move all files and folders from the top-level filesystem into it. Note that as we use the optimized mount options like compression, these will be applied during the moving process:
```bash
btrfs subvolume create /mnt/@
# Create subvolume '/mnt/@'
cd /mnt
ls | grep -v @ | xargs mv -t @ #move all files and folders to /mnt/@
ls /mnt/
# @
cd /
```
Now let's create two more subvolumes `@home` and `@swap`. Note that the Pop!_OS installer does neither create a user nor a swapfile, so there is nothing we need to copy over.
```bash
btrfs subvolume create /mnt/@home
# Create subvolume '/mnt/@home'
btrfs subvolume create /mnt/@swap
# Create subvolume '/mnt/@swap'
btrfs subvolume list /mnt
# ID 264 gen 66 top level 5 path @
# ID 267 gen 64 top level 5 path @home
# ID 268 gen 66 top level 5 path @swap
```
### Migrate home directories to `@home` subvolume
Now we need to copy the user home created by the Pop-OS installer to our newly created `@home` subvolume.
Once this is done we need to restore the correct permission on the files e.g: performing a `chown` on the home folder.<br>
This change is required due to the change in the install routine of Pop OS 21.04.
```bash
cp -ar  /mnt/@/home/. /mnt/@home
ls /mnt/@home
# user
``` 

### Create a btrfs swapfile
Swapfiles used to be a tricky business on btrfs, as it messed up snapshots and compression, but recent kernels are able to handle swapfile correctly if one puts them in a dedicated subvolume, in our case this will be called `@swap`. (Note, though, that if you plan to set up a RAID1 using btrfs you have to deactivate the swapfile again as this is still not supported in a RAID1 managed by btrfs.) 

Anyways, now let's create a 4GB swapfile inside this subvolume (change the size according to your needs) and set the necessary properties for btrfs:

```bash
truncate -s 0 /mnt/@swap/swapfile
chattr +C /mnt/@swap/swapfile
btrfs property set /mnt/@swap/swapfile compression none
fallocate -l 4G /mnt/@swap/swapfile
chmod 600 /mnt/@swap/swapfile
mkswap /mnt/@swap/swapfile
# Setting up swapspace version 1, size = 2 GiB (2147479552 bytes)
# no label, UUID=a0fee436-e38a-4d60-bb40-680c221db376
mkdir /mnt/@/swap
```
Note that we created the folder `/swap` to mount `@swap` to it via the `fstab`. 

So let's make the necessary changes to `fstab` with a text editor, e.g.:
```bash
nano /mnt/@/etc/fstab
```
 or use these `sed` commands
```bash
sed -i 's/defaults/defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd/' /mnt/@/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/data-root)   /home   btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0 0" >> /mnt/@/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/mapper/data-root)   /swap   btrfs   defaults,subvol=@swap,compress=no   0 0" >> /mnt/@/etc/fstab
echo "/swap/swapfile none swap defaults 0 0" >> /mnt/@/etc/fstab
```
Either way your `fstab` should look like this:
```bash
cat /mnt/@/etc/fstab
# PARTUUID=UUID_of_vda1                     /boot/efi   vfat   umask=0077   0   0
# PARTUUID=UUID_of_vda2                     /recovery   vfat   umask=0077   0   0
# UUID=UUID_of_data-root         /           btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd   0   0
# UUID=UUID_of_data-root         /home       btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd   0   0
# UUID=UUID_of_data-root         /swap       btrfs  defaults,subvol=@swap,compress=no   0   0
# /swap/swapfile                            none        swap   defaults      0   0
```
Note that the mount options for `@` and `@home` are the same, whereas for swap we do not use compression (in the video I did a mistake there).


### Adjust configuration of systemd bootloader and kernelstub
We need to adjust some settings for the systemd boot manager and also make sure these settings are not overwritten if we install or update kernels and modules.

Let's mount our EFI partition
```bash
mount /dev/vda1 /mnt/@/boot/efi
```

Add a timeout to the systemd boot menu in order to easily access the recovery partition:
```bash
echo "timeout 2" >> /mnt/@/boot/efi/loader/loader.conf
cat /mnt/@/boot/efi/loader/loader.conf 
# default Pop_OS-current
# timeout 2
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
where UUID_of_data-root is the UUID of /dev/mapper/data-root.

Lastly (and most importantly), we need to add `rootflags=subvol=@` to the `"user"` kernel options of the kernelstub configuration file:
```bash
nano /mnt/@/etc/kernelstub/configuration
# add rootflags=subvol=@ to "user" kernel options
# don't forget the comma after "splash"

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

### Create a chroot environment, install btrfs-progs and update initramfs

Now, let's create a chroot environment, which enables you to work directly inside your newly installed OS, without actually rebooting. For this, unmount the top-level root filesystem from `/mnt` and remount the subvolume `@` which we created for `/` to `/mnt`:
```bash
cd /
umount -l /mnt
mount -o defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/data-root /mnt
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
# /swap                    : successfully mounted
# none                     : ignored
```
Looks good! Now we need to install `btrfs-progs` (in the video it was already installed for some reason):
```bash
apt install -y btrfs-progs
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

If all went well you should see a single passphrase prompt (YAY!), where you enter the luks passphrase and your system boots. 

Now let's click through the welcome screen and create a user account. Let's open up a terminal to see whether everything is set up correctly:

```bash
sudo cat /etc/crypttab
# cryptdata UUID=d17cee65-e8cc-415a-8ea8-3521332c6c41 none luks

sudo cat /etc/fstab
# PARTUUID=69eb0006-62ee-4c4b-8c4a-4cab8e3e2174  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=e358f275-f7e2-4b9d-9e66-4dd5ae992eb6  /recovery  vfat  umask=0077  0  0
# UUID=a41ad72e-5188-42e2-ab45-40938756005f  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
# UUID=a41ad72e-5188-42e2-ab45-40938756005f  /home  btrfs  defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd  0  0
# UUID=a41ad72e-5188-42e2-ab45-40938756005f  /home  btrfs  defaults,subvol=@swap,compress=no  0  0
# /swap/swapfile none swap defaults 0 0

sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# /                        : ignored
# /home                    : already mounted
# /swap                    : already mounted
# none                     : ignored

sudo mount -v | grep /dev/mapper
# /dev/mapper/data-root on / type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=263,subvol=/@)
# /dev/mapper/data-root on /swap type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=265,subvol=/@home)
# /dev/mapper/data-root on /home type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=264,subvol=/@home)

sudo swapon
# NAME           TYPE      SIZE USED PRIO
# /swap/swapfile file        4G   0B   -2

sudo btrfs filesystem show /
# Label: none  uuid: a41ad72e-5188-42e2-ab45-40938756005f
# 	Total devices 1 FS bytes used 271.63GiB
# 	devid    1 size 468.42GiB used 294.02GiB path /dev/mapper/data-root

sudo btrfs subvolume list /
# ID 256 gen 195 top level 5 path @
# ID 258 gen 192 top level 5 path @home
# ID 262 gen 180 top level 5 path @swap
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


## Step 6: Install Timeshift and timeshift-autosnap-apt

Open a terminal and install some dependencies:
```bash
sudo apt install -y git make
```

Install Timeshift and configure it directly via the GUI:
```bash
sudo apt install -y timeshift
sudo timeshift-gtk
```
   * Select "BTRFS" as the "Snapshot Type"; continue with "Next"
   * Choose your BTRFS system partition as "Snapshot Location"; continue with "Next"  (even if timeshift does not see a btrfs system in the GUI it will still work, so continue (I already filed a bug report with timeshift))
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

*Timeshift* puts all snapshots into `/run/timeshift/backup`. Conveniently, the real root (subvolid 5) of your BTRFS partition is also mounted here, so it is easy to view, create, delete and move around snapshots manually.

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

Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift*. For example:

```bash
sudo apt install -y rolldice
# Reading package lists... Done
# Building dependency tree       
# Reading state information... Done
# The following NEW packages will be installed:
#   rolldice
# 0 upgraded, 1 newly installed, 0 to remove and 37 not upgraded.
# Need to get 9.628 B of archives.
# After this operation, 31,7 kB of additional disk space will be used.
# Get:1 http://de.archive.ubuntu.com/ubuntu focal/universe amd64 rolldice amd64 1.16-1build1 [9.628 B]
# Fetched 9.628 B in 0s (32,4 kB/s)
# Rsyncing /boot/efi into the filesystem before the call to timeshift.
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# 
# /dev/dm-0 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-0, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-45-37
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-45-37/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-45-37/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2020-05-06_23-45-37/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2020-05-06_23-45-37': ondemand
# Selecting previously unselected package rolldice.
# (Reading database ... 158308 files and directories currently installed.)
# Preparing to unpack .../rolldice_1.16-1build1_amd64.deb ...
# Unpacking rolldice (1.16-1build1) ...
# Setting up rolldice (1.16-1build1) ...
# Processing triggers for man-db (2.9.1-1) ...
```

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**

**If you ever need to rollback your system, checkout my [Recovery and system rollback with Timeshift](../../timeshift).**
