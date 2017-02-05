---
layout: post
title: "Using DISM to install Storage Drivers"
---

If you migrate Windows installations between storage adapters, you're
often left with the well known STOP 0x7B ``INACCESSIBLE_BOOT_DEVICE``.
This happens because Windows doesn't yet have the required drivers installed,
and/or set as boot-critical.

The [dism.exe](http://technet.microsoft.com/en-us/library/hh824971.aspx) tool allows us to install (boot-critical) drivers into
an offline Windows "image". Note that an offline Windows "image" is nothing
special - a regular Windows install is a valid Windows "image".

After a STOP 0x7B, Windows Boot Manager usually sets up fallback boot
into [WinRE](http://technet.microsoft.com/en-us/library/cc766048.aspx) (Windows Recovery Environment). WinRE has a copy of the DISM
tool, so you're good to go.
(Cancel the Startup Recovery assistant if you have to.)

Example DISM commands to use from the WinRE (or WinPE) Command Prompt:

Install Microsoft/Generic Storage Drivers
-----------------------------------------

This includes MSAHCI, IntelIDE, AMDIDE, ATAPI, PCIIDE and so on:

    dism /image:d:\ /add-driver /driver:d:\windows\inf\mshdc.inf /forceunsigned

(D: is assumed to be the Windows SystemDrive partition.)

Install LSI MegaRAID / SAS/SATA Drivers
---------------------------------------

    dism /image:d:\ /add-driver /driver:d:\windows\inf\megaraid.inf /forceunsigned

(D: is assumed to be the Windows SystemDrive partition.)


Install VirtIO Storage Drivers
------------------------------

If you have the [VirtIO drivers](http://www.linux-kvm.org/page/WindowsGuestDrivers/Download_Drivers) ISO mounted, and added the drivers in the Recovery
GUI, dism can add them to the offline Windows as well:

    dism /image:c:\ /add-driver /driver:d:\win7\amd64\viostor.inf

(C: is assumed to be the Windows SystemDrive partition, and D: is the virtio ISO/CD.)


Update: fixed megaraid.inf filename. (Thanks, mika.)

