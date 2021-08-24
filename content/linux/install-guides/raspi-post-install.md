---
title: 'Ubuntu Server Raspberry Pi: Things to do after installation (Apps, Settings, and Tweaks)'
#linktitle: Raspberry Pi apps-settings-tweaks
summary: In the following I will go through my post installation steps, i.e. which settings I choose and which apps and containers I install and use on my Raspberry Pi 4 (4 GB)
toc: true
type: book
#date: "2021-01-11"
draft: false
weight: 14
---

***Please feel free to raise any comments or issues on the [website's Github repository](https://github.com/wmutschl/website-academic). Pull requests are very much appreciated.***

In the following I will go through my post installation steps, i.e. which settings I choose and which apps I install and use on my Raspberry Pi 4 (4 GB) after [installing Ubuntu Server 20.10 with btrfs-luks booted from an external USB drive](../raspi-btrfs).


## Basic steps

#### Set hostname
By default the Pi is called ubuntu; but, I rename it for better accessability on the network:
```sh
sudo hostnamectl set-hostname raspi4
```

#### Set up locales and keyboard language
Even though I am based in Germany, I use `en_US` for my locales on my server:
```sh
sudo locale-gen en_US.UTF-8 de_DE.UTF-8
# Generating locales (this might take a while)...
#   de_DE.UTF-8... done
#   en_US.UTF-8... done
# Generation complete.
sudo update-locale LANG=en_US.UTF-8
```
Check the timezone:
```
sudo dpkg-reconfigure tzdata
# Current default time zone: 'Europe/Berlin'
# Local time is now:      Mon Jan 11 20:40:36 CET 2021.
# Universal Time is now:  Mon Jan 11 19:40:36 UTC 2021.
```
and change the keyboard language to 'de':
```sh
L='de' && sudo sed -i 's/XKBLAYOUT=\"\w*"/XKBLAYOUT=\"'$L'\"/g' /etc/default/keyboard
cat /etc/default/keyboard 
# XKBMODEL="pc105"
# XKBLAYOUT="de"
# XKBVARIANT=""
# XKBOPTIONS=""
# 
# BACKSPACE="guess"
```


#### Use alternate mappings for "page up" and "page down" to search the history
```sh
sudo nano /etc/inputrc
# Uncomment:
# "\e[5~": history-search-backward
# "\e[6~": history-search-forward
```

#### SSH settings and SSH keys for passwordless logins
Add your public keys for passwordless logins in the `authorized_keys` file:
```sh
nano /home/$USER/.ssh/authorized_keys
# Add public keys:
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7vrYpbvJaZq2L1Gm7BrrCyl1iPCUephMZScwdentw3 XPS
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIfzrJ10mpCU6s4MEcCDtzILvD8gIYYzxoDAO1P9WadH iPad-iPhone
# ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKX/swGeaikcTOx/7rNbyBkeJI3VMiWCkywrdLDfyqJe precision
```


Check settings of the SSH server:
```sh
sudo nano /etc/ssh/sshd_config
# PubkeyAuthentication yes
# PasswordAuthentication no
# PermitRootLogin prohibit-password

sudo systemctl restart ssh
```
Before you close the Terminal, open another terminal and check whether you can SSH in without a password.

#### Pull server scripts from GitHub and create folder for logs

## Scripts
I keep my log files on GitHub, so let's clone that (private) repository (note that I spell out the scripts I use on my Pi below) and create a folder for log files:
```sh
git clone git@github.com:wmutschl/server-scripts.git /home/$USER/scripts
mkdir -p /home/$USER/logs
```

### Monitoring Cron Jobs with logs and healthchecks.io
I am runnning Cron Jobs for my maintenance scripts. To monitor these I am saving the output of the scripts into my `logs` folder. Moreover, I am using [healthchecks.io](https://healthchecks.io) such that in case a script does not succeed or is not executed on time I get a warning via email. In the scripts below the `BASEURL` environmental variables need to be adapted by the URLs to the healtchecks.io base urls.

My crontab looks like this (`sudo crontab -l`):
```sh
@daily     /home/ubuntu/scripts/wasabi.sh         >> /home/ubuntu/logs/wasabi.log        2>&1
@weekly    /home/ubuntu/scripts/btrfs-balance.sh  >> /home/ubuntu/logs/btrfs-balance.log 2>&1
@monthly   /home/ubuntu/scripts/btrfs-scrub.sh    >> /home/ubuntu/logs/btrfs-scrub.log   2>&1
```

### btrfs balance
I do a weekly [btrfs balance](https://btrfs.wiki.kernel.org/index.php/Manpage/btrfs-balance) using the following script adapted from [btrfsmaintenance](https://github.com/kdave/btrfsmaintenance):
```sh
#!/bin/bash
BTRFS_BALANCE_BASEURL="https://hc-ping.com/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

echo "*****************************************************"
echo $(date)
echo " "

baseurl=$BTRFS_BALANCE_BASEURL
url=$baseurl
curl -s -m 10 --retry 5 $url/start > /dev/null

echo " "
MOUNTPOINTS="/"
DUSAGES="0 5 10"
MUSAGES="0 5 10"
for MP in $MOUNTPOINTS; do
  for DU in $DUSAGES; do
    for MU in $MUSAGES; do
      cmd="btrfs balance start -dusage=$DU -musage=$MU $MP"
      echo $cmd
      $cmd
      if [ $? -ne 0 ]; then url=$baseurl/fail;fi
    done
  done
  btrfs filesystem df $MP
  df -H $MP
  echo " "
done

echo " "
echo "HealthChecks.io:"
echo $url
curl -s -m 10 --retry 5 $url > /dev/null
echo " "
echo $(date)
echo "Finished"
echo "*****************************************************"
```

### btrfs scrub
I do a monthly [btrfs scrub](https://btrfs.wiki.kernel.org/index.php/Manpage/btrfs-scrub) using the following script adapted from [btrfsmaintenance](https://github.com/kdave/btrfsmaintenance):

```sh
#!/bin/bash
BTRFS_SCRUB_BASEURL="https://hc-ping.com/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"

echo "*****************************************************"
echo $(date)
echo " "

baseurl=$BTRFS_SCRUB_BASEURL
url=$baseurl
curl -s -m 10 --retry 5 $url/start > /dev/null

echo " "
MOUNTPOINTS="/"
# Priority of IO at which the scrub process will run. Idle should not degrade performance but may take longer to finish.
BTRFS_SCRUB_PRIORITY="normal"
# Do read-only scrub and don't try to repair anything.
BTRFS_SCRUB_READ_ONLY="false"

readonly=
if [ "$BTRFS_SCRUB_READ_ONLY" = "true" ]; then
  readonly=-r
fi
ioprio=
if [ "$BTRFS_SCRUB_PRIORITY" = "normal" ]; then
  # ionice(3) best-effort, level 4
  ioprio="-c 2 -n 4"
fi

for MNT in $MOUNTPOINTS; do
  echo "Running scrub on $MNT"
  btrfs scrub start -Bd $ioprio $readonly "$MNT"
  if [ "$?" != "0" ]; then
    echo "Scrub cancelled at $MNT"
    url=$baseurl/fail
  fi
done

echo " "
echo "HealthChecks.io:"
echo $url
curl -s -m 10 --retry 5 $url > /dev/null
echo " "
echo $(date)
echo "Finished"
echo "*****************************************************"
```

### Backup home directory to Wasabi using restic
I do a daily encrypted backup of my home directory files with [Restic](https://restic.net/) to [Wasabi cloud storage](https://wasabi-support.zendesk.com/hc/en-us/articles/115002240372-How-do-I-use-Restic-with-Wasabi-). First let's install restic:

```sh
sudo apt install restic
sudo restic self-update #optionally
```

Optionally, if you have not done so yet, create a new bucket on Wasabi (let's call it raspi4) and initialize it with restic:
```sh
export WASABI_BASEURL="https://hc-ping.com/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export RESTIC_PASSWORD="XXXXXXXXXX"
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXX"
export WASABI_SERVICE_URL="s3.eu-central-1.wasabisys.com"
export WASABI_BUCKET_NAME="raspi4"

restic -r s3:https://$WASABI_SERVICE_URL/$WASABI_BUCKET_NAME init
```

The script (`wasabi.sh`) which I use for the backup is:

```sh
#!/bin/bash
export WASABI_BASEURL="https://hc-ping.com/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
export RESTIC_PASSWORD="XXXXXXXXXX"
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXX"
export WASABI_SERVICE_URL="s3.eu-central-1.wasabisys.com"
export WASABI_BUCKET_NAME="raspi4"

echo "*****************************************************"
echo $(date)
echo " "

baseurl=$WASABI_BASEURL
curl -s --retry 3 $baseurl/start  > /dev/null
url=$baseurl

echo " "
echo "Backing up /home/ubuntu to WASABI"

btrfs subvolume snapshot -r /btr_pool/@home /btr_pool/@home_wasabi
if [ $? -ne 0 ]; then url=$baseurl/fail; fi
restic cache --cleanup
restic backup -r s3:https://$WASABI_SERVICE_URL/$WASABI_BUCKET_NAME /btr_pool/@home_wasabi/ubuntu
if [ $? -ne 0 ]; then url=$baseurl/fail; fi
restic -r s3:https://$WASABI_SERVICE_URL/$WASABI_BUCKET_NAME snapshots
if [ $? -ne 0 ]; then url=$baseurl/fail; fi
btrfs subvolume delete /btr_pool/@home_wasabi
if [ $? -ne 0 ]; then url=$baseurl/fail; fi

echo " "
echo "HealthChecks.io:"
echo $url
curl -s --retry 3 $url > /dev/null
echo " "
echo $(date)
echo "Finished"
```

[See below](#restore-backup) for how to restore files with Restic from Wasabi.


## Backup target for btrfs send/receive with BTRBK

### On my Raspberry Pi
On my computers, I use [BTRBK](https://github.com/digint/btrbk) to send and receive my btrfs snapshots to `/btr_pool/btrbk-precision`. So I make sure that all dependencies are installed by also installing `BTRBK` on the PI:
```sh
mkdir /btr_pool/btrbk-precision
sudo apt install btrbk
```
I have a dedicated SSH Key for BTRBK on my computers. I add the corresponding public key to `/root/.ssh/authorized_keys`. Also I restrict this access using the `ssh_filter_btrbk.sh` script:

```sh
sudo -i
echo 'command="/usr/share/btrbk/scripts/ssh_filter_btrbk.sh --log --target --info --delete" ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTN6c3+YNVXfilLIZWT0yecFyfzWuqC/33LAETIqFmDYo2IC6Q5LNoH3AJ45vrrcLWZMIrP1de9tn9JCWR9PoKap6/WOf307nFNwnYlv1/L/5+LsJTmCxxvTHFJqYHojeYZu3E7kYzviejUIBGcWbzSBJKorMpy1UgsuvlDyBhgc4KdyXjh5gyAG8UZrYgUDmYZg9gZ/arCeyCTinPIANN0ZAyAnBHvCBiNFLZjVei3Sh2+VQTmjRTPazFst1ABuE169Lp6QUdfiizsjYoInA5b4yODgYv614YBA8fmP41Yt1oMrOEOQBLgRP80itzHBmoSVD+UNQva2HP6C2fPml1 btrbk' >> /root/.ssh/authorized_keys
```

### On my Fedora machine
For example, the configuration file `/home/wmutschl/scripts/btrbk-precision.conf` of BTRBK on my Fedora machine looks like this:
```sh
transaction_log         /var/log/btrbk.log
stream_buffer           256m
snapshot_dir            _btrbk_snap

snapshot_qgroup_destroy yes
target_qgroup_destroy   yes

snapshot_preserve_min   2d
snapshot_preserve       14d

target_preserve_min     2d
target_preserve         5d 3w 2m 1y

archive_preserve_min    latest
archive_preserve        5d 3w 2m 1y

ssh_identity            /home/wmutschl/.ssh/id_btrbk
ssh_user                root

volume /btr_pool
  snapshot_create  always
  target /btr_backup
  target ssh://192.168.178.50/btr_pool/btrbk-precision
  subvolume root
  subvolume home
```

Also, I run BTRBK daily to create snapshots and backup this to both an encrypted internal disk (mounted to /btr_backup) as well as the (encrypted) Raspberry Pi using btrfs send/receive.

```sh
cat /etc/cron.daily/btrbk 
#!/bin/sh
exec /usr/bin/btrbk -q -c /home/wmutschl/scripts/btrbk-precision.conf run
```

## ZRam [Not yet]

Instead of a [encrypted swap partition or file](../ubuntu-btrfs-20-04/#encrypted-swap), I am using [ZRam].

## Docker

As Docker might [gradually exhaust disk space on a BTRFS filesystem](https://github.com/moby/moby/issues/27653), I am creating an (encrypted) ext4 partition for my (disposable) docker images. Alternatively, I will also cover [putting Docker on its own pseudo filesystem using an image file](https://gist.github.com/hopeseekr/cd2058e71d01deca5bae9f4e5a555440). Note that my docker configuration files and personal data reside in my home directory which gets regular btrfs snapshots with Timeshift (see my [installation guide](../raspi-btrfs)) and gets backed up to Wasabi daily.

### Option A: Create dedicated encrypted docker image partition
I will show how to encrypt my second partition (`/dev/sda2`) with luks and auto-unlock it with a key-file. So, open an interactive root shell:
```sh
sudo -i
```
Now let's encrypt `sda2` with luks and add a key-file to open it:
```sh
cryptsetup luksFormat --type=luks2 -c xchacha20,aes-adiantum-plain64 /dev/sda2
# WARNING: Device /dev/sda2 already contains a 'ext4' superblock signature.
# 
# WARNING!
# ========
# This will overwrite data on /dev/sda2 irrevocably.
# 
# Are you sure? (Type 'yes' in capital letters): YES
# Enter passphrase for /dev/sda2: 
# Verify passphrase: 

mkdir /etc/luks
dd if=/dev/urandom of=/etc/luks/boot_os.keyfile bs=4096 count=1
# 1+0 records in
# 1+0 records out
# 4096 bytes (4.1 kB, 4.0 KiB) copied, 0.000928939 s, 4.4 MB/s
chmod u=rx,go-rwx /etc/luks
chmod u=r,go-rwx /etc/luks/boot_os.keyfile
cryptsetup luksAddKey /dev/sda2 /etc/luks/boot_os.keyfile
# Enter any existing passphrase: 
```

Let's restrict the pattern of keyfiles and avoid leaking key material for the initramfs hook:

```bash
echo "KEYFILE_PATTERN=/etc/luks/*.keyfile" >> /etc/cryptsetup-initramfs/conf-hook
echo "UMASK=0077" >> /etc/initramfs-tools/initramfs.conf
```
These commands will harden the security options in the intiramfs configuration file and hook.

Let's unlock the luks partition and create an ext4 filesystem in `crypt_docker`:
```sh
cryptsetup luksOpen /dev/sda2 crypt_docker
# Enter passphrase for /dev/sda2:

mkfs.ext4 /dev/mapper/crypt_docker
# mke2fs 1.45.6 (20-Mar-2020)
# Creating filesystem with 1210112 4k blocks and 303104 inodes
# Filesystem UUID: b34df824-3749-421e-9ad4-c1c86a6ef55e
# Superblock backups stored on blocks: 
# 	32768, 98304, 163840, 229376, 294912, 819200, 884736
# 
# Allocating group tables: done                            
# Writing inode tables: done                            
# Creating journal (16384 blocks): done
# Writing superblocks and filesystem accounting information: done 
```

Next, add the partition and keyfile to your `crypttab`:

```bash
echo "crypt_docker   /dev/sda2   /etc/luks/boot_os.keyfile luks" >> /etc/crypttab
# crypt_raspi  /dev/sda3   none   luks
# crypt_docker /dev/sda2   /etc/luks/boot_os.keyfile luks
```

Mount the partition to `/var/lib/docker`:
```sh
mkdir -p /var/lib/docker
echo "/dev/mapper/crypt_docker   /var/lib/docker   ext4   defaults,x-systemd.after=/   0   0" >> /etc/fstab
```
Don't forget to update the initramfs before rebooting your system:
```sh
update-initramfs -u -k all
reboot now
```

### Option B: Create pseudo filesystem for docker images
Alternatively, you can create an image file `docker-volume.img` with a pseudo ext4 filesystem for docker. These steps are similar to creating a [swapfile on btrfs](../-20-04/#option-b-swapfile) as we need to be careful to not mess up snapshots and compression. So we'll put the file in the top-level btrfs root. If you are running a RAID1 system, though, you should probably go with Option A.

So, open an interactive root shell and run the following commands:
```sh
sudo -i

truncate -s 0 /btr_pool/docker-volume.img
chattr +C /btr_pool/docker-volume.img
fallocate -l 10G /btr_pool/docker-volume.img
mkfs.ext4 /btr_pool/docker-volume.img
# mke2fs 1.45.6 (20-Mar-2020)
# Discarding device blocks: done                            
# Creating filesystem with 2621440 4k blocks and 655360 inodes
# Filesystem UUID: 7da7f4d8-6518-4ec3-894b-8819ac2f7c22
# Superblock backups stored on blocks: 
# 	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632
# 
# Allocating group tables: done                            
# Writing inode tables: done                            
# Creating journal (16384 blocks): done
# Writing superblocks and filesystem accounting information: done 

mkdir -p /var/lib/docker
mount -o loop -t ext4 /btr_pool/docker-volume.img /var/lib/docker
df -h
# You should see: /dev/loop6      9.8G   37M  9.3G   1% /var/lib/docker
umount /var/lib/docker
```

Add the pesudo filesystem to the `fstab`:
```sh
echo "/btr_pool/docker-volume.img /var/lib/docker ext4 defaults,x-systemd.after=/ 0 0" >> /etc/fstab
mount /var/lib/docker
```
Now reboot the system and confirm that the volume has auto-mounted.


### Install docker and docker-compose
If you want the latest Docker version, follow the official [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/) steps. I am fine with using the version from the Ubuntu archive:
```sh
sudo apt install docker docker-compose docker.io
sudo usermod -aG docker ${USER}
```

### Create alias
My global docker-compose file resides in `/home/ubuntu/scripts/raspi4-compose.yml`, I make an alias `dc` which I can use for all things related to docker-compose:
```sh
echo "alias dc='docker-compose -f /home/ubuntu/scripts/raspi4-compose.yml'" >> /home/ubuntu/.bashrc
source ~/.bashrc
```

## Home Assistant Docker
I am installing [Home Assistant Core running in a Docker environment](https://www.home-assistant.io/docs/installation/docker/). 

### Restore backup
My configuration files and data reside in `/home/ubuntu/homeassistant`, so I first restore a backup of this from e.g. Wasabi:
```sh
sudo -i
export RESTIC_PASSWORD="XXXXXXXXXX"
export AWS_ACCESS_KEY_ID="XXXXXXXXXXXXXX"
export AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXX"
export WASABI_SERVICE_URL="s3.eu-central-1.wasabisys.com"
export WASABI_BUCKET_NAME="raspi4"

restic -r s3:https://$WASABI_SERVICE_URL/$WASABI_BUCKET_NAME restore latest --target /home/ubuntu/homeassistant-restore --include "/btr_pool/@home_wasabi/ubuntu/homeassistant"

mv /home/ubuntu/homeassistant-restore/btr_pool/\@home_wasabi/ubuntu/homeassistant/ /home/ubuntu/homeassistant
```

### docker-compose file
My docker-compose file looks like this:

```sh
version: '3'

services:

  homeassistant:
    container_name: home-assistant
    image: homeassistant/raspberrypi4-homeassistant:stable
    volumes:
      - /home/ubuntu/homeassistant:/config
    environment:
      - USER_UID=1000
      - USER_GID=1000
      - TZ=Europe/Berlin
    restart: always
    network_mode: host
```

Doing a `docker-compose pull && docker-compose up -d``gets the service up and running. Of course, I am using my alias for this:
```sh
dc pull
dc up -d
```
Check whether it is working by opening the url of your Pi appended with port 8123 (e.g. [http://192.168.178.50:8123](http://192.168.178.50:8123)).


