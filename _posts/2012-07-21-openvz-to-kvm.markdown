--- 
layout: post
title: "My rough OpenVZ -> KVM migration notes"
---

For Debian squeeze based systems.

Preparations on old system
--------------------------

Host: make sure sudo rsync works without password.

Guest: Note IP address, hostname, instance ID. Shut it down.

Migration
---------

* Create new instance using virt-manager
  * Have it boot with a grml.iso
  * LVM-based storage (virtio)
  * Bridge to physical device
  * Tick start on host boot on advanced settings
* Get network connectivity in new guest:
  * ip a add a.b.c.d/24 dev eth0
  * ip r add default via g.w
  * echo nameserver 8.8.8.8 > /etc/resolv.conf
  * passwd root
  * Start ssh
  * ping zeha.at
* Login using ssh, continue:
  * cfdisk /dev/vda, one bootable partition
  * mkfs.ext4 /dev/vda1
  * tune2fs -c0 -i0 /dev/vda1
  * mount /mnt/vda1
  * cd /mnt/vda1
  * rsync -avH --rsync-path="sudo rsync" --numeric-ids user@old-host:/srv/vz/private/100X/ ./
  * grml-chroot .
  * vi /etc/inittab
  * echo '/dev/vda1 / ext4 defaults,errors=remount-ro,noatime,acl 0 1' > /etc/fstab
  * rm /etc/udev/rules.d/70-persistent-* /etc/rc6.d/K00vzreboot
  * passwd root
  * apt-get install -y grub-pc acpid acpi-support-base linux-image-2.6.32-5-amd64 console-setup console-terminus openssh-server
  * /etc/default/grub set GFXMODE=1024x768
  * check network settings
  * check user/root ssh keys (does login work!?)
  * reboot
