---
layout: post
title: "Kernel 3.19+ is incompatible with 3PAR OS before 3.2.2 MU3"
---

```
sd 0:0:0:101: [sdj] tag#0 FAILED Result: hostbyte=DID_OK driverbyte=DRIVER_SENSE
sd 0:0:0:101: [sdj] tag#0 Sense Key : Illegal Request [current]
sd 0:0:0:101: [sdj] tag#0 Add. Sense: Invalid field in cdb
sd 0:0:0:101: [sdj] tag#0 CDB: Write same(16) 93 08 00 00 00 00 4c c4 87 fc 00 00 ff ff 00 00
blk_update_request: critical target error, dev sdj, sector 1287948284
blk_update_request: critical target error, dev dm-5, sector 1287948284
```

This is what greets you in dmesg when installing a virtualized Windows or just when copying large files,
IF you run Linux kernel 3.19+, and your Storage is 3PAR OS before 3.2.2 MU3. This is not well
documented.

Before going into the details, here is the TL;DR to fix your issue:

  * Kernels before 3.19 defaulted to the SCSI "UNMAP" command when DISCARDing/TRIMing.
  * Newer kernels default to the SCSI "WRITE SAME (16)" command for this, when they see a 3PAR Volume.
    The exact selection algo can be found in [sd.c:sd_read_block_limits](http://lxr.free-electrons.com/source/drivers/scsi/sd.c?v=4.4#L2651).
  * You can change that default by writing into `/sys/block/sd*/device/scsi_disk/*/provisioning_mode`.
    To go back to the old behaviour, write `unmap` into that file.
  * Or, you just upgrade your storage to 3.2.2 MU3 or newer.

Some references:

  * https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1585668
  * [commit 7985090aa0201fa7760583f9f8e6ba41a8d4c392](https://github.com/torvalds/linux/commit/7985090aa0201fa7760583f9f8e6ba41a8d4c392)
  * [3.16 backport patchwork "documenting" known issues with that change](https://patchwork.kernel.org/patch/8950011/)
  * [HPE SPOCK article "documenting" that this is a known bug in 3PAR OS < 3.2.2MU3](https://h20272.www2.hpe.com/SPOCK/Content/ConfigurationSetDetailView.aspx?Id=82343)


More details: decoding that CDB
===============================

When you see that error message for the first time, it does not really look helpful. One, it does not appear to tell you what command is failing.
Now that is not true: the text after after "tag#xx CDB:" shows you the translated command name; here: "Write same (16)".

Unfortunately this does not hint at what is actually going on - you have to decode the actual CDB yourself to know more.
With the help of the [Seagate SCSI Reference](http://www.seagate.com/files/staticfiles/support/docs/manual/Interface%20manuals/100293068h.pdf) we find:

Our CDB was: `93 08 00 00 00 00 4c c4 87 fc 00 00 ff ff 00 00`.

  - `93`: Command WRITE SAME (16)
  - `08`: Flags; bit 3 indicates "UNMAP" (instead of actually writing data)
  - `00 00 00 00 4c c4 87 fc`: Address to write to (the reported failing `sector`: 1287948284 == 0x4cc487fc)
  - `00 00 ff ff`: Number of blocks (here: 64K)
  - `00`: Reserved / Group Number
  - `00`: CONTROL

Now with this knowledge, you can understand the failing command is an UNMAP of size 64K blocks, starting at sector 1287948284,
here implemented using the newer WRITE SAME (16) command.

Once you know that, finding the [commit](https://github.com/torvalds/linux/commit/7985090aa0201fa7760583f9f8e6ba41a8d4c392) changing the kernel behaviour is
easy. (In my case, I have done a verification against kernel 3.16, which does not show the problem.)


What is UNMAP?
==============

UNMAP is the SCSI implementation (remember SAS is "just" SCSI over a new link, and FC is also SCSI over another link) of TRIM.
(In the Linux kernel sources, this concept is referred to as DISCARD.)

UNMAP: the act of forgetting data.

As you have seen above, SCSI has multiple ways to do an UNMAP: it has the straight forward UNMAP command, and it has the UNMAP bit in the WRITE SAME 10/16/32 commands.

Why have both? Well. UNMAP is allowed to be ignored by drivers and other intermediaries. The WRITE SAME commands must be passed through.


Understanding even more: WRITE SAME 16 vs. UNMAP
================================================

To understand the issue better, we can try sending those problematic commands to the storage. For this, `sg3-utils` has a really handy tool
called `sg_write_same`. Example:

**WARNING: this is destructive to any data found on the specified block device.**

    $ sg_write_same --16 --unmap --num=65535 --lba=1287948284 -vvv /dev/sdXXX

This will send the exact same CDB as found in the dmesg output. Armed with this, we can dig a bit more, and try changing the parameters.
After all, we would not expect UNMAP to be completely broken.
As we only pass `--lba` and `--num`, in my tests I've tried changing `--lba` first, but could not find a difference there.
But `--num` is interesting: once your request is smaller than **32K**, the command suddenly works!

Lets try sending a plain UNMAP command then:

    $ sg_unmap --unmap --num=65535  --lba=1287948284 /dev/sdXXX

Works! So it appears the 3PAR OS has incorrect length checking in the WRITE SAME code path.

Now how does Linux know what number of blocks are acceptable? The storage tells it. Specifically, in the "Block limits VPD page".
With another tool from `sg3-utils`, you can read that page:

```
$ sg_vpd /dev/sdXXX -p bl
Block limits VPD page (SBC):
  Optimal transfer length granularity: 32 blocks
  Maximum transfer length: 32768 blocks
  Optimal transfer length: 32768 blocks
  Maximum prefetch, xdread, xdwrite transfer length: 0 blocks
  Maximum unmap LBA count: 65536
  Maximum unmap block descriptor count: 10
  Optimal unmap granularity: 32
  Unmap granularity alignment valid: 1
  Unmap granularity alignment: 0
```

Clearly, "Maximum unmap LBA count" is set to 64K, and the kernel uses that, even if the UNMAP is happening through a WRITE SAME command.

PS: Try `sg_vpd /dev/sdXXX -p hp3par`.


On multipath
============

As a bonus, if you are running multipath (as you should do), you will see that SCSI error in dmesg only once.

So for testing issues like that, always test on the underlying /dev/sdXXX devices, to make sure multipathd and dm-multipath do not lie to you :-)


Automating the workaround
=========================

If you can not upgrade your storage, but want to run newer kernels, you can automate the workaround with a simple udev rule:

```
# /etc/udev/rules.d/20-3par-unmap.rules
# Alter provisioning_mode to "unmap", instead of the auto-detected
# "writesame16", which does not work with 3PAR OS <= 3.2.2MU3.
# See https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1585668
# See https://patchwork.kernel.org/patch/8950011/
# See https://h20272.www2.hpe.com/SPOCK/Content/ConfigurationSetDetailView.aspx?Id=82343
# "File System Space Reclaim - feature in 14.04.3 is supported but requires 3.2.2.MU3.
#  Space Reclaim on 14.04/14.04.1/14.04.2 LTS which uses the unmap provisioning is supported
#  across all versions of 3PAR OS"
# See linux commit 7985090aa0201fa7760583f9f8e6ba41a8d4c392 (3.19+)
ACTION=="add", SUBSYSTEM=="scsi_disk", SUBSYSTEMS=="scsi", ATTRS{model}=="VV", ATTRS{rev}=="3210",
               ATTR{provisioning_mode}="unmap"
```

Note that this rule is limited to `ATTRS{rev}=="3210"`, so it only works with 3PAR OS 3.2.1.
