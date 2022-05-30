---
title: 'Ubuntu Desktop 20.04: installation guide with btrfs-luks-RAID1 full disk encryption including /boot and auto-apt snapshots with Timeshift'
#linktitle: Ubuntu 20.04 btrfs-luks-raid1
#summary: In this guide I will walk you through the installation procedure to get an Ubuntu 20.04 system with a luks-encrypted partition for the root filesystem (including /boot) formatted with btrfs that contains a subvolume @ for / and a subvolume @home for /home. The system is set up in a RAID1 managed by the btrfs filesystem. I will show how to optimize the btrfs mount options and how to add key-files to type the luks passphrase only once for each disk for GRUB. I will also cover how to setup encrypted swap partitions. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. Moreover, using grub-btrfs all snapshots can be accessed and booted into from the GRUB menu. Due to the RAID1 managed by btrfs you get redundancy of your data.
toc: true
type: book
#date: "2020-05-21"
draft: false
weight: 39
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).