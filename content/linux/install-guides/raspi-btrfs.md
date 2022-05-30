---
title: 'Ubuntu Server 20.10 on Raspberry Pi 4: installation guide with USB Boot (no SD card) and full disk encryption (excluding /boot) using btrfs-inside-luks and auto-apt snapshots with Timeshift'
#summary: In this guide I will walk you through the installation procedure to get an Ubuntu 20.10 system with a luks-encrypted partition for the root filesystem (excluding /boot) formatted with btrfs that contains a subvolume @ for / and a subvolume @home for /home running on a Raspberry Pi 4. The system is installed to an external bootable USB drive so no SD card is required. I will show how to optimize the btrfs mount options and how to get a headless server, i.e. remotely unlock the luks partition using Dropbear which enables one to use SSH to decrypt the luks-encrypted partitions after a reboot. This layout enables one to use Timeshift and timeshift-autosnap-apt which will regularly take snapshots of the system and particularly on any apt operation.
#linktitle: Raspberry Pi Ubuntu Server 20.04 USB-boot-btrfs-luks
toc: true
type: book
#date: "2021-01-10"
draft: false
weight: 35
---
This site has moved to [https://mutschler.dev](https://mutschler.dev).