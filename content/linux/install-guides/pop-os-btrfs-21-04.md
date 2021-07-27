---
title: Pop!_OS 21.04 with btrfs-LVM-luks installation guide and auto-apt snapshots with Timeshift
linktitle: Pop!_OS 21.04 btrfs-luks
toc: true
type: book
date: "2021-07-27T00:00:00+01:00"
draft: false

weight: 12
---

```md
{{< youtube  >}}
```
*Note that this written guide is an updated version of the video and contains much more information.*

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

## Overview 
I am exclusively using btrfs as my filesystem on all my systems, see [Why I (still) like btrfs](../../btrfs/). So, in this guide I will show how to install Pop!_OS 21.04 with the following structure:

- an unencrypted EFI partition for the systemd bootloader
- an unencrypted partition for the Pop!_OS recovery system
- an encrypted swap partition which works with hibernation
- a btrfs-LVM-inside-luks partition for the root filesystem
  - the btrfs logical volume contains a subvolume `@` for `/` and a subvolume `@home` for `/home`. Note that the Pop!_OS installer does not create any subvolumes on btrfs, so we need to do this manually.
- automatic system snapshots and easy rollback similar to *zsys* using:
   - [Timeshift](https://github.com/teejee2008/timeshift) which will regularly take (almost instant) snapshots of the system
   - [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) which will automatically run Timeshift on any apt operation and also keep a backup of your EFI partition inside the snapshot

With this setup you basically get the same comfort of Ubuntu's ZFS and *zsys* initiative, but with much more flexibility and comfort due to the awesome [Timeshift](https://github.com/teejee2008/timeshift) program, which saved my bacon quite a few times. This setup works similarly well on other distributions, for which I also have [installation guides with optional RAID1](../../install-guides).

**If you ever need to rollback your system, checkout [Recovery and system rollback with Timeshift](../../timeshift).**


## Step 0: General remarks
This tutorial is made with Pop!_OS 21.04 from https://system76.com/pop copied to an installation media (usually a USB Flash device but may be a DVD or the ISO file attached to a virtual machine hypervisor). Other versions of Pop!_OS and other distributions that use Systemd boot manager might also work, but sometimes require additional steps (see my other [installation guides](../../install-guides)).

**I strongly advise to try the following installation steps in a virtual machine first before doing anything like that on real hardware!**
For instance, you can spin up a virtual machine with 4 cores, 8 GB RAM, and a 64GB disk using e.g. the awesome bash script [quickemu](https://github.com/wimpysworld/quickemu). 

In the following, however, I outline the steps for my Dell Precision 7520 with a NVME drive.

## Step 1: Boot the install and open an interactive root shell
POP!_OS is a UEFI only system, so once the Live Desktop environment has started choose your language, region, and keyboard layout, then hit `Try Demo Mode`. Open a terminal and switch to an interactive root session:
```bash
sudo -i
```
You might find maximizing the terminal window is helpful for working with the command-line. Do not close this terminal window during the whole installation process until we are finished with everything.

## Step 2: Prepare partitions manually

### Create partition table and layout

First find out the name of your drive. You can also open `gparted` or have a look into the `/dev` folder to make sure what your hard drives are called. In most cases they are called `sda`, `sdb`, `sdc`... for normal SSD and HDD, whereas for NVME storage the naming is `nvme0n1`, `nvme0n2`, `nvme0n3`,.... I usually use the following command to get an overview:
```bash
lsblk
# NAME    MAJ:MIN RM    SIZE RO TYPE MOUNTPOINT
# loop0     7:0    0    2.6G  1 loop /rofs
# sda       8:0    0  465.8G  0 disk 
# └─sda1    8:1    0  465.8G  0 part 
# sdb       8:16   1    3.7G  0 disk 
# ├─sdb1    8:17   1    2.7G  0 part /cdrom
# ├─sdb2    8:18   1      4M  0 part 
# └─sdb3    8:19   1 1011.5M  0 part /var/crash
# nvme0n1 259:0    0  476.9G  0 disk
```
In my case `sda` is an internal SSD that I use for [my backup strategy](../../backup/#5-dell-precision-7520-fedora), whereas `sdb` is the flash drive that contains the installation files. So, for me the installation target device is called `nvme0n1`.

We'll now create a disk table and add four partitions on `nvme0n1`:

1. a 498 MiB FAT32 EFI partition for the systemd bootloader
2. a 4096 MiB FAT32 partition for the Pop!_OS recovery system
3. a 4096 MiB swap partition for encrypted swap use
4. a luks2 encrypted partition which contains a LVM with one logical volume formatted with btrfs, which will be our root filesystem

Some remarks:

- The LVM is actually a bit of an overkill for my typical use case, but otherwise the installer cannot access the luks partition.
- `/boot` will reside on the encrypted partition. The systemd bootloader is able to decrypt this at boot time.
- With btrfs I do not need any other partitions for e.g. `/home`, as we will use subvolumes instead. 

Let's use `parted` for this:
```bash
parted /dev/nvme0n1 mklabel gpt
# Confirm with Yes
parted /dev/nvme0n1 mkpart primary fat32 2MiB 500MiB
parted /dev/nvme0n1 mkpart primary fat32 500MiB 4596MiB
parted /dev/nvme0n1 mkpart primary 4596MiB 8692MiB
parted /dev/nvme0n1 mkpart primary 8692MiB 100%
parted /dev/nvme0n1 name 1 EFI
parted /dev/nvme0n1 name 2 recovery
parted /dev/nvme0n1 name 3 SWAP
parted /dev/nvme0n1 name 4 POPOS
parted /dev/nvme0n1 set 1 esp on
parted /dev/nvme0n1 set 3 swap on
parted /dev/nvme0n1 unit MiB print
# Model: PM961 NVMe SAMSUNG 512GB (nvme)
# Disk /dev/nvme0n1: 488386MiB
# Sector size (logical/physical): 512B/512B
# Partition Table: gpt
# Disk Flags: 
# 
# Number  Start    End        Size       File system  Name      Flags
#  1      2.00MiB  500MiB     498MiB     fat32        EFI       boot, esp
#  2      500MiB   4596MiB    4096MiB    fat32        recovery  msftdata
#  3      4596MiB  8692MiB    4096MiB                 SWAP      swap
#  4      8692MiB  488386MiB  479694MiB               POPOS
```

### Create luks2 partition, LVM and btrfs root filesystem

Pop!_OS uses the systemd bootloader, which can handle luks type 2 encryption just fine at boot time, so we can use the default options of `cryptsetup luksFormat` to format our `nvme0n1p4` partition and map it to a device called `cryptdata`, which will contain our LVM:

```bash
cryptsetup luksFormat /dev/nvme0n1p4
# WARNING!
# ========
# This will overwrite data on /dev/nvme0n1p4 irrevocably.
# Are you sure? (Type uppercase yes): YES
# Enter passphrase for /dev/nvme0n1p4: 
# Verify passphrase:
cryptsetup luksOpen /dev/nvme0n1p4 cryptdata
# Enter passphrase for /dev/nvme0n1p4:
ls /dev/mapper
# control cryptdata
```
Use a very good password here. Now we need to create the LVM for the Pop!_OS installer, i.e. 

- make `cryptdata` a physical volume
- add a new volume group and call it also `data`
- create a logical volume `root` for our root partition

These are also the steps the Pop!_OS installer performs when you click `Clean install` albeit with ext4 as the filesystem; so here are the commands:

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
`data-root` is our root partition which we'll use for the root filesystem. We will use the Pop!_OS installer to format it to btrfs and after the installation create two subvolumes: 

- `@` for `/`
- `@home` for `/home`

This is the typical btrfs layout used by the Ubuntu installer and supported by tools like Timeshift. Pop!_OS, however, does not create any subvolumes by default, so we will do that manually after the usual installation process.

## Step 3: Install Pop!_OS using the graphical installer

Now let's open the installer from the dock, select the region, language and keyboard layout. Then choose `Custom (Advanced)`. You will see your partitioned hard disk:

- Click on the first partition, activate `Use partition`, activate `Format`, Use as `Boot /boot/efi`, Filesystem: `fat32`.
- Click on the second partition, activate `Use partition`, activate `Format`, Use as `Custom` and enter `/recovery`, Filesystem: `fat32`.
- Click on the third partition, activate `Use partition`, Use as `Swap`.
- Click on the fourth and largest partition. A `Decrypt This Partition` dialog opens, enter your luks password and hit `Decrypt`. A new line is displayed `LVM data`. Click on this partition, activate `Use partition`, activate `Format`, Use as `Root (/)` , Filesystem: `btrfs`.

*If you have other partitions, check their types and use; particularly, deactivate other EFI partitions.*

Recheck everything (check the partitions where there is a black checkmark) and hit `Erase and Install`. Follow the steps to create a user account and to write the changes to the disk. Once the installer finishes do NOT **Restart Device**, but return to your terminal.

## Step 4: Post-Installation steps

### Mount the btrfs top-level root filesystem

Let's mount our root partition (the top-level btrfs volume always has root-id 5), but with mount options that optimize performance and durability on SSD or NVME drives:
```bash
cryptsetup luksOpen /dev/nvme0n1p4 cryptdata
# Enter passphrase for /dev/nvme0n1p4
mount -o subvolid=5,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async /dev/mapper/data-root /mnt
```
 I have found that there is some general agreement to use the following mount options, namely:

- `ssd`: use SSD specific options for optimal use on SSD and NVME
- `noatime`: prevent frequent disk writes by instructing the Linux kernel not to store the last access time of files and folders
- `space_cache`: allows btrfs to store free space cache on the disk to make caching of a block group much quicker
- `commit=120`: time interval in which data is written to the filesystem (value of 120 is taken from Manjaro's minimal iso)
- `compress=zstd`: allows to specify the compression algorithm which we want to use. btrfs provides lzo, zstd and zlib compression algorithms; however, zstd has become the best performing candidate.
- `discard=async`: [Btrfs Async Discard Support Looks To Be Ready For Linux 5.6](https://www.phoronix.com/scan.php?page=news_item&px=Btrfs-Async-Discard)

We will later also append these mount options to the fstab, but it is good practice to already make use of these optimizations.

### Create btrfs subvolumes `@` and `@home`

Now we will first create the subvolume `@` and move all files and folders from the top-level filesystem into `@`. Note that as we use the optimized mount options like compression, these will be applied during the moving process:
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

### Changes to fstab and crypttab
We need to adapt the `fstab` to
- mount `/` from `@`
- mount `/home` from `@home`
- optimize mount options for btrfs

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

# PARTUUID=57a2caa4-adb4-4b30-bf56-370907690882  /boot/efi  vfat  umask=0077  0  0
# PARTUUID=bc7b4892-230a-46ed-91a7-418b7b2726e1  /recovery  vfat  umask=0077  0  0
# /dev/mapper/cryptswap  none  swap  defaults  0  0
# UUID=498cd72c-fdcb-4569-991d-229aa17d3dd4  /  btrfs  defaults,subvol=@,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async  0  0
# UUID=498cd72c-fdcb-4569-991d-229aa17d3dd4 /home btrfs defaults,subvol=@home,ssd,noatime,space_cache,commit=120,compress=zstd,discard=async 0 0
```
Note that your PARTUUID and UUID numbers will be different.

Lastly, as we use `discard=async`, we need to add discard to the `crypttab`:

```sh
sed -i 's/luks/luks,discard/' /mnt/@/etc/crypttab
cat /mnt/@/etc/crypttab
# cryptswap UUID=4811153e-7b1d-489d-a350-a5b58e0c05b5 /dev/urandom swap,plain,offset=1024,cipher=aes-xts-plain64,size=512
# cryptdata UUID=48acea7a-7290-40de-b3c8-3fab4e328f60 none luks,discard
```

### Adjust configuration of systemd bootloader and kernelstub
We need to adjust some settings for the systemd boot manager and also make sure these settings are not overwritten if we install or update kernels and modules.

Let's mount our EFI partition
```bash
mount /dev/nvme0n1p1 /mnt/@/boot/efi
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


## Step 5: Reboot, some checks, and update system

Now, it is time to exit the chroot - cross your fingers - and reboot the system:

```bash
exit
# exit
reboot now
```

If all went well you should see a single passphrase prompt (YAY!), where you enter the luks passphrase and your system boots. 

Now let's click through the welcome screen (actually it took a minute until the welcome screen appeared). Anyways, open a terminal to see whether everything is set up correctly:

```bash
sudo mount -av
# /boot/efi                : already mounted
# /recovery                : already mounted
# none                     : ignored
# /                        : ignored
# /home                    : already mounted

sudo mount -v | grep /dev/mapper
# /dev/mapper/data-root on / type btrfs (rw,noatime,compress=zstd:3,ssd,discard=async,space_cache,commit=120,subvolid=264,subvol=/@)
# /dev/mapper/data-root on /home type btrfs (rw,noatime,compress=zstd:3,ssd,discard=async,space_cache,commit=120,subvolid=265,subvol=/@home)

sudo swapon
# NAME           TYPE      SIZE USED PRIO
# /dev/dm-2      partition 4G   0B   -2

sudo btrfs filesystem show /
# Label: none  uuid: 498cd72c-fdcb-4569-991d-229aa17d3dd4
# 	Total devices 1 FS bytes used 6.75GiB
# 	devid    1 size 468.43GiB used 8.02GiB path dm-1

sudo btrfs subvolume list /
# ID 264 gen 410 top level 5 path @
# ID 265 gen 410 top level 5 path @home
```
If all look's good, let's update and upgrade the system:

```bash
sudo apt update
sudo apt upgrade
sudo apt dist-upgrade
sudo apt autoremove
sudo apt autoclean
```

Optionally, if you installed on a SSD and NVME, enable `fstrim.timer` as [both fstrim and discard=async mount option can peacefully co-exist](https://www.phoronix.com/scan.php?page=news_item&px=Fedora-Btrfs-Opts-Discard-Comp):
```sh
sudo systemctl enable fstrim.timer
```
Again, for [SSD trimming to work properly](https://www.heise.de/ct/hotline/Linux-Verschluesselte-SSD-trimmen-2405875.html), it is important that you add `discard` to your `crypttab` (see above). Also check whether you find `issue_discards=1` in `/etc/lvm/lvm.conf` (which should be correct by default).

Now reboot:
```bash
sudo reboot now
```


## Step 6: Install Timeshift and timeshift-autosnap-apt

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
     * Note that sometimes I ran into issues when activating all schedule levels, so I deactivate either hourly or boot.
     * continue with "Next"
     * I also include the `@home` subvolume (which is not selected by default). Note that when you restore a snapshot Timeshift you get the choise whether you want to restore it as well (which in most cases you don't want to).
     * I check "Enable BTRFS qgroups (recommended)". Note that some people [reported slowdowns when using Timeshift with quotas](https://forum.manjaro.org/t/freeze-issues-with-btrfs-and-timeshift/22005/11), but for me it is working fine the recommended way.
     * Click "Finish"
   * "Create" a manual first snapshot & exit Timeshift
  
*Timeshift* will now check every hour if snapshots ("hourly", "daily", "weekly", "monthly", "boot") need to be created or deleted. Note that "boot" snapshots will not be created directly but about 10 minutes after a system startup.

*Timeshift* puts all snapshots into `/run/timeshift/backup`. Conveniently, the real root (subvolid 5) of your BTRFS partition is also mounted here, so it is easy to view, create, delete and move around snapshots manually.

```bash
ls /run/timeshift/backup
# @  @home  timeshift-btrfs
```
Note that `/run/timeshift/backup/@` contains your `/` folder and `/run/timeshift/backup/@home` contains your `/home` folder.

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
# /dev/dm-1 is mounted at: /run/timeshift/backup, options: rw,relatime,compress=zstd:3,ssd,discard=async,space_cache,commit=120,subvolid=5,subvol=/
# 
# Creating new backup...(BTRFS)
# Saving to device: /dev/dm-1, mounted at path: /run/timeshift/backup
# Created directory: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-07-27_22-14-29
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-07-27_22-14-29/@
# Created subvolume snapshot: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-07-27_22-14-29/@home
# Created control file: /run/timeshift/backup/timeshift-btrfs/snapshots/2021-07-27_22-14-29/info.json
# BTRFS Snapshot saved successfully (0s)
# Tagged snapshot '2021-07-27_22-14-29': ondemand
```

Now, if you run `sudo apt install|remove|upgrade|dist-upgrade`, *timeshift-autosnap-apt* will create a snapshot of your system with *Timeshift*.

**FINISHED! CONGRATULATIONS AND THANKS FOR STICKING THROUGH!**

**Check out my [Pop!_OS post-installation steps](../pop-os-post-install).**

**If you ever need to rollback your system, checkout my [Recovery and system rollback with Timeshift](../../timeshift).**