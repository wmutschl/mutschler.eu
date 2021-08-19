---
title: Timeshift (under construction)
#linktitle: Timeshift
summary: My personal experience and projects regarding Timeshift.
#date: "2020-04-01T00:00:00Z"
type: book
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
weight: 20
---

### If you can access your desktop environment (either directly or via an old snapshot)

Launch Timeshift from the menu (or desktop shortcut) and select a snapshot and hit restore. A reboot and you're done. Takes mere seconds and doesn’t get any easier.

### If you can't boot into your desktop environment
Run a live system, decrypt all partitions and install Timeshift.
```bash
sudo cryptsetup luksOpen /dev/vda3 cryptdata
sudo apt install timeshift
```
Run timeshift either in GUI or CLI mode, set the options and restore your system. 


### Manually or if the above fails
Run a live system (e.g. Ubuntu install medium), decrypt all partitions and install timeshift.
```bash
sudo cryptsetup luksOpen /dev/vda3 cryptdata
sudo apt install timeshift
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
apt install -y --reinstall grub-efi-amd64-signed linux-generic linux-headers-generic
update-initramfs -c -k all
grub-install /dev/vda
update-grub
```
Reboot!

## Emergency scenario: RAID1 is broken (in-progress to generalize this)
### vda is broken
Let's assume vda is broken (to this end I shutdown the virtual machine and added an empty vda). 
Now we need to open the EFI BOOT MANAGER IN BIOS and select to boot from the EFI partition on vdb. The system will not boot, but we have our recovery system on vdb, so let's boot into it. Then, we need to chroot in degraded mode into the system, change PARTUUID in the fstab, and remove the bad drive from the crypttab:
```bash
sudo -i
cryptsetup luksOpen /dev/vdb4 crypt_vdb
mount -o subvol=@,degraded /dev/mapper/data_vdb-root /mnt
mount /dev/vdb1 /mnt/boot/efi
for n in proc sys dev etc/resolv.conf; do mount --rbind /$n /mnt/$n; done

chroot /mnt

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
Choose POP!_OS (degraded) in the boot menu and you can boot into your system and repair it!

### vdb is broken
Let's assume vdb is broken (to this end I shutdown the virtual machine and added a empty vdb). 
Now we need to open the EFI BOOT MANAGER IN BIOS and select to boot from the EFI partition on vdb. The system will not boot, but we have our recovery system on vda, so let's boot into it. Then, we need to chroot in degraded mode into the system and remove the bad drive from the crypttab:
```bash
sudo -i
cryptsetup luksOpen /dev/vda4 crypt_vda
mount -o subvol=@,degraded /dev/mapper/data_vda-root /mnt
mount /dev/vda1 /mnt/boot/efi
for n in proc sys dev etc/resolv.conf; do mount --rbind /$n /mnt/$n; done

chroot /mnt

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

TO DO SHOW HOW TO [Repair the Bootloader](https://support.system76.com/articles/bootloader/)