### DISCLAIMER
THIS ADJOIN TOOL IS NOT SUPPORTED BY SUN. IT SHOULD BE CONSIDERED AS PROOF
OF CONCEPT/TECHNOLOGY AND SHOULD NOT BE USED FOR PRODUCTION.

# License
* See http://www.sun.com/bigadmin/common/berkeley_license.html (via
   Wayback Machine) for License details about this software. See
   http://www.illumos.org/license/CDDL for License details for newer
   components of this software. CDDL-licensed code will have a CDDL-
   referencing file header.

# Further Reading
* See kerberos_s10.pdf, "Using Kerberos to Authenticate a
   Solaris(TM) 10 OS LDAP Client With Microsoft Active Directory"

# Scripts
## adjoin

adjoin script automates process of joining Solaris client to a
   AD domain. It automates the following steps:

   1. Auto-detect Active Directory domain controller. 
   2. Creates a machine account (a.k.a. Computer object) for the
      Solaris host in Active Directory and generates a random
      password for this account. 
   3. Configures the Solaris host as a Kerberos client of AD KDC
      by setting up `/etc/krb5/krb5.conf` on the Solaris host.
   4. Sets up `/etc/krb5/krb5.keytab` file on the Solaris host using
      the keys generated for the machine account.
   5. If you run this script as `adleave` (symlink), then it
      deletes the machine account and leaves the AD domain.

## krbpam
krbpam script automates process of enabling the pam_krb5.so.1 in pam.conf
   for Active Directory/Kerberos authentication, account management, and
   password management on a solarish client.

## Files
* sources
  * src/adjoin.sh
  * src/krbpam.pl
  * src/ksetpw.c
* sparc bits
  * sparc/adjoin
  * sparc/adleave
  * sparc/krbpam
* i386 bits
  * i386/adjoin
  * i386/adleave
  * i386/krbpam
* amd64 bits
  * amd64/adjoin
  * amd64/adleave
  * amd64/krbpam

# Installation

1. Build the `ksetpw` program if the binaries are not available
   for your platform (`CC` is e.g. `cc` or `gcc`):

```
% $CC -o ksetpw ../src/ksetpw.c -lkrb5
```

2. Configure `/etc/resolv.conf` to point to AD DNS server

```
% cat /etc/resolv.conf
domain mydomain.com
search mydomain.com otherdomain.com
nameserver 11.22.33.44
```

3. Use DNS for host resolution

```
% grep dns /etc/nsswitch.conf
hosts:      dns files
ipnodes:    dns files
```

4. Restart nscd and dns if `resolv.conf` or `nsswitch.conf` were modified

```
% svcadm restart network/dns/client
% svcadm restart name-service-cache
```

5. In the same directory where you have `ksetpw`, run the `adjoin` script:

    *  `-h` to get help
    *  `-n` for dry runs
    *  `-f` force creation of machine account in AD by deleting existing entry

```
% ./adjoin -f
```

6. Optional: manually create DNS A and PTR RRs in AD for your client

7. If the `adjoin` script runs without error, edit `/etc/nsswitch.ldap`, which
   will be copied later by `ldapclient` to overwrite `/etc/nsswitch.conf`:

   7.1. Make a backup copy if not yet done (Bash syntax):

```
% cp -a /etc/nsswitch.ldap{,.orig}
```

   7.2. Edit `/etc/nsswitch.ldap` to use DNS (mdns only if applicable):

```
% egrep '^(hosts:|ipnodes:)' /etc/nsswitch.ldap
hosts:      files dns mdns
ipnodes:    files dns mdns
```

   7.3. Continue to edit `/etc/nsswitch.ldap`, setting "ldap" for the following:

```
% egrep '^(passwd:|group:)' /etc/nsswitch.ldap
passwd: files ldap
group:  files ldap
```

   7.4. Finally, finish editing `/etc/nsswitch.ldap` to remove "ldap" from all
      other "database" settings (e.g., from "networks", "protocols", "rpc",
      etc.).

8. Follow the instructions in the kerberos_s10.pdf section "Initializing the
   Solaris LDAP Client." N.b. that the "ldapclient" commands as documented in
   the PDF do not properly escape for shells such as Bash the '?' characters
   appearing as arguments. For example, the following:

````
       -a serviceSearchDescriptor=group:cn=users,dc=companyxyz,dc=com?one
````

   should be escaped as:

````
       -a serviceSearchDescriptor=group:cn=users,dc=companyxyz,dc=com\?one
````

9. If the LDAP client tests run without error, run the `krbpam` script:
    *  `-h` to get help
    *  `-n` for dry runs
    *  `-v` for verbose output

````
% ./krbpam -n -v		# dry-run
% ./krbpam
````

# ISSUES

   1. To use adjoin with Windows 2008 server, remove "@${realm}" from
      the userPrincipalName otherwise you'll get Authentication error. For
      Windows 2012 or higher, however, it will work as it is without revision.

````
      # diff adjoin.win2k3 adjoin.longhorn  
      765c765
      < userPrincipalName: host/${fqdn}@${realm}
      ---
      > userPrincipalName: host/${fqdn}
````


# Acknowledgements
* Originally written by Nico Williams for the Winchester OpenSolaris project
* Updated by Baban Kenkre for Solaris 10.
* Updated by C Fraire for illumos and Windows Server 2012 and to manage pam.conf.
