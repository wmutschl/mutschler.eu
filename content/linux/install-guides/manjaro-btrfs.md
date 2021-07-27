---
title: Manjaro Linux with btrfs-luks full disk encryption including /boot and auto-snapshots with Timeshift (in-progress)
linktitle: Manjaro btrfs-luks
toc: true
type: book
date: "2020-05-08T00:00:00+01:00"
draft: false

# Prev/next pager order (if `docs_section_pager` enabled in `params.toml`)
weight: 31
---

```md
{{< youtube  >}}
```

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

## Overview 
In this guide I will walk you through the installation procedure to get a Manjaro system with the following structure:

- a btrfs-inside-luks partition for the root file system (including /boot) containing a subvolume `@` for /, a subvolume `@home` for /home, and a subvolume `@cache` for /var/cache with only one passphrase prompt from GRUB
- either an encrypted swap partition or a swapfile
- an unencrypted EFI partition and any other partitions you might want
- [Timeshift](https://github.com/teejee2008/timeshift) will regularly take snapshots of the system
- [timeshift-autosnap](https://gitlab.com/gobonja/timeshift-autosnap) will automatically run Timeshift on any pacman operation
- [grub-btrfs](https://github.com/Antynea/grub-btrfs) will automatically create GRUB entries for all your btrfs snapshots

So with this setup you get the same comfort of e.g. Ubuntu's 20.04's ZFS and zsys initiative, but with much more flexibility and comfort due to the awesome *Timeshift* program. This setup works equally well on other distributions like Ubuntu, Linux Mint or Pop!_OS, for which I also have advanced [installation guides with RAID1 capability](https://mutschler.eu/linux/install-guides/).

## Installation Steps
Let's spin up a virtual machine with 4 cores and 8 GB RAM using e.g. the awesome script for QEMU Virgil from Martin Wimpress called [quickemu](https://github.com/wimpysworld/quickemu). The same steps work on my Dell XPS 9630, my Dell precision 7520 (with additional luks-encrypted RAID1 between a SSD and NVME) and on my server (with additional luks-encrypted RAID1 between two HDD).

This tutorial is made with [manjaro-architect-20.0-200426-linux56.iso](https://manjaro.org/downloads/official/architect/) copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor). I also make sure that I am connected to the internet via an ethernet cable not wifi.

### 0: Boot the install, change language settings and start the setup
Since most PCs since 2010 have UEFI, I will cover only the UEFI installation (see the [References](../../references/#btrfs-installation-guides) on how to deal with Legacy installs). So, boot the installer in UEFI mode, choose your `keytable`, `lang`, `driver` and click `Boot: Manjaro.x86_64 architect`. Once you are at the command prompt, use `manjaro` as manjaro-architect login and `manjaro` as password. Run
```bash
mount | grep efivars
# efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)
```
to detect whether we are in UEFI mode. Now run `setup` to start the Architect. This will update the installer and get the latest packages. Select your Language and confirm the Welcome box.


### 1: Prepare Installation
Click on `1 Prepare Installation`.

1. `Set Virtual Console`: Click on it and change it to your language code.
2. `List Devices (optional)`: Click on it to see which hard disks and partitions you already have in use. Make not of the one you want to use for the install or on which disks you want to create partitions. For me the installation target device is called `/dev/vda`
3. `Partition Disk`: Select your installation target, for me this is `/dev/vda`. If you don't want a swap partition, then choose `Automatic Partitioning` wich creates a 512 MB boot partition and the rest is allocated for the root filesystem. Later you can choose whether you want to create a swapfile as well. I usually create a swap partition, so I use `parted` to create the following partition layout on `vda`:

   - a 512 MiB FAT32 EFI partition 
   - a 4 GiB partition for encrypted swap use
   - a luks1 encrypted partition which will be our root btrfs file system
   - any other partitions you might need
  
  Let's click on `parted` for this:
```bash
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
   Note that /boot will reside on an encrypted luks1 partition as GRUB is able to decrypt luks1 at boot time. You could also create an encrypted luks1 partition for /boot and a luks2 encrypted partition for the root file system. With btrfs I actually do not need any other partitions as the installer will create subvolumes for that. Lastly, note that if you plan to use RAID1 with btrfs, swapfiles are not supported, and you should stick to an encrypted swap partition.
 
4. RAID (optional): Skip this step as we do not want to set up software raid.

5. Logical Volume Management (optional): Skip this step, as I do not need this for my Desktop use-case. If so, I actually create luks partitions first and then come back to LVM.

6. LUKS Encryption (optional): Click on it and select Automatic LUKS Encryption for your root partition /dev/vda3. Choose a name, e.g. crypt_vda3, and use a very good password. Note that the encrypted partition is mapped to a device called `crypt_vda3` located in /dev/mapper. This is where we install our root file system. Select Back and Back to go back to the next Prepare Installation step.

7. ZFS (optional): Skip this, as we will use btrfs instead of ZFS. Also this won't work since we do not have the ZFS kernel modules installed in this iso, see how to do so on the [Manjaro Forum](https://forum.manjaro.org/t/architect-zfs-installation/102764)

8. Mount Partitions: Click on it and confirm the dialog. Make the following selection:
   - Select ROOT Partition: /dev/mapper/crypt_vda3, Filesystem btrfs, confirm the format, and choose and confirm the following mount options if you are on a SSD or NVME:
      - `ssd`: use SSD specific options for optimal use on SSD and NVME
      - `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders (noatime also includes nodiratime)
      - `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
      - `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro)
      - `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms. Based on some Phoronix test cases, zstd seems to be the better performing candidate.
    Otherwise stick with Manjaro's default options.
    - Confirm that you like to create subvolumes, choose the automatic mode, which creates subvolumes @ for /, @home for /home, and @cache for /var/cache.
  - Select SWAP Partition: /dev/vda2 and confirm to mkswap.
  - Select additional partitions: I don't need any more partitions, as the EFI partition comes next, so click Done.
  - Select UEFI partition: /dev/vda1 with mount point /boot/efi

9. Configure Installer Mirrorlist: Choose Rank Mirrors by Speed and select the top 5 mirrors for the installation in your country.

10. Refresh Pacman Keys: If your iso is very old, you should refresh these which will take quite some time. If you have a somewhat recent iso downloaded, then skip this step.

11. Choose pacman cache: Skip this step.

12. Enable fsck hook: Skip this step.

13. Back: Click on it to go to the next installation phase.

### 2. Install Desktop System

1. Install Manjaro Desktop: Click on it.
   - As I love the AUR, I select yay+base-devel to be installed and the recent stable kernel linux56 (check on [kernel](https://kernel.org)).
   - Choose your desktop environment: I am a gnome fan boy, so I choose gnome.
   - Extra Packages: you could add all packages you need at the end of the file, but I usually choose to do all this inside the running system, so No.
   - Manjaro Gnome comes in two editions, full or minimal. As I really like the default selection of the Manjaro Team, I choose full.
   
   Now you have to wait until the installation finishes and asks which Display Driver to install. Choose according to your system, for me I usually choose Auto-install either free or proprietary drivers on Nvidia systems.

2. Install Bootloader: Click on it.
   - For this tutorial, I choose grub as we are concerned with full-disk encryption and I also really like the grub-btrfs package. Note that systemd-boot is also really great and has much quicker boot time. But, let's stick to grub and confirm to Install UEFI Bootloader GRUB. This will now create a keyfile and add it to your luks partition for automatic unlocking, so you have to enter your luks passphrase here.
   Also, I set the Grub bootloader as default, as explained in the next message box.

3. Configure Base: Go through all of the steps:
    1. Generate FSTAB. Very important, so click on it and choose the recommended way using Device UUID.
    2. Set Hostname: Click on it and set your hostname.
    3. Set System Locale: Click on it and choose your language code
    4. Set Desktop Keyboard Layout: Click on it and choose your layout
    5. Set Timezone and Clock: Click on it and set your timezone
    6. Set Root Password: Set a good password here for the user root
    7. Add New User(s): I create a user account for me called wmutschl and use bash as my default shell.
    8. Back: Go back to the next phase.

4. System Tweaks: You can go through these.
  1. Enable Automatic Login: I usually enable this as I am the sole use of my system and already input my LUKS passphrase.
  2. Hibernation: I don't use hibernation, so I skip this.
  3. Performance: I like Manjaro's default settings, so I skip this.
  4. Security and systemd Tweaks: I like Manjaro's default settings, so I skip this.
  5. Back: Go back to the next phase.

5. Review Configuration Files
I usually go through all the files and check the following:
  - fstab: check the mount points and mount options. I noticed that even though the Architect creates a subvolume @cache it does not get mounted correctly in fstab, so I copy the line for @home and replace @home with @cache and the mount entry to /var/cache.
  - crypttab: if I have any additional (non-root) luks encrypted partitions they should be listed here. In this tutorial, I don't have any, so there should not be anything uncommented in this file.
  - grub: check whether in GRUB_CMDLINE_LINUX there is your cryptdevice=UUID=...:crypt_vda3, GRUB_ENABLE_CRYPTODISK=y, 

  - mkinitcpio.conf: Check whether the key file is included in FILES=(/crypto_keyfile.bin), and you have the following hooks:
  HOOKS=(base udev autodetect keymap modconf block encrypt filesystems keyboard)

6. Chroot into Installation: No need, we will make some further small changes inside the newly installed systems

Click back, Done, Close installer, choose whether you want to save the installation log (No) and then input `sudo reboot now`.


### Step 5: Post-Installation steps
If all went well you should see a single passphrase prompt (YAY!):

```
Enter the passphrase for hd0,gpt3 (some very long number):
```

where you enter the luks passphrase to unlock GRUB, which then uses the key-file to unlock /dev/vda3 and map it to /dev/mapper/crypt_vda3. So you need to type your password only once. Note that if you mistyped the password, you must restart the computer.

Now let's click through the welcome screen and open up a terminal to update the system:

```bash
sudo pacman-mirrors -c Germany
sudo pacman -Syyu
```

#### Install Timeshift, timeshift-autosnap and grub-btrfs
Install Timeshift and configure it either directly in the /etc/timeshift.json file or via the GUI:
```bash
sudo pacman -S timeshift timeshift-autosnap grub-btrfs
sudo timeshift-gtk
```
   * Select “BTRFS” as the “Snapshot Type”; continue with “Next”
   * Choose your BTRFS system partition as “Snapshot Location”; continue with “Next”
   * “Select Snapshot Levels” (type and number of snapshots that will be automatically created and managed/deleted by Timeshift), recommendations:
     * Keep “Daily” at 5
     * Activate “Boot”, but change to 3
     * Activate "Stop cron emails for scheduled tasks"
     * continue with “Next”
     * I also include @home subvolume (which is not selected by default). Note that when you restore a snapshot Timeshift will ask you again whether or not to include @home in the restore process.
     * Click "Finish"
   * “Create” a manual first snapshot & exit Timeshift

*Timeshift* will now check on every full hour if snapshots (hourly, daily, weekly, monthly) need to be created or deleted. Note that boot snapshots will actually be created about 10 minutes after boot, not directly at system startup.

*Timeshift* puts all snapshots into `/run/timeshift/backup`. Conveniently, the real root (subvolid 5) of your BTRFS partition is also mounted here, so it is easy to view, create, delete and move around snapshots manually.

```bash
ls /run/timeshift/backup
# @  @cache @home timeshift-btrfs
```

After this, optionally, make changes to the configuration files:
```bash
sudo nano /etc/timeshift-autosnap.conf
sudo nano /etc/default/grub-btrfs/config
```
For example, as we don't have a dedicated /boot partition, we can set `snapshotBoot=false` in the `timeshift-autosnap-conf` file to not rsync the boot files to boot.backup. Note that the EFI partition is still rsynced into your snapshot to /boot.backup/efi. For grub-btrfs, I change `GRUB_BTRFS_SUBMENUNAME` to "MY BTRFS SNAPSHOTS".

Check if everything is working:
```bash
sudo timeshift-autosnap
```

Now, if you run `sudo pacman -S|R|Syu|Syyu`, *timeshift-autosnap* will create a snapshot of your system with *Timeshift* and *grub-btrfs* creates the corresponding boot menu entries (actually it creates boot menu entries for all subvolumes of your system).

#### (Optional) Enable fstrim.timer for SSD and NVME
Note that we did not add discard to the crypttab as btrfs support for (asynchronous) discard requires at least Kernel 5.6. Therefore, if you have installed on a SSD or NVME, enable the fstrim.timer systemd service:

```bash
sudo systemctl enable fstrim.timer
```

#### Move /var/cache into @cache
```bash
cd /run/timeshift/backup/@/var/cache
ls | xargs sudo mv -t /run/timeshift/backup/@cache/


export CRYPTUUID=$(blkid -s UUID -o value /dev/mapper/crypt_vda3)
echo "UUID=${CRYPTUUID}    /var/cache    btrfs    rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvol=@cache 0 0" >> /etc/fstab
sudo mount -av
```


#### Encrypted swap
There are many ways to encrypt the swap partition, a good reference is [dm-crypt/Swap encryption](https://wiki.archlinux.org/index.php/Dm-crypt/Swap_encryption). For the sake of this guide, I will show how to set up both an encrypted swap partition as well as a swapfile which resides in its own btrfs subvolume. Choose the one you like more.

##### Swap partition
As I have no use for hibernation or suspend-to-disk, I will simply use a random password to decrypt the swap partition using the `/etc/crypttab`:
```
sudo -i
export SWAPUUID=$(blkid -s UUID -o value /dev/vda2)
echo "cryptswap UUID=${SWAPUUID} /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512" >> /etc/crypttab
cat /etc/crypttab
# cryptswap UUID=9cae34c0-3755-43b1-ac05-2173924fd433 /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512
```

We also need to adapt the fstab accordingly:
```bash
sed -i "s|UUID=${SWAPUUID}|/dev/mapper/cryptswap|" /etc/fstab
cat /etc/fstab
# /dev/mapper/cryptswap none            swap    defaults,pri=-2 0 0
```
The sed command simply replaced the UUID of your swap partition with the encrypted device /dev/mapper/cryptswap. There you go, you have an encrypted swap partition. Alternatively, or additionally, you can set up a swapfile, or skip to the next step.

##### Create a btrfs swapfile
Swapfiles used to be a tricky business on btrfs, as it messed up snapshots and compression, but recent kernels are able to handle swapfile correctly if one puts them in a dedicated subvolume, in our case this will be called @swap. (Note, though, that if you plan to set up a RAID1 using btrfs you have to deactivate the swapfile again as this is still not supported in a RAID1 managed by btrfs.) 

If you did not create a swap partition above, Ubiquity created a swapfile for you. Let's remove this file and also any reference to it in the `/etc/fstab`:
```bash
swapoff /swapfile
rm /swapfile
sed -i '\|^/swapfile|d' /etc/fstab #this removes any lines starting with /swapfile
```

Next we mount the top-level root btrfs filesystem, which always has id 5, to /mnt:

```bash
mount -o subvolid=5 /dev/mapper/cryptdata /mnt
ls /mnt
# @  @home
```

Note that we now look from the outside on our system, i.e. in @ we have the same files as in /, in @home the same files as in /home. Let's create another subvolume called @swap:
```bash
btrfs subvolume create /mnt/@swap
ls /mnt
# @  @home  @swap
```
and create a 4GB swapfile inside this subvolume (change the size according to your needs) and set the necessary properties for btrfs:

```bash
cd /run/timeshift/backup
truncate -s 0 @swap/swapfile
chattr +C @swap/swapfile
btrfs property set @swap/swapfile compression none
fallocate -l 4G @swap/swapfile
chmod 600 @swap/swapfile
mkswap @swap/swapfile
# Setting up swapspace version 1, size = 4 GiB (4294963200 bytes)
# no label, UUID=2c39e8bd-c158-4126-8389-5d56c0977db0

mkdir /swap #or equivalently: mkdir /swap
```

Note that we created the folder /swap to mount @swap to it via the fstab. So, let's make the necessary change in fstab with a text editor, e.g.:
```bash
nano /etc/fstab
```
or these `sed` commands
```bash
echo "UUID=$(blkid -s UUID -o value /dev/mapper/crypt_vda3)   /swap   btrfs   subvol=@swap,compress=no   0 0" >> /etc/fstab
echo "/swap/swapfile none swap defaults 0 0" >> /etc/fstab
```
Either way your fstab should look like this:
```bash
cat /mnt/@/etc/fstab
# /dev/mapper/cryptdata /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# UUID=01DE-F282  /boot/efi       vfat    umask=0077      0       1
# /dev/mapper/cryptdata /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# #THIS IS YOUR ENCRYPTED SWAP PARTITION
# /dev/mapper/cryptswap none            swap    sw              0       0
# #THE NEXT 2 LINES ARE NEEDED FOR YOUR SWAPFILE
# UUID=aa90f2d3-10d9-420b-86e2-92ffce0ece9d   /swap   btrfs   subvol=@swap,compress=no   0 0
# /swap/swapfile none swap defaults 0 0
```

We are done with swap and can unmount the top-level root filesystem:
```bash
umount /mnt
```



 to see whether everything is set up correctly and make some small changes:

```bash
sudo mount -av
# /                        : ignored
# /boot/efi                : already mounted
# /home                    : already mounted

sudo mount -v | grep /dev/mapper
# /dev/mapper/cryptdata on / type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=256,subvol=/@)
# /dev/mapper/cryptdata on /swap type btrfs (rw,relatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=262,subvol=/@swap)
# /dev/mapper/cryptdata on /home type btrfs (rw,noatime,compress=zstd:3,ssd,space_cache,commit=120,subvolid=258,subvol=/@home)


cat /etc/crypttab
# cryptdata UUID=8e893c0f-4060-49e3-9d96-db6dce7466dc /etc/luks/boot_os.keyfile luks
# cryptswap UUID=9cae34c0-3755-43b1-ac05-2173924fd433 /dev/urandom swap,offset=1024,cipher=aes-xts-plain64,size=512

cat /etc/fstab
# /dev/mapper/cryptdata /               btrfs   defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# UUID=01DE-F282  /boot/efi       vfat    umask=0077      0       1
# /dev/mapper/cryptdata /home           btrfs   defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd 0       0
# /dev/mapper/cryptswap none            swap    sw              0       0
# UUID=aa90f2d3-10d9-420b-86e2-92ffce0ece9d   /swap   btrfs   subvol=@swap,compress=no   0 0
# /swap/swapfile none swap defaults 0 0



swapon
# NAME           TYPE      SIZE USED PRIO
# /swap/swapfile file        4G   0B   -2
# /dev/dm-1      partition   4G   0B   -3

sudo btrfs filesystem show /
# Label: none  uuid: aa90f2d3-10d9-420b-86e2-92ffce0ece9d
# 	Total devices 1 FS bytes used 6.61GiB
# 	devid    1 size 59.50GiB used 9.02GiB path /dev/mapper/cryptdata

btrfs subvolume list /
# ID 256 gen 195 top level 5 path @
# ID 258 gen 192 top level 5 path @home
# ID 262 gen 180 top level 5 path @swap
```

Look's good.


**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**


## BONUS: How to RESTORE a previous system snapshot

### If you can access your desktop environment (either directly or via an old snapshot)

Launch Timeshift from the menu (or desktop shortcut) and select a snapshot and hit restore. A reboot and you're done. Takes mere seconds and doesn’t get any easier.

### If you can't boot into your desktop environment
Run a live system (e.g. Ubuntu install medium), decrypt all partitions and install timeshift.
```bash
sudo cryptsetup luksOpen /dev/vda3 cryptdata
sudo pacman -S timeshift
```
Run timeshift either in GUI or CLI mode, set the options and restore your system. 


### Manually or if the above fails
Run a live system (e.g. Ubuntu install medium), decrypt all partitions and install timeshift.
```bash
sudo cryptsetup luksOpen /dev/vda3 cryptdata
sudo pacman -S install timeshift
```
Mount the top level root filesystem to /mnt:
```bash
sudo mount -o subvolid=@ /dev/mapper/cryptdata /mnt
```
Now move or rename the bad @ snapshot.
```bash
sudo mv /mnt/@ /mnt/@.bad
```
and move a good one to be your new @:
```bash
sudo mv /mnt/timeshift-btrfs/snapshots/2020-05-06_23-35-24/@ /mnt/@
```

In some cases (if you want to revert failed kernel updates or failed changes to initramfs), you should also restore your EFI partition. That is, mount your efi partition into the the new @ and restore the efi backup:
```bash
sudo mount /dev/vda1 /mnt/@/boot/efi
sudo rsync -avuP --delete /mnt/@/boot.backup/efi/ /mnt/@/boot/efi/
```
Reboot. If something went wrong, but you are sure that your snapshot is actually fine, then you need to chroot into your system as described in the next section.

### Last resort: chroot method
If you need to access your system via a chroot environment, then run a live system (e.g. Ubuntu install medium), decrypt all partitions and mount @:
```bash
sudo cryptsetup luksOpen /dev/vda3 cryptdata
mount -o subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd /dev/mapper/cryptdata /mnt
for n in proc sys dev etc/resolv.conf; do mount --rbind /$n /mnt/$n; done
chroot /mnt
mount -av # in case you need the other subvolumes and partitions
# DO SOME ROOT STUFF
```
Typically, these commands should restore a working snapshot:
```bash
pacman -S --reinstall grub-efi-amd64-signed linux-generic linux-headers-generic
update-initramfs -c -k all
grub-install /dev/vda
update-grub
```
Reboot!
