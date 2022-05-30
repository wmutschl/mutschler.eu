---
title: 'DRAFT: Pop!_OS 21.10: installation guide with btrfs-LVM-luks and auto snapshots with BTRBK'
#linktitle: Pop!_OS 21.10 btrfs-luks
#summary: In this guide I will walk you through the installation procedure to get a Pop!_OS 21.10 system with a luks-encrypted partition which contains a LVM with a logical volume for the root filesystem that is formatted with btrfs and contains a subvolume @ for / and a subvolume @home for /home. I will show how to optimize the btrfs mount options and how to setup an encrypted swap partition which works with hibernation. This layout enables one to use BTRBK which will regularly take snapshots of the system and optionally on any apt operation. The recovery system of Pop!_OS is also installed to the disk and accessible via the systemd bootloader.
toc: true
type: book
#date: "2021-12-13"
draft: false
weight: 26
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).