---
layout: post
title: "Expired Root CA Verification failures"
---

Today, the [AddTrust External CA Root](https://crt.sh/?id=1) certificate expired.
This certificate was used to cross-sign the current Sectigo root certificate, which has quite some marketshare.

If you're using certificates from Gandi, chances are they chain back to that certificate.
Now, the Sectigo root certificate should be in most trust stores, and there should be no story to write.

However, quite a few things broke today.
All of these breakages are caused by a combination of server misconfiguration, and bugs in SSL client libraries.

## Server-side misconfiguration

SSL (really, TLS) servers send their certificate to a client, so the client can then verify that the server it is connecting to is really who the client thinks it is.
This is why we have certificates in the first place.

Most of the time, server certificates are issued by some intermediate certificate authority (CA), and not by the root CA.
The root CA is trusted by the client, this is achieved by putting the root CA into the clients "trust store".
Usually this trust store is configured by the SSL client (library) vendor - so, your browser or operating system vendor.

The intermediate CA is however not in that trust store. The server has to send the intermediate CA to the client when it connects.
Still good.

Now, the Sectigo Root CA was *new* at some long time ago in the past - you know, in year 2000.
As a transitional measure, it was cross-signed by the AddTrust root, effectively becoming an intermediate CA!

But this time is long gone, and with the AddTrust root expiring today, these servers now send a broken certificate chain.

## SSL client library bugs

The server-side misconfiguration should be harmless in itself.
But SSL client libraries... also have bugs!

In theory, client libraries should look into their trust stores and try to build all valid chains - using any certificate the server sent, and whatever they have in their trust store.
In the trust store, the library should find the current Sectigo Root CA certificate, marked as trusted.

The expired cross-signed certificate should just be ignored. Everything should be great.

And: many client libraries get this correct. Some, do not. And then stuff that should just work, breaks.

## Known breakage

Here's a list of client libraries and software combinations that are known to break:

### Apple's curl and Apple's LibreSSL

Version: `Apple's curl 7.64.1 (x86_64-apple-darwin19.0) libcurl/7.64.1 (SecureTransport) LibreSSL/2.8.3 zlib/1.2.11 nghttp2/1.39.2`

Note that this says *both* `SecureTransport` AND `LibreSSL` at the same time.

```
$ curl https://apt.puppet.com -v
*   Trying 2600:9000:2050:8800:1d:fc37:1cc0:93a1...
* TCP_NODELAY set
* Connected to apt.puppet.com (2600:9000:2050:8800:1d:fc37:1cc0:93a1) port 443 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*   CAfile: /etc/ssl/cert.pem
  CApath: none
* TLSv1.2 (OUT), TLS handshake, Client hello (1):
* TLSv1.2 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (OUT), TLS alert, certificate expired (557):
* SSL certificate problem: certificate has expired
* Closing connection 0
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

As far as I can tell, `SecureTransport` does it right - Safari works; however `openssl s_client` (confusingly named!) fails validation:

```
$ openssl version
LibreSSL 2.8.3
$ openssl s_client -connect apt.puppet.com:443 -tls1_2 -servername apt.puppetlabs.com
CONNECTED(00000005)
depth=1 C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
verify error:num=10:certificate has expired
notAfter=May 30 10:48:38 2020 GMT
verify return:0
depth=1 C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
verify error:num=10:certificate has expired
notAfter=May 30 10:48:38 2020 GMT
verify return:0
depth=3 C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
verify error:num=10:certificate has expired
notAfter=May 30 10:48:38 2020 GMT
verify return:0
---
Certificate chain
0 s:/OU=Domain Control Validated/OU=PositiveSSL Multi-Domain/CN=apt.puppet.com
  i:/C=FR/ST=Paris/L=Paris/O=Gandi/CN=Gandi Standard SSL CA 2
1 s:/C=FR/ST=Paris/L=Paris/O=Gandi/CN=Gandi Standard SSL CA 2
  i:/C=US/ST=New Jersey/L=Jersey City/O=The USERTRUST Network/CN=USERTrust RSA Certification Authority
2 s:/C=US/ST=New Jersey/L=Jersey City/O=The USERTRUST Network/CN=USERTrust RSA Certification Authority
  i:/C=SE/O=AddTrust AB/OU=AddTrust External TTP Network/CN=AddTrust External CA Root
```

### GnuTLS

Apparently any version is affected. Example output:

```
$ gnutls-cli apt.puppet.com:443
Processed 129 CA certificate(s).
Resolving 'apt.puppet.com:443'...
Connecting to '2600:9000:206e:9400:1d:fc37:1cc0:93a1:443'...
- Certificate type: X.509
- Got a certificate list of 3 certificates.
- Certificate[0] info:
- subject `CN=apt.puppet.com,OU=PositiveSSL Multi-Domain,OU=Domain Control Validated', issuer `CN=Gandi Standard SSL CA 2,O=Gandi,L=Paris,ST=Paris,C=FR', serial 0x00d50b93f3f071150e62d87aee147a1520, RSA key 2048 bits, signed using RSA-SHA256, activated `2019-07-18 00:00:00 UTC', expires `2020-07-18 23:59:59 UTC', pin-sha256="oBlhqVlMzd0j01OweaExY7LRykSLER7Cyml3qM9Rp4M="
  Public Key ID:
    sha1:c94ab18efcc44ba3c51d39f831a734ad4e78e60b
    sha256:a01961a9594ccddd23d353b079a13163b2d1ca448b111ec2ca6977a8cf51a783
  Public Key PIN:
    pin-sha256:oBlhqVlMzd0j01OweaExY7LRykSLER7Cyml3qM9Rp4M=

- Certificate[1] info:
- subject `CN=Gandi Standard SSL CA 2,O=Gandi,L=Paris,ST=Paris,C=FR', issuer `CN=USERTrust RSA Certification Authority,O=The USERTRUST Network,L=Jersey City,ST=New Jersey,C=US', serial 0x05e4dc3b9438ab3b8597cba6a19850e3, RSA key 2048 bits, signed using RSA-SHA384, activated `2014-09-12 00:00:00 UTC', expires `2024-09-11 23:59:59 UTC', pin-sha256="WGJkyYjx1QMdMe0UqlyOKXtydPDVrk7sl2fV+nNm1r4="
- Certificate[2] info:
- subject `CN=USERTrust RSA Certification Authority,O=The USERTRUST Network,L=Jersey City,ST=New Jersey,C=US', issuer `CN=AddTrust External CA Root,OU=AddTrust External TTP Network,O=AddTrust AB,C=SE', serial 0x13ea28705bf4eced0c36630980614336, RSA key 4096 bits, signed using RSA-SHA384, activated `2000-05-30 10:48:38 UTC', expires `2020-05-30 10:48:38 UTC', pin-sha256="x4QzPSC810K5/cMjb05Qm4k3Bw5zBn4lTdO/nEW/Td4="
- Status: The certificate is NOT trusted. The certificate chain uses expired certificate.
*** PKI verification of server certificate failed...
*** Fatal error: Error in the certificate.
```

### Debian's `apt` and `reprepro`

This uses GnuTLS. By extension, `reprepro`, because that uses `apt-transport-https` (from `apt`).

Failure from `reprepro`:

```
$ reprepro update
aptmethod error receiving 'https://apt.puppet.com/dists/buster/Release':
'server certificate verification failed. CAfile: /etc/ssl/certs/ca-certificates.crt CRLfile: none'
```

### Client SDKs for PHP

Apparently some client SDKs for SaaS use `libcurl` in some non-default config, and also trip over.

Sometimes they also contain an outdated root CA bundle.

### Not affected: OpenSSL 1.1.1d

On Debian stable:

```
$ openssl s_client -connect apt.puppet.com:443
CONNECTED(00000003)
depth=2 C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
verify return:1
depth=1 C = FR, ST = Paris, L = Paris, O = Gandi, CN = Gandi Standard SSL CA 2
verify return:1
depth=0 OU = Domain Control Validated, OU = PositiveSSL Multi-Domain, CN = apt.puppet.com
verify return:1
---
Certificate chain
 0 s:OU = Domain Control Validated, OU = PositiveSSL Multi-Domain, CN = apt.puppet.com
   i:C = FR, ST = Paris, L = Paris, O = Gandi, CN = Gandi Standard SSL CA 2
 1 s:C = FR, ST = Paris, L = Paris, O = Gandi, CN = Gandi Standard SSL CA 2
   i:C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
 2 s:C = US, ST = New Jersey, L = Jersey City, O = The USERTRUST Network, CN = USERTrust RSA Certification Authority
   i:C = SE, O = AddTrust AB, OU = AddTrust External TTP Network, CN = AddTrust External CA Root
---
...
```

Note how it ignores the AddTrust 


## Links

* [AddTrust root](https://crt.sh/?id=1)
* [Ryan Sleevi's analysis of GnuTLS](https://twitter.com/sleevi_/status/1266731836912422912)
* [My ticket for fixing apt.puppet.com](https://tickets.puppetlabs.com/browse/CPR-741)

