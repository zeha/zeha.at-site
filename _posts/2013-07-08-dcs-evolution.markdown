---
layout: post
title: "Configuring Evolution for CalDAV and CardDAV with Darwin Calendar Server"
---

The correct settings to feed Evolution are:

Calendar:
---------

Create a new CalDAV calendar with this URL:

    https://servername.fqdn:8443/calendars/users/username/calendar/


Set "Username" in the GUI to your login username.
(Replace "servername", "fqdn" and "username" in the URL, obviously.) 

Example URL that works for me (my login username being "ch"):

    https://server.local:8443/calendars/users/ch/calendar/

Address Book:
-------------

Create a new WebDAV address book with this URL:

    https://servername.fqdn:8443/addressbooks/users/username/addressbook/

Set "Username" in the GUI to your login username as well.
(Replace "servername", "fqdn" and "username" in the URL, obviously.) 
