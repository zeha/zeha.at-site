--- 
layout: post
title: "Short how-to: use schroot with aufs"
---

If you need to use schroot instead of cowbuilder, you're probably using it with LVM snapshots. This gives you the advantage that changes to the chroot are thrown away when your session ends.

In my setup, schroot is used to auto-build Debian packages, with a special wrapper, etc. And boy, the setup was dog slow.

["LVM2 snapshot performance problems"](http://www.nikhef.nl/~dennisvd/lvmcrap.html) from 2009 explains the slowness.

Switching to aufs made my builds complete in 25% of their normal time.

## Here's what you need to do:

1. Run Debian squeeze stock kernels. They come with a working aufs module. Maybe do a modprobe aufs.
2. Migrate back to a type=directory chroot. It's the only base type schroot supports with aufs. (This might be as simple as a mount and changing schroot.conf.)
3. Set union-type=aufs in schroot.conf.
4. Enjoy the speed!

