---
title: 'Pop!_OS 21.04: installation guide with btrfs-LVM-luks and auto-apt snapshots with Timeshift'
#linktitle: Pop!_OS 21.04 btrfs-luks
#summary: In this guide I will walk you through the installation procedure to get a Pop!_OS 21.04 system with a luks-encrypted partition which contains a LVM with a logical volume for the root filesystem that is formatted with btrfs and contains a subvolume @ for / and a subvolume @home for /home. I will show how to optimize the btrfs mount options and how to setup an encrypted swap partition which works with hibernation. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. The recovery system of Pop!_OS is also installed to the disk and accessible via the systemd bootloader.
toc: true
type: book
#date: "2021-07-27"
draft: false
weight: 27
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).