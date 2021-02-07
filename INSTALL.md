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
