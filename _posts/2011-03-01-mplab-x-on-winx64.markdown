---
layout: post
title: "Running MPLAB X on Windows x64"
---

**Update**: With MPLAB X 1.30 this no longer appears to be necessary.


If you have Windows (7) x64 installed, it's likely that you have a 32-bit and a 64-bit JVM installed. By default MPLAB X (or rather, the Netbeans Launcher) will pick up the 64-bit JVM. Unfortunately the Microchip Netbeans plugins can't find hardware connected to the USB bus if they run on the 64-bit JVM.

To remedy this, switch to the 32-bit JVM. To do so, update your MPLAB X shortcut file.

The original command line:
    "C:\Program Files (x86)\Microchip\MPLAB X IDE\mplab_ide\bin\LaunchMPLAB_IDE.exe"

The new command line:
    "C:\Program Files (x86)\Microchip\MPLAB X IDE\mplab_ide\bin\LaunchMPLAB_IDE.exe" --jdkhome """C:\Program Files (x86)\Java\jre6"""

Due to brain damage in LaunchMPLAB_IDE.exe you have to use triple quotes around the Java home path.

