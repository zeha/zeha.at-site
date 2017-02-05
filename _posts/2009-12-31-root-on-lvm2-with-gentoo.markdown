--- 
layout: post
title: root-on-LVM2 with Gentoo
mt_id: 68
---
For various reasons I had to reinstall my home desktop, this time using Gentoo Linux.

My desktop systems usually have their root-fs on an LVM2 volume. Alas, such a setup is not covered in the Gentoo Installation Guide. Here are the details:

# Setting up root-on-LVM2 with Gentoo #

_Fact:_ root-on-LVM2 needs an initramfs to work.

Therefore:

*   <tt>emerge lvm2</tt> in your chroot before doing any kernel work.
*   Setup LVM2 as usual (create type <tt>8e</tt> PV partitions, <tt>pvcreate</tt> them, <tt>vgcreate</tt>, <tt>lvcreate</tt>, <tt>mkfs</tt>)
*   Use <tt>genkernel --lvm</tt> to build your kernel.
*   Specify <tt>root=/dev/mapper/VGNAME-LVNAME</tt> and <tt>dolvm</tt> on the kernel command line.

You _may_ need to set these things in your kernel config, too:

*   Disable asynchronous SCSI device scanning
*   Build SCSI/SATA device drivers into your kernel
*   Build device mapper as a module

(These last things are what I did, without testing other options.)

If the initramfs complains about not finding your root-LV, check that there is an <tt>/etc/lvm/lvm.conf</tt> inside the initramfs. Else, <tt>pvscan/vgscan will</tt> scan no devices for PVs/VGs. 
