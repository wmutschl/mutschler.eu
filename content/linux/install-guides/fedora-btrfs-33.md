---
title: 'Fedora Workstation 33: installation guide with btrfs-luks full disk encryption (optionally including /boot) and auto snapshots with Timeshift'
#linktitle: Fedora 33 btrfs-luks
#summary: In this guide I will walk you through the installation procedure to get a Fedora workstation 33 system with a luks-encrypted partition for the root filesystem (optionally including /boot) formatted with btrfs that contains (renamed) subvolumes @ and @home for / and /home, respectively. I will show how to optimize the btrfs mount options and, in case /boot is on the encrypted partition, how to add a key-file to type the luks passphrase only once for GRUB. This layout enables one to use Timeshift which will regularly take snapshots of the system. Moreover, using grub-btrfs all snapshots can be accessed and booted into from the GRUB menu.
toc: true
type: book
#date: "2020-11-04"
draft: false
weight: 49
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).