---
layout: post
title: "Take back control II"
---

Last time, in ["Take back control"](http://christian.hofstaedtler.name/blog/2012/11/take-back-control.html),
I talked about the basic concepts, on why we should take back control.

Today, I'll talk a bit about concrete steps -- concrete implementation of what works for me.

Instant messaging
-----------------

[XMPP](http://xmpp.org/) is an open standard, and one of the core concepts
is federation. -- Works exactly like e-mail. (XMPP/Jabber addresses also look
like e-mail addresses.)

I personally run [ejabberd](http://www.process-one.net/en/ejabberd/),
and use [pidgin](http://www.pidgin.im/) on client computers.
Obviously, don't forget to enable encryption! And [OTR](http://www.cypherpunks.ca/otr/).

On the phone: I don't use instant messaging on the phone. Just have people call
if it's important.


E-Mail
------

Very generic setup, and unchanged for years. Running [Exim](http://www.exim.org/) +
[Dovecot](http://www.dovecot.org/) for SMTP + IMAP. Again, don't forget SSL.

For clients: [mutt](http://www.mutt.org/). On the phone: Apple MobileMail.


Calendar & Contacts
-------------------

This was the hardest thing to move off the cloud. Whilst I was evaluating
various so called "Groupware" "solutions", none of them particularly appealed to me.
(Most of these are fine packages, but they look like overkill for a single user, plus
I wasn't comfortable with putting any of them onto the Internet.)

At some point I just realized, I don't need "always on" availability of these
services. My phone always has a full copy of the data, and can sync changes
back whenever the server is reachable. This realization made me choose
the OS X Server Calendar and Contacts features, on the Mac mini "server"
I already had at home.

While this choice works good enough for me, it's certainly not for everybody.


Dropbox
-------

The sad part of the story -- there's no real replacement yet.

I've begun work on a partial replacement, more as a feasability study.
No sharing/teams yet, no nice web thing yet, and so on.

I *present*: [Oncotrunk](https://github.com/zeha/oncotrunk)

What really needs to be done is proper syncing -- right now Oncotrunk relies on
[Unison](http://www.cis.upenn.edu/~bcpierce/unison/) to actually do the file
synchronization. While Unison is certainly a great standalone tool, it's really
not meant to be driven by other programs, and my glue code isn't any good
either.

I'm using Oncotrunk on multiple computers today.

-----

That's all for now.

Good luck, and *take back control*!

The U.S. cloud party was fun while it lasted, but it's really over now.
