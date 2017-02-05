---
layout: post
title: "Porting to Python 3"
---

[Quick Tips on Making Your Code Python 3 Ready](http://stackful.io/blog/quick-tips-on-making-your-code-python-3-ready/) is a great blog post you should read before porting your code to Python 3.

I've recently ported [pbundler](https://github.com/zeha/pbundler) using a subset of these methods, and as a result pbundler now runs fine on Python 2.6, 2.7, 3.2 and 3.3.

Even more important is the fact that the Python 3 "port" is not a port as such, **and** *2to3* is not involved. Both "platforms" run from the same code base, and there's no translation step - making both, Python 2 and 3 primary, equal targets.

Consider doing the same, and getting rid of 2to3 in your build/install steps.

