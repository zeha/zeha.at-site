--- 
layout: post
title: 'Grml aftermath'
---

You probably saw it already, there's a new [Grml release: 2011.12](http://grml.org/changelogs/README-grml-2011.12/).
We made it to
[Heise on December 24th](http://www.heise.de/open/meldung/Rettungs-Linux-Grml-2011-12-Knecht-Rootrecht-freigegeben-1401261.html).

I've spent countless nights, weekends, free hours during the last months to actually make it happen.
I met with mika for several days twice.
This all is time where I could've slept, could've been with my girlfriend, could've worked on commercial projects, could've sold time, and so on.

During this time I worked on almost everything: lobbying for a smaller software selection,
[grml-live](https://github.com/grml/grml-live) improvements,
cleaning up various parts of the website,
fixing BitTorrent downloads,
automating most of the release process.
I touched all our packages,
overhauled [packages.grml.org](http://packages.grml.org/) so it's a tool we can use for the release process.

For sure, I haven't worked alone on this - the work I've done is only part of what was needed to release,
but without it, there almost certainly would be no release.

Obviously, not everything is great: where work is done, bugs are introduced, things are overlooked,
in a rush not everything is communicated the best way it could have been.
And in a rush we were.

Turn back the time, to mid-2011:
--------------------------------

Oh right, the 2011.05 release just happened!
RC1 happened while the real release manager was getting married.
It was a tough call to get people moving, so RC1 could happen, and then the same for the release again.

In the end, we had a frustrated release manager (who was already burned out to start with),
and a new, now-frustrated stealth release manager.
After the release, development on Grml almost came to a full stop.

Some time later, when it became clear that the promised next release date (December) would be "soon",
it still looked grim: almost no work had been done on Grml itself.

In the meantime, the Grml System Administrators did a great job moving the server off from private
infrastructure to a sponsored machine (thank you, Hostway!), and I certainly want to thank them for that.

Nevertheless, we looked into a void. I drew my own conclusions, and offered to step up as a second release manager,
with one condition (actually, goal): work for a release must go down.

For this to become true, a few tasks were identified:

  * set a clear focus on what Grml should be,
  * cut out all things not belonging to the new focus,
  * automate the release process as far as possible.

Sure, it's hard to swallow and most people can just ignore the alternative: no release at all.

"How did it turn out in reality?", you ask?
-------------------------------------------

Certainly a few packages too much were being cut.

Certainly some use cases got broken by this (especially the desktop usecase).

Certainly some users are now pissed off that their favorite distribution is no longer a swiss army knife that can do everything, but
nothing really well.

But, like, really?
------------------

While a few people think it's a good idea to piss into the wind or in my face instead of contributing,
overall 2011.12 is a very great release, even if it's got a few more bugs than usual.

Here's why:

  * The project got a lot of feedback from users. Compare this to the previous release, where everybody was saying: "Oh, a new release *yawn*". (No, not overwhelmingly negative feedback.)
  * Our disabled userbase woke up when we almost cut brltty and friends. This time, we actually had somebody **test** (Hi, John!) that stuff works (and discovered that it was broken in 2011.05.)
  * The development/release process is way more open and visible.
  * At least one of the old developers has (more or less) found motivation to work on Grml.
  * We got new people interested in Grml, possibly developing stuff in Grml.
  * A few tons of old cruft have been cleaned up.
  * The release process is *less* work now.
  
*There are even fantasies of releasing more often in the future.*

*For me it's a great release. I think this also holds true for the project.*


**tl;dr: 2011.12 is a great release, even if some people think otherwise**
