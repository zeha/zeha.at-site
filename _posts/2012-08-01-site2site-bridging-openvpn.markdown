--- 
layout: post
title: "Site-to-Site Ethernet Bridging with OpenVPN"
---

Tested on Debian squeeze.

I trust you can setup OpenVPN keys and that stuff.

You must already have bridge-utils and iproute installed.

Here are the changes to a standard OpenVPN configuration
to get site-to-site bridging to work:


Server
------

One side must be the server. One or more clients can connect to it.


/etc/network/interfaces:

    auto br1
    iface br1 inet static
      address 10.10.99.1
      netmask 255.255.255.0
      bridge_ports  none # or eth0 if you bridge to a phys nic
      bridge_stp    off  # for virtual-only bridges
      bridge_fd     0    # same
      bridge_maxage 12   # ...
      # allow (local) multicast traffic to pass through
      post-up route add -net 224.0.0.0 netmask 240.0.0.0 dev br1

/etc/openvpn/openvpn.conf: (excerpt)

    # so the scripts always get the same tap device
    dev tap0
    # can do without this
    ifconfig-pool-persist ipp.txt
    # for more than one client
    client-to-client
    #             local ip                 'dhcp'-start 'dhcp'-end
    server-bridge 10.10.99.1 255.255.255.0 10.10.99.100 10.10.99.150
    script-security 2
    up "/etc/openvpn/up.sh"

/etc/openvpn/up.sh: (mode 0750)

    #!/bin/sh
    echo bringing up tap0
    /sbin/ifconfig tap0 up promisc
    /usr/sbin/brctl addif br1 tap0


Bring up the bridge before starting openvpn.



Clients
-------

You can have many of these.


/etc/network/interfaces:

    auto br1
    iface br1 inet manual
      bridge_ports  none # or eth0 if you bridge to a phys nic
      bridge_stp    off  # for virtual-only bridges
      bridge_fd     0    # same
      bridge_maxage 12   # ...

/etc/openvpn/openvpn.conf: (excerpt)

    # so the scripts always get the same tap device
    dev tap0
    script-security 2
    ifconfig-noexec
    up "/etc/openvpn/up.sh"
    route-up "/etc/openvpn/route-up.sh"

/etc/openvpn/up.sh: (mode 0750)

    #!/bin/sh
    echo bringing up tap0
    /sbin/ifconfig tap0 up promisc
    /usr/sbin/brctl addif br1 tap0

/etc/openvpn/route-up.sh: (mode 0750)

    #!/bin/sh
    echo removing old ips
    while ip -f inet addr del dev br1; do echo .; done
    echo adding ip address
    ip a add ${ifconfig_local}/24 dev br1
    route add -net 224.0.0.0 netmask 240.0.0.0 dev br1


Depending on your specific configuration you might want to add a down script to clear out the received IP address on OpenVPN shutdown.

