---
# Page title
title: Why I (still) like btrfs

# Title for the menu link if you wish to use a shorter link title
linktitle: Btrfs

# Page summary for search engines
summary: My personal experiences and notes on the btrfs filesystem.

# Date page published
date: "2020-04-01T00:00:00Z"
lastmod: "2020-04-20T00:00:00Z"

# Academic page type (do not modify)
type: book

# Position of this page in the menu. Remove this option to sort alphabetically
weight: 10

# Page metadata.
draft: false  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
---

Linux is about choice, so since a couple of months I started using btrfs as my filesystem of choice on all my computers and servers. Granted, for most desktop users the default ext4 file system will work just fine; however, for those of us who like to tinker with their system an advanced file system like ZFS or btrfs offers much more functionality. Particularly, the possibility of taking snapshots within seconds (due to copy-on-write) and easy ways to rollback your system in case anything breaks are just awesome selling points for me as an advanced desktop user (and occasional distro hopper). Even though, for an enterprise environment, there is some heated debate why ZFS is allegedly better than btrfs, but for me as a desktop user both filesystems offer basically the same functionality and reliability, that is:

- automatic defragmentation
- builtin raid features
- compression
- data checksums
- extreme flexibility
- snapshots

Ubuntu 20.04 Focal Fossa has given us an experimental installation option which creates ZFS pools and dataset compatible with *zsys*, which is a utility that creates automatic snapshots and adds corresponding GRUB menu entries before any APT operation. However, a full disk encryption is missing from the installer, any manual partitioning needs are not yet possible, and most live systems won't be able to open your root pool as the ZFS modules are not loaded by default in the kernel.[^1] 

[^1]: Granted there are always ways as you can of course adapt `/usr/share/ubiquity/zsys-setup` for your manual partition needs or enable native encryption. Also the Ubuntu live image has the relevant ZFS kernel modules enabled by default, so have this at hand in case your system breaks.

Ubuntu will keep pushing ZFS and this is a good thing, again Linux is about choice. But until then I will stick with btrfs, because - simply put - I understand it better than ZFS, find it much simpler to use, and it is built into the kernel. btrfs commands are very easy, snapshots look like directories, I can create them, delete them, move them around, boot into, replace stuff just like with normal files and folders. Compression works fast, send-receive backups to other drives works incrementally, etc. Also there is a greater availability of open-source CLI and GUI programs for btrfs than for ZFS (on desktop (!) Linux) like [Snapper](https://wiki.archlinux.org/index.php/Snapper), [btrbk](https://github.com/digint/btrbk), [buttermanager](https://github.com/egara/buttermanager) or [btrfsmaintenance](https://github.com/kdave/btrfsmaintenance).

The biggest asset for me, however, is that I love and support [Timeshift](https://github.com/teejee2008/timeshift), as it saved my bacon several times, and *Timeshift* supports btrfs and not ZFS! Also, there are several extensions, on which I contributed, that make working with *Timeshift* and btrfs very user-friendly and comfortable. For instance, I am a developer of [timeshift-autosnap](https://gitlab.com/gobonja/timeshift-autosnap) for ARCH systems and [timeshift-autosnap-apt](https://github.com/wmutschl/timeshift-autosnap-apt) for Debian/Ubuntu based systems. These scripts create automatic snapshots with *Timeshift* during any APT operation. Combined with *grub-btrfs*, which creates GRUB menu entries for all snapshots, this is the perfect setup for my *I love playing with things* use case and replaces any need for *zsys* right now. Of course, I will continue to study and try out ZFS and maybe switch over in due course.

Even though I am quite fond with btrfs for now, there are still some caveats that theoretically might be problematic, and I'd like to mention them for completeness sake:

- btrfs is difficult to deal with when it runs out of space (you have to do a manual rebalance)
- *timeshift-autosnap-apt* does not have error handling and can freeze updates
- swapfiles need special consideration
- advanced features like RAID need careful consideration. I do have very good experience with btrfs in a RAID 1 setting both on my Dell precision 7520 workstation and my KVM server.
- The installers of Ubuntu, Linux Mint, Pop!_OS or ElementaryOS need manual adustment of configuration files and mount options are usually not set optimally for using btrfs on SSD or NVMe.

So I have written several [installation guides](../../install-guides) and made some [YouTube](https://www.youtube.com/playlist?list=PLiN_C6lGtCc-KbqCP1XuWgMp4ky634v0X) videos on my installation steps to install Pop!_OS, Ubuntu or Manjaro with btrfs inside an encrypted luks partition and automatic system snapshots with Timeshift.


## Some caveats [THIS PART IS ONLY NOTES AND THIS NEEDS TO UPDATE THIS PART]
BTRFS will refuse to mount multi-device systems in degraded state, which is if one or more devices are missing, without special mount option degraded. Even so, a BTRFS filesystem should not be manipulated by changing geometry (switching to or from RAID levels, adding or removing disks) when mounted, especially not root, as that will most certainly result with inconsistent filesystem and in some cases inability to boot at all.

I would actually advise to create a RAID1 between 3 devices, if you can. Also in any case, if a disk breaks, boot into a live system and try to replace the disk or make the working disk single again with the balance command

