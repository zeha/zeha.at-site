--- 
layout: post
title: fail2ban is insecure by design
mt_id: 83
---
To quote the [fail2ban](http://www.fail2ban.org) web site:
> Fail2ban scans log files like /var/log/pwdfail or /var/log/apache/error_log and bans IP that makes too many password failures. It updates firewall rules to reject the IP address.

Well, it also scans /var/log/auth.log which is a file written by syslog. Combined with [my previous blog entry](http://zeha.at/blog/2010/10/on-the-non-security-of-system-logs.html), you can already see where this is going.

fail2ban uses a simple regex based scheme for parsing the login failure logs, for example for the sshd service (one of many):

    ^%(__prefix_line)sFailed (?:password|publickey) for .* from <HOST>(?: port \d*)?(?: ssh\d*)?$

  
<br/>


You can easily turn around fail2ban to work for you, an unprivileged user (do this 5 times or so):

    logger -p auth.info -i -t sshd "Failed password for root from 10.3.3.3 port 3333 ssh2"


If fail2ban runs in it's default configuration you have now inhibited all traffic from 10.3.3.3. 

Congratulations.
 
