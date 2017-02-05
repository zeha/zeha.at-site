--- 
layout: post
title: On the non-security of system logs
mt_id: 82
---
Let me make a claim:
  Current system level logging systems are insecure.

On what level you ask? Authentication of log entries.

Most system logging services have some way of restricting who can view log entries. But practically none have a way of restricting who can *write* log entries, and therefore they also do not have any authentication that a log entry written by program X is really from program X - not from someone just claiming to be program X.

This is especially true if the logging service can forward log entries to another machine (rather: if it can receive log entries from another machine).


**What this means for the system administrator:**

You can not trust your syslogs for that something in there really happened. They are generally a good indication of what's going on, but it's trivial for anyone to fake log entries.
This holds true for classic Un*x syslog as well as the Windows NT Event Log, and especially for the Audit logs in those systems.

If all of this is obvious for you, ask yourself: when was the last time you questioned if a particular syslog entry was real or fake?
 
