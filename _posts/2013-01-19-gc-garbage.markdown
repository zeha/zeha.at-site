--- 
layout: post
title: "gc.garbage is your friend -- Object cycles in Python"
---

You probably never think of this when writing code, but Python relies on
a [garbage collector](http://docs.python.org/2/library/gc.html) to clean
up (most) objects. Rightly so. Most of the time, ignoring the GC is
the right thing to do - "it just works".

The "it just works" approach also extends to object cycles - where you
put obj1 into obj2 and obj2 into obj1. Now I've already linked to the `gc`
docs and the title gives it away as well: this breaks down if you have a
[__del__](http://docs.python.org/2/reference/datamodel.html#object.__del__)
method in one of the objects!
This is spelled out quite clearly in the `__del__` docs as well as in the
`gc` doc.

So, when you have such a situation, `gc.garbage` will become your new
friend. To use it, you don't need to do anything! Just look at it!

By default, gc.garbage will be the list of all objects the gc couldn't
clean up that also happen to have a `__del__` method. So this tells you
the object that prevented the standard gc behaviour (which is: just zap
everything).

Unfortunately, this is often not enough to debug the issue at hand. To
also see all the objects that weren't collected *without* a `__del__`
method - which usually are these that somehow hold your
object-with-`__del__`, do this in your wrapper code:

    gc.set_debug(gc.DEBUG_UNCOLLECTABLE|gc.DEBUG_COLLECTABLE)
    [your code]
    gc.collect()

    logger.debug('gc garbage: %r', gc.garbage)
    for o in gc.garbage:
        for r in gc.get_referrers(o):
            logger.debug('ref for %r: %r', o, r)

(I assume that you already have a wrapper. If you need this, you most
likely already use a wrapper for profiling or other one-time
initialization or shutdown code.)

Note that `gc.garbage` istself *also* holds references to the objects in
question, and therefore keeps them alive. Therefore, you'll see
`gc.garbage` *itself* as a reference to your objects in the debug
output. Ignore it. (It looks like a standard list.)

Now that you see every object that wasn't collected, you'll also see the
object that holds your special object with the `__del__` method.

Good luck unwinding your object cycle!
