---
layout: post
title: "Puppet Pattern: the site_location fact"
---

Often you will need location-specific settings on your servers.
Especially when you subscribe to the "almost everything should be managed" school - likely your
`/etc/resolv.conf` will depend on where a server (or VM) is.

My recommendation: have a fact called `site_location` and use that in your [hiera hierarchy](https://docs.puppet.com/hiera/3.2/hierarchy.html).

Example for your `hiera.yaml`:

```yaml
---
:hierarchy:
  - defaults
  - "nodes/%{trusted.certname}"
  - "environment/%{server_facts.environment}"
  - "location/%{::site_location}"
  - global
```

An example location yaml, in my case `location/nlay-fle.yaml`:

```yaml
---
nullmailer::smarthost: 10.40.0.10
dnsclient::nameservers:
  - 10.40.0.10
  - 10.40.0.11
```

If you have nicely short site names, I would use those as the `site_location`.
In a well-mannered environment, you would have that name as part of the machines `fqdn`.
Or, for VMs, you can probably retrieve that using your hypervisor API from the VM host.

Or, if you are a bit more **ghetto**:

For VMs: have the VM host write the location name into a file inside the VM. (Previously,
I have used `/etc/facter/facts.d` for that.)

For physical machines, derive the location off the configured IP addresses. Like this:

```ruby
# modules/site/lib/facter/site_location.rb
require 'puppet'
Facter.add("site_location") do
  lookup_table = {
    '10.40.' => 'nlay-fle',
    '10.41.' => 'site-b',
    '10.42.' => 'site-c',
    '10.43.' => 'site-d',
    '10.44.' => 'site-e',
  }
  setcode do
    if Facter::Util::Resolution.which('ip')
      ips = Facter::Util::Resolution.exec('ip addr ls | awk \'/inet / {print $2}\'').split
      lookup_table.select { |prefix, location| ips.any? { |ip| ip.start_with?(prefix) } }.values.first
    end
  end
end
```
