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
