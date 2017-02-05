--- 
layout: post
title: Linux on the Intel DP55KG board
mt_id: 69
---
Now owning an Intel DP55KG board (<http://www.intel.com/products/desktop/motherboards/DP55KG/DP55KG-overview.htm>), I naturally tried running Linux on it. Unfortunately this was not one of those "works out of the box" experiences.

The current issues are (all tested with 2.6.31.4):

* Linux does not reboot properly (Windows does). You need to say <tt>reboot=a</tt> on the kernel cmdline.
* Ethernet link speed gets set to 10MBit/s. <http://e1000.sf.net/> has e1000e-1.2.2 drivers which resolve this.
* There will be a HPET WARNing in dmesg. It should be harmless (<http://thread.gmane.org/gmane.linux.kernel/913374/focus=915233>).

Other stuff to know:

* The extra Marvell controller exposes an AHCI interface, so just use the AHCI SATA driver for it. Hot-plugging eSATA drives works fine.
* There are apparently issues with Noctua fans, but I haven't verified that yet. 
