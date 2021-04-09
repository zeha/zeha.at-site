---
layout: post
title: "My notes on upgrading to Debian bullseye"
---

[Debian 11](https://www.debian.org/releases/bullseye/) "bullseye" should be getting released soon. While I am already running a few VMs on bullseye/sid, only today I tried upgrading from Debian 10 "buster". *Here are my notes.*

Many things mentioned here are also noted in the official [Release Notes](https://www.debian.org/releases/bullseye/amd64/release-notes/index.en.html).

## Assumptions

My VMs tend to follow a slimmed down variant of the setup scheme dubbed "Wiener Melange". More on this scheme in future articles. The most important points:

- Most config is either managed by Puppet, or just left at the OS defaults
- Networking is either [systemd-networkd](https://wiki.debian.org/SystemdNetworkd) or ifupdown
- Init is systemd
- Firewall is [ferm](https://github.com/MaxKellermann/ferm/) + fail2ban
- Updates are installed by unattended-upgrades
- Depending on the VM, lots of third-party repositories are present (at least: [Puppet](http://apt.puppet.com/))
- etckeeper is installed

Notably absent here are setups with many block devices; I will try upgrading such systems at a later date.

## Pre-Update cleanup

For numerous reasons my VMs tend to be long-lived, and are not always "100% pristine".
The release notes also suggest cleaning up before attempting an update, for good reasons.

Packages I found lingering around from previous Debian versions:
* `gcc-6-base`
* `openjdk-8-jre-headless`
* `perl-modules-5.24`

These have now been added to my `buster` cleanup code in Puppet.
If you do the same, be aware that some third-party software still needs `openjdk-8-jre-headless` (example: UniFi controller).

The release notes also call for cleaning up old config files, and gives this command line:
```
find /etc -name '*.dpkg-*' -o -name '*.ucf-*' -o -name '*.merge-error'
```

After looking at the output, I reran this with `-delete`.

<blockquote>
If it's not in Puppet, it does not exist.<br>
<i>*cough*</i>
</blockquote>

## Update preparation

Disable Puppet:
```
puppet agent --disable 'chofstaedtler: OS update'
```

Commit any /etc changes to etckeeper:
```
etckeeper commit -m "pre-bullseye"
```

Update sources:
```
sed -e 's/buster/bullseye/' -i /etc/apt/sources.list.d/debian*
sed -e 's!bullseye/updates!bullseye-security!' -i /etc/apt/sources.list.d/debian*
```

*Note 1:* bullseye renamed the "security" repository, so you need two sed calls.

*Note 2:* You might need `/etc/apt/sources.list` too, but with Puppet's ["apt" module](https://forge.puppet.com/modules/puppetlabs/apt), I do not.

## The Upgrade

As advised by the release notes, I have run the upgrade in a `script` session. Actually, nested in a `tmux` session, in case my ssh connection dies:

```
tmux
script -t 2>~/upgrade-bullseye1.time -a ~/upgrade-bullseye1.script
apt update
```

Out of habit, I upgrade "apt" and "dpkg" first:
```
apt install apt dpkg
```

And then, the full upgrade:
```
apt full-upgrade
```

Once this finished, note that your zsh completion is broken (until restarting zsh). Continue on with one last command before exiting `script`:

```
apt autoremove --purge
```
*This removes most automatically installed packages which are no longer depended upon. Also deleted the config files.* 

After this, `reboot`. But see below for some gotchas, first.

## Enable `usrmerge`

Once all your services work again, and other dust has settled, I would recommend moving to a "usr-merged" system.
This can be achieved by installing the `usrmerge` package, and choosing `Yes` at the following prompt.

As this involves moving around lots of files without involving `dpkg`, I would recommend a VM snapshot before doing so.

You might ask: "why?" - very good question.
Theoretically, it should not matter.
Practically speaking, not all bugs caused by path mixups that only happen on non-merged systems will have been caught during the bullseye development cycle. Some of these bugs manifest themselves quietly - some functionality might be broken without any messages. Spare yourself the debugging exercise.

## Notable changes

1. `bsdmainutils` goes away. Some of the tools got moved to `bsdextrautils`. If you want the full `calendar` utility, you have to install the `calendar` package.
1. `python2.7` and `python3.7` go away; you will get `python3.9`.
1. There is a new `e2scrub` cron job (and timer unit); default disabled. Did not investigate this yet.
1. Obviously, lots of new transitional packages that can be removed: `e2fslibs libcomerr2 libgcc1 gcc-8-base libpython2.7-minimal libpython2.7-stdlib libncurses5 netcat-traditional`
1. New `/etc/ethertypes` and `/etc/netconfig` files appear
1. `iptables` is now split into the nft-using `iptables` and `iptables-legacy`. `ferm` uses the latter.

## Gotchas

### `service` no longer ignores dependencies during boot

This [commit in init-system-helpers](https://salsa.debian.org/debian/init-system-helpers/-/commit/3988cf70533b9a826727a26ce6dce91755a0fb22) removes `--job-mode=ignore-dependencies` while the system is not fully booted yet.
The option was always a crude hack, and if you did rely on it you have to change your stuff now.

My ferm setup uses hooks to trigger fail2ban, specifically like this (in `/etc/ferm/ferm.conf`):

```
@hook post "/usr/sbin/service fail2ban restart";
@hook flush "/usr/sbin/service fail2ban restart";
```

Result: the `ferm` startup job will hang forever during boot.

I have fixed this by changing to:

```
@hook post "/usr/bin/fail2ban-client reload --restart || true";
@hook flush "/usr/bin/fail2ban-client reload --restart";
```

The `|| true` is necessary during boot, as I did not want to add explicit ordering requirements between ferm and fail2ban.

### iptables-legacy

`iptables -nL` is very empty. At least `ferm` still uses `iptables-legacy`, so you have to use `iptables-legacy -nL` to look at the active rules.

Speaking of ferm: the author [has stated](https://github.com/MaxKellermann/ferm/issues/35) one should consider switching to `nftables`. I have to investigate this.

### Third party repositories

Various third party repositories do not carry a `bullseye` distribution yet.

Notably:
* [Puppet](https://tickets.puppetlabs.com/browse/PA-3624)
* [HPE SDR MCP](http://downloads.linux.hpe.com/SDR/repo/mcp/) - but for Gen9 hardware, there is no `buster` repository either. I would not hold my breath, and continue to use the `stretch` packages.

### Puppet Unattended-Upgrades

The [unattended-upgrades module](https://github.com/voxpupuli/puppet-unattended_upgrades) for Puppet does not know about the new "security" suite name yet. [Ticket](https://github.com/voxpupuli/puppet-unattended_upgrades/issues/187)

### ifupdown

I would recommend migrating away from `ifupdown` as soon as possible.
On simple setups you will not see any problems, but not all setups are simple.

Most notably, ifupdown's `networking.service` injects a `udevadm settle` service into the boot chain, and waits for that to complete before configuring network interfaces.
If you have lots of (say, block) devices, that `udevadm settle` command might very well fail (timeout), and you will not have a running network setup.

---
*(Thanks to Michael Biebl for pointing me at the init-system-helpers change.)*
