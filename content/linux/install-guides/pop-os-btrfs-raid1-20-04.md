---
title: 'Pop!_OS 20.04: installation guide with btrfs-LVM-luks-RAID1 and auto-apt snapshots with Timeshift'
#linktitle: Pop!_OS 20.04 btrfs-luks-raid1
#summary: In this guide I will walk you through the installation procedure to get a Pop!_OS 20.04 system with a luks-encrypted partition which contains a LVM with a logical volume for the root filesystem that is formatted with btrfs and contains a subvolume @ for / and a subvolume @home for /home. The system is set up in a RAID1 managed by the btrfs filesystem. I will show how to optimize the btrfs mount options and how to setup encrypted swap partitions which work with hibernation. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. The recovery system of Pop!_OS is also installed to both disks and accessible via the systemd bootloaders. Due to the RAID1 managed by btrfs you get redundancy of your data.
toc: true
type: book
#date: "2020-04-21"
draft: false
weight: 29
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).