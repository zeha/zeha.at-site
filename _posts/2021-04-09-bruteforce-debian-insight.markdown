---
layout: post
title: "Brute-Force Insight into your Debian packages for the next release"
---

*Debian has recently, somewhat quietly, switched to a different model for releasing.*
*Insight into this process is lacking for Debian package maintainers.*

Important note: all of the following is written from an observing position. I am not part of the release team, and have not discussed this text ahead of time with them. Errors are, obviously, my own. 

In the past, many suggestions on improving the Debian release process have been discussed publicly.
Often the goals could be summarized as "release more often" and "the freeze should be shorter".
Variants of these goals were the "rolling release" proposal and others.
Orthogonal ideas were floated, and sometimes "x-and-a-half" releases were made.

For the currently in-progress release, it would appear the (partially changed) release team has indeed changed how the release process works.
I believe the new process will indeed lead to the goals given above.
However - I think - this is mostly achieved by reaching another goal, which was not quite clearly stated before:
"Reduce load (and thus work) on the Release Team".

Like (all) other Debian teams, the Release team is a volunteer-staffed team.
Nevertheless they stand in the spotlight and carry lots of responsibility.
At the same time they probably are understaffed (again, like all other Debian teams).

Reducing the work to be done by teams is what Debian generally needs to do.
I strongly believe this is the only way forward, and as such I welcome these changes.

How is this achieved for the release team?

## Automated tests

Debian has gained a [Debian CI](https://ci.debian.net/) service.
All packages declaring (autopkg)tests will be tested in their respective suite.

They *also* get tested again when something else in their dependency tree changes, and before the migration of that change.

That's actually really nice as a concept, as that makes it possible to find changes in your package breaking other packages, or changes in other packages breaking your package.
Without manual testing and bug reports appearing years later.

Downside of this: as a package maintainer, Debian CI is quite the box that you cannot introspect:

* You cannot really tell when your package will be tested again, or if your request for a re-test was actually recorded.
* You cannot look at old logs, if your package was not retested for a while (logs are expired after NN days).
* You cannot tell if your package tests failed for non-package reasons: test worker VM broken, overloaded, partial breakdown of the isolation between packages being tested, etc.
* It is hard to reproduce the exact environment that Debian CI runs your package tests in. The LXC setup seems to have some requirements not easily met in a KVM VM. On non-x86, you would have to find hardware you can run LXC on - certainly not the porterboxes.
* You do not get notifications for failed tests.

Nevertheless failing tests are directly your problem as a package maintainer.

## Automated removals

Packages being too buggy to be considered for the release ("release-critical bug") are marked for automatic removal after some time.

I believe this automates lots of the work and decision making that was previously down by the release team.
As a self-service aspect, package maintainers can "ping" their release-critical bugs with status updates, effectively gaining more time to fix those bugs.

However, the interface available to maintainers is basically [this list](https://udd.debian.org/cgi-bin/autoremovals.cgi).
IIRC, maintainers actually get a warning mail once for their package.

For packages that you care about but are not the maintainer, there seems to be no good way of staying informed.

## Key packages

The autoremoval process, as well as the release rules (see below), treat ["key packages"](https://udd.debian.org/cgi-bin/key_packages.yaml.cgi) differently.

Which might be good. Or not. Lets say I am neutral to this.

As a package maintainer you are supposed to know if your package is a key package.

But how do you get to know this? By checking the list! Which can change each day.

## Follow the rules

The release team sets [rules and timelines](https://release.debian.org/bullseye/freeze_policy.html) for the release.
These rules are to be known and obeyed by the package maintainers.

And thats a good thing!

If... we actually knew all of the rules and dates in advance.
And if package maintainers would understand them.

Judging by the questions appearing on the mailing lists, IRC and also my own confusion about these rules, I can only conclude that they are not clear enough. Maybe they are just not communicated clearly enough.

## UDD: Getting some insight

The title of this post promised some "brute force insight" for maintainers, not just a listing of problems... so:

The [Ultimate Debian Database](https://wiki.debian.org/UltimateDebianDatabase) ("UDD") has copies/imports of most of the relevant data used for the release process. On a per-package level, this is exposed on the distro tracker ([example](https://tracker.debian.org/pkg/bsdiff)).

On a per-maintainer level, you can get a lot of info from UDDs "Maintainer Dashboard" ([example](https://udd.debian.org/dmd/?email1=zeha%40debian.org)). Quite overwhelming though.

## UDD SQL: the brute-force way of insight

Personally, I often only need to answer these question for my packages (and other packages I am interested in):
* Will the new version I have uploaded migrate?
* Will the package be in the upcoming release?

As a start, I have hacked together the following script - it can go into your @daily crontab.
If your cron is configured correctly, you will get a summary mail once per day. Most of the time you should -not- get email, as hopefully there is nothing to do for you!

Note that checking the status more than once a day is mostly pointless. Most automated Debian things run on a rather large interval, and UDD sometimes lags behind with the data imports.

```
#!/bin/sh
DEBEMAIL="you@example.org"
exec psql "postgresql://udd-mirror:udd-mirror@udd-mirror.debian.net/udd" -XbAt <<EOT
WITH pkgs AS (
  SELECT source FROM sources
  WHERE (maintainer_email = '${DEBEMAIL}' OR uploaders ILIKE '%${DEBEMAIL}%')
  AND release = 'sid'
  GROUP BY 1),
latest_ci AS (
  SELECT ci.*
  FROM ci JOIN (
    SELECT ci.suite, ci.arch, ci.source, max(ci.run_id) AS max_run_id FROM ci
    JOIN pkgs ON pkgs.source = ci.source
    WHERE ci.suite = 'testing'
    GROUP BY 1,2,3
  ) lci ON ci.run_id = lci.max_run_id)

SELECT
  ':: ' || pkgs.source || ' summary: ' || exc.new_version || 
  ' testing: ' || mig.testing_version || 
  ' unstable: ' || mig.unstable_version || ' ' || 
  exc.migration_policy_verdict || ' by ' || (coalesce(array_to_string(exc.reason, ' '), '(age)')) || E'\n  ' ||
  array_to_string(exc.excuses, E'\n  ')
FROM pkgs
LEFT JOIN migration_excuses exc ON exc.source = pkgs.source
LEFT JOIN migrations mig ON mig.source = pkgs.source
WHERE mig.in_unstable IS NOT NULL
AND (mig.testing_version <> mig.unstable_version OR exc.source IS NOT NULL)

UNION ALL

SELECT
  ':: ' || pkgs.source || ' autoremoval: ' || to_timestamp(removal_time)::date::text
FROM pkgs
JOIN testing_autoremovals ON testing_autoremovals.source = pkgs.source

UNION ALL

SELECT
  ':: ' || bugs.source || ' bugs: ' || string_agg('#' || bugs.id::text, ' ')
FROM bugs
JOIN pkgs ON pkgs.source = bugs.source
LEFT JOIN bugs_tags bt_ignore ON bt_ignore.id = bugs.id AND bt_ignore.tag = (SELECT release FROM releases WHERE role = 'testing')||'-ignore'
WHERE bugs.affects_testing
AND bugs.severity >= 'serious'
GROUP BY bugs.source

UNION ALL

SELECT
  ':: ' || source || ' ci: ' || string_agg(arch || ':' || message, ';')
FROM latest_ci
WHERE status = 'fail'
GROUP BY source

ORDER BY 1
;
EOT
```

UDD also has parsed "hints" data. Improvements welcome!

PS: I like SQL. :-)
