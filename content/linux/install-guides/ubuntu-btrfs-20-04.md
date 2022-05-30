---
title: 'Ubuntu Desktop 20.04: installation guide with btrfs-luks full disk encryption including /boot and auto-apt snapshots with Timeshift'
#linktitle: Ubuntu 20.04 btrfs-luks
#summary: In this guide I will walk you through the installation procedure to get an Ubuntu 20.04 system with a luks-encrypted partition for the root filesystem (including /boot) formatted with btrfs that contains a subvolume @ for / and a subvolume @home for /home. I will show how to optimize the btrfs mount options and how to add a key-file to type the luks passphrase only once for GRUB. I will also cover how to setup an encrypted swap partition or swapfile. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation. Moreover, using grub-btrfs all snapshots can be accessed and booted into from the GRUB menu.
toc: true
type: book
#date: "2020-05-08"
draft: false
weight: 38
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).