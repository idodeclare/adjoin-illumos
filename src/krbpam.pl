#!/usr/bin/perl
#
# CDDL HEADER START
#
# The contents of this file are subject to the terms of the
# Common Development and Distribution License (the "License").
# You may not use this file except in compliance with the License.
#
# You can obtain a copy of the license at
# http://www.illumos.org/license/CDDL.
#
# See the License for the specific language governing permissions
# and limitations under the License.
#
# When distributing Covered Code, include this CDDL HEADER in each
# file and include the LICENSE file.
#
# If applicable, add the following below this CDDL HEADER, with the
# fields enclosed by brackets "[]" replaced with your own identifying
# information: Portions Copyright [yyyy] [name of copyright owner]
#
# CDDL HEADER END
#
# Copyright (c) 2016, C Fraire <cfraire@me.com>
#

use strict;
use warnings;
use File::Copy;
use Getopt::Std;

our $USAGE = <<"END";
Usage: $0 [-n] [-v]

	Options:

	-n	Dry-run (don't do anything)
	-v	Verbose (show the commands run and lines created/modified)

	Updates /etc/pam.conf to use the pam_krb5.so.1 module to enable
	authentication, account management, and password management on a
	solarish client by using Active Directory through Kerberos, while
	still falling back to UNIX login and password management for non-
	Active Directory accounts.

	The modules are specifically arranged to best support the
	configuration where a majority of users are in Active Directory and
	where there are only a few non-Active Directory user accounts, such
	as root.

	A backup copy, /etc/pam.conf-pre-adjoin, is made if it doesn't yet
	exist.
END

our ($ORIGPAMCONF, $pamconf, $opt_n, $opt_v);
our $PAMCONF = "/etc/pam.conf";
our $PAMCONFBAK = "$PAMCONF-pre-adjoin";
our $PAMCONFTMP = "$PAMCONF-tmp";

die $USAGE if !getopts('nv');

my ($lede);

if (! -f $PAMCONFBAK) {
	$lede = $opt_n ? "Would create" : "Creating";
	print "$lede backup $PAMCONFBAK\n" if $opt_v || $opt_n;
	(copy($PAMCONF, $PAMCONFBAK) or die "Error copying to $PAMCONFBAK\n")
	  if !$opt_n;
}

$pamconf = $ORIGPAMCONF = `cat "$PAMCONF"` or die "Error reading $PAMCONF\n";

# affirm contiguous match of "login auth" service lines
my ($logauth, $logauth_p, $logauth_l)
  = validatedread(qr/\s*\b login \s+ auth \s.+/mx, "login auth");

# affirm contiguous match of "other auth" service lines
my ($oth_auth, $oth_auth_p, $oth_auth_l)
  = validatedread(qr/\s*\b other \s+ auth \s.+/mx, "other auth");

# affirm contiguous match of "other account" service lines
my ($oth_acc, $oth_acc_p, $oth_acc_l)
  = validatedread(qr/\s*\b other \s+ account \s.+/mx, "other account");

# affirm contiguous match of "other password" service lines
my ($oth_pw, $oth_pw_p, $oth_pw_l)
  = validatedread(qr/\s*\b other \s+ password \s.+/mx, "other password");

# Amend the sections from bottom to top, since the reads returned
# offsets/lengths
my ($IXCONF, $IXPOS, $IXLEN, $IXSUB) = (0, 1, 2, 3);
my @edits = (
  [$logauth, $logauth_p, $logauth_l, \&amend_logauth],
  [$oth_auth, $oth_auth_p, $oth_auth_l, \&amend_oth_auth],
  [$oth_acc, $oth_acc_p, $oth_acc_l, \&amend_oth_acc],
  [$oth_pw, $oth_pw_p, $oth_pw_l, \&amend_oth_pw],
);
@edits = sort { $b->[$IXPOS] <=> $a->[$IXPOS] } @edits;

# Execute edits in-memory
foreach my $e (@edits) {
	my ($c, $p, $l, $s) = @$e;
	&$s($c, $p, $l);
}

# If original == modified, then do nothing
if ($ORIGPAMCONF eq $pamconf) {
	print "Nothing more to do.\n";
	exit 0;
}

# Write temp file in same filesystem as pam.conf
$lede = $opt_n ? "Would write" : "Writing";
print "$lede $PAMCONFTMP\n" if $opt_v || $opt_n;
if ($opt_v && $opt_n) {
	my $vconf = $pamconf;
	$vconf =~ s/^/> /mg;
	$vconf .= "\n" if $vconf !~ /\n$/;
	print $vconf;
}
(writetmpconf() or die "Error writing $PAMCONFTMP\n")
  if !$opt_n;

# Rename temporary file to pam.conf
$lede = $opt_n ? "Would rename" : "Renaming";
print "$lede $PAMCONFTMP as $PAMCONF\n" if $opt_v || $opt_n;
(rename $PAMCONFTMP, $PAMCONF or do {
	unlink $PAMCONFTMP;
	die "Error renaming to clobber $PAMCONF\n";
}) if !$opt_n;

# DONE
print "Done", $opt_n ? " (dryrun)" : "", "\n";

#-----------------------------------------------------------------------------

sub amend_logauth {
	my ($section, $pos, $len) = @_;

	my $servicemodule = "login auth";
	my $snmtrex = qr/\s*\b login \s+ auth \b/x;
	my $markerlib = "pam_unix_cred.so.1";

	amend_section($section, $pos, $len, $servicemodule, $snmtrex, $markerlib);
}

sub amend_oth_auth {
	my ($section, $pos, $len) = @_;

	my $servicemodule = "other auth";
	my $snmtrex = qr/\s*\b other \s+ auth \b/x;
	my $markerlib = "pam_unix_cred.so.1";

	amend_section($section, $pos, $len, $servicemodule, $snmtrex, $markerlib);
}

sub amend_oth_acc {
	my ($section, $pos, $len) = @_;

	my $servicemodule = "other account";
	my $snmtrex = qr/\s*\b other \s+ account \b/x;
	my $markerlib = "pam_unix_account.so.1";

	amend_section($section, $pos, $len, $servicemodule, $snmtrex, $markerlib);
}

sub amend_oth_pw {
	my ($section, $pos, $len) = @_;

	my $servicemodule = "other password";
	my $snmtrex = qr/\s*\b other \s+ password \b/x;
	my $markerlib = "pam_authtok_check.so.1";

	amend_section($section, $pos, $len, $servicemodule, $snmtrex, $markerlib);
}

sub amend_section {
	my ($section, $pos, $len, $servicemodule, $snmtrex, $markerlib) = @_;

	my $PAMKRB5LIB = "pam_krb5.so.1";
	return if $section =~ /\Q$PAMKRB5LIB\E/;

	# Initialize regex to match the $markerlib line
	my $prefix;
	my $markerlibrex = qr/^($snmtrex) \s+ # service name-module type + spacer
	  \S+ (\s+)                           # control flag + spacer
	  \Q$markerlib\E                      # matching library to precede amendment
	  .*(\n?)\K                           # options + trailing space + KEEP flag
	  /mx;

	# Initialize the subroutine to produce the krb5 line to be placed after
	# the $markerlib lib
	my $amendfunc = sub {
		my ($snmt, $spacer, $endline) = @_;

		# if the krb5 amendment will be the last instruction, it must be
		# "required"; otherwise, leave it as "sufficient".
		my $krbcontrolflag = $' =~ m`\b required \b`x ? "sufficient" : "required";
		(length($endline) > 0 ? "" : "\n")
		  . qq[${prefix}${snmt} ${krbcontrolflag}${spacer}${PAMKRB5LIB}\n];
	};

	if ($opt_v) {
		# note the indentations for diff-like output
		$prefix = "+ ";
		my $vsection = $section;
		$vsection =~ s/$markerlibrex/&$amendfunc($1, $2, $3)/mxe;
		if ($vsection ne $section) {
			$vsection =~ s/^(?!\+)/  /mg;
			$vsection .= "\n" if $vsection !~ /\n$/;
			print "+++ '$servicemodule' changes:\n";
			print $vsection;
		}
	}

	$prefix = "";
	my $savedsection = $section;
	$section =~ s/$markerlibrex/&$amendfunc($1, $2, $3)/mxe;
	if ($section eq $savedsection) {
		warn "No insertion point found for '$servicemodule' section "
		  . "after $markerlib:\n";
		$section =~ s/^/> /gm;
		$section .= "\n" if $section !~ /\n$/;
		print STDERR $section;
		return;
	}

	substr($pamconf, $pos, $len) = $section;
}

sub validatedread {
	my ($linerex, $servicemodule) = @_;

	die "Error matching '$servicemodule' in $PAMCONF\n" if $pamconf !~ /
	  (^$linerex\n
	   (?:.+\n)*
	   ^$linerex\n?)
	  /mx;
	my ($section, $pos, $len) = ($1, $-[1], $+[1]-$-[1]);

	die "'$servicemodule' service lines are not contiguous in $PAMCONF\n"
	  if $section =~ /^(?!$linerex)(?!#)(?!\s*$)/m;

	return ($section, $pos, $len);
}

sub writetmpconf {
	open(my $fh, ">", $PAMCONFTMP)
	  or die "Error opening > $PAMCONFTMP: $!";

	print $fh $pamconf or do {
		warn "Error printing to $PAMCONFTMP: $!";
		return 0;
	};

	close($fh) or do {
		warn "Error closing $PAMCONFTMP: $!";
		return 0;
	};
	return 1;
}
