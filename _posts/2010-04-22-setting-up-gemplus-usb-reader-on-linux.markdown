--- 
layout: post
title: Setting up GemPlus USB reader on Linux
mt_id: 75
---
For reference.

SmartCard reader is a gemalto PC USB-SL Reader, P/N HWP108841C.


Install these packages:

- sys-apps/pcsc-lite (+usb +hal)
- app-crypt/ccid

It might be benefical to install sys-apps/pcsc-tools too.

After this, start pcscd. You don't need to put anything into /etc/reader.conf, pcscd should pick up the USB reader, and load the ccid driver.

If you happen to use MOCCA, the Austrian "Buergerkarte" software, it should now find the card reader. Might need to restart it though.
 
