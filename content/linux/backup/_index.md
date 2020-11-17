---
# Page title
title: Backups (One is None)

# Title for the menu link if you wish to use a shorter link title
linktitle: Backups (One is None)

# Page summary for search engines
summary: Here I describe my backup strategy using Nextcloud Sync, restic, rclone, Microsoft One Drive and two good old USB harddisks

# Date page published
date: "2020-07-17T00:00:00Z"
lastmod: "2020-04-20T00:00:00Z"

# Academic page type (do not modify)
type: book

# Position of this page in the menu. Remove this option to sort alphabetically
# weight: 3

# Page metadata.
draft: true  # Is this a draft? true/false
toc: true  # Show table of contents? true/false
---

Computers I have to backup:

- Workstation: running Pop!_OS 20.04
- Laptop: running Windows 10
- Server: running Ubuntu Pop!_OS 20.04

### Connect rclone to Microsoft OneDrive

```bash
sudo apt install rclone
sudo rclone config
  n #for new remote
  remote #name of new remote
  onedrive #storage name
  # hit enter to leave empty client_id
  # hit enter to leave empty client_secret
  n #do not edit advanced config
  n # Use auto config (no, as I am using a remote machine)
```
On another machine with a webbrowser install rclone and run the following

```bash
sudo apt install rclone
rclone authorize "onedrive"
```
Then back to the headless box, paste in the code and choose the relevant options


Install restic
```bash
sudo apt install restic
```

Initialize repo
```bash
sudo restic -r rclone:remote:gitea init
sudo restic -r rclone:remote:nextcloud_snap init
sudo restic -r rclone:remote:nextcloud_data init
```

```bash
sudo rm -rf /var/snap/nextcloud/common/backups/*
sudo nextcloud.export -a -b -c
sudo mv /var/snap/nextcloud/common/backups/* /var/snap/nextcloud/common/backups/AppsDatabaseConfigBackup

sudo btrfs subvolume snapshot -r /btrfs_pool/@ /btrfs_pool/@_restic
sudo btrfs subvolume snapshot -r /btrfs_pool/@home /btrfs_pool/@home_restic

sudo restic -r rclone:remote:gitea backup --verbose --password-file=/home/wmutschl/resticpwd /btrfs_pool/@home_restic/wmutschl/gitea

sudo restic -r rclone:remote:nextcloud_snap backup --verbose --password-file=/home/wmutschl/resticpwd /btrfs_pool/@_restic/var/snap/nextcloud/common/backups

sudo restic -r rclone:remote:nextcloud_data backup --verbose --password-file=/home/wmutschl/resticpwd /btrfs_pool/@_restic/var/snap/nextcloud/common/nextcloud/data

sudo btrfs subvolume delete /btrfs_pool/@_restic
sudo btrfs subvolume delete /btrfs_pool/@home_restic
```

```bash
sudo restic -r rclone:remote:gitea snapshots --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data-subset=1/5 --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data-subset=2/5 --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data-subset=3/5 --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data-subset=4/5 --password-file=/home/wmutschl/resticpwd
sudo restic -r rclone:remote:gitea check --read-data-subset=5/5 --password-file=/home/wmutschl/resticpwd
```

