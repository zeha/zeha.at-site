--- 
layout: post
title: Lessons learned with Supermicro's remote management/IPMI view
mt_id: 78
---
Supermicro's recent IPMI/KVM ("remote server management with graphical console") violates all good design principles and what you would expect from such a solution.

Basically, it works like this: there is some management controller on the mainboard, with it's own dedicated network port. It's got an HTTP interface for use & configuration. For use it offers basic power control (off, on, reset), a serial-over-lan transport, and a graphical console which can also provide disk services to the host (CD/ISO, USB Key, floppy).

For the basic feature set, this sounds like what you want to use.

Unfortunately Supermicro's implementation adds a great deal of obstacles which make using it nearly impossible. Here's why:

 - The HTML UI makes extensive use of JavaScript and AJAX, and fails to provide progress and error messages when something goes wrong.
 - The client part of the graphical console appears to be implemented in Java _and_ native code. The native code parts are only available for the platforms Supermicro has chosen to support (i386/amd64 of Windows and "Linux").
 - Different servers appear to require different management controller firmware versions. While the interface looks quite the same, it seems to do completely different things under the hood. ("This one works on a Mac, the other's dont?")

None of this does any good.

Details:

 - The graphical console requires you to use Sun Java 6u17. Using a newer Java version plainly doesn't work, and you get either no window and no error message or "Authentication failed".
 - The underlying protocol seems to be VNC, but with a different authentication scheme, making standard VNC clients useless. (Also it appears to be an OEM version of ATENs KVM/VNC stuff.)


A friend pointed me to the so called "IPMIView" tool, which basically is a standalone version of the graphical console and some other bonus features. Compared to the Java applet stuff, it feels rather stable, but has the same platform limitations (i.e. Windows + "Linux" only). It appears to be available only from SM's FTP server: 
   [ftp://ftp.supermicro.com/utility/IPMIView/](ftp://ftp.supermicro.com/utility/IPMIView/)


Also, to compare this situation with HP: HP's "ILO 2" is _very_ slow, went through a few firmware versions to fix rather odd bugs, but: the basic features (== what you depend on during emergencies) work and worked all the time. Their graphical console also is Java, but with no native code, and therefore works fine on a Mac and IIRC it also worked fine on ppc Linux.


**Update 2013-06-09**: Anders Hellquist has mailed in (thanks!) and pointed out that [this blog post at mcgill.org.za](http://www.mcgill.org.za/stuff/archives/340) has useful info for running IPMIView on Linux, and that it works for him on Ubuntu (64-bits) with OpenJDK 6 and 7. Also, IPMIView apparently gets regular updates, which makes it way more preferable than the Applet stuff.

**Clarifications on Mac issues 2013-08-01**: Apparently there's some confusion on the Mac side of things, let me clarify:

  - You don't need a special "Mac" release of IPMIView. Download the "Jar" version.
  - If KVM will work for you depends on the firmware used on the server. SuperMicro uses, depending on the server model, AMI or ATEN KVM firmware, in various revisions:
    - Some(?) ATEN firmware will need binary components on the IPMIView side.
    - ATEN Binary components are only shipped for: Windows x86 and x64, Linux x86_32 and x86_64, 64-bit OS X.
  - This means:
    - ATEN KVM won't work on 32-bit OS X.
    - It won't work on arbitrary other platforms (even if a Java runtime exists).
    - AMI KVM should work. (Remote Media is another story.)
    - You won't really know if KVM works until you actually have the server.

If you got lucky and it works for you, good for you! As already said above, we had some machines (model 1) where KVM would work fine, and others (model 2) where it just wouldn't work on the Macs.

-----

Sidebar:

This has cost a client about 12 man hours. They're using Macs in the office, and those are now basically useless during emergency times. 
