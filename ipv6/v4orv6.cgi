#!/usr/bin/perl

if ($ENV{REMOTE_ADDR} =~ /200([1-9a-fA-F]+):.*/) {
  print "Location: /ipv6/ipv6.png\n\n";
} else {
  print "Location: /ipv6/ipv4.png\n\n";
}
