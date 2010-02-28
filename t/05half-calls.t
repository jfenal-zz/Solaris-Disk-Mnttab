#!/usr/bin/perl -w
# in case Test::More ain't there
# vim: syntax=perl
BEGIN {
    eval { require Test::More; };
    print "1..0\n" and exit if $@;
}

use strict;
use Test::More;
use lib qw( ./lib ../lib );

BEGIN { plan tests => 18; }

BEGIN { use_ok('Solaris::Disk::Mnttab'); }
require_ok('Solaris::Disk::Mnttab');

my $mnttab;

$mnttab = Solaris::Disk::Mnttab->new;
ok( $mnttab, "No parm" );

$mnttab = Solaris::Disk::Mnttab->new( fake => "param" );
ok( $mnttab, "Unknown parm" );

$mnttab->readmtab( fake => "param" );
ok( $mnttab, "Unknown parm" );

$mnttab->readstab( fake => "param" );
ok( $mnttab, "Unknown parm" );

$mnttab = Solaris::Disk::Mnttab->new( init => 0 );
ok( defined($mnttab), "No init" );

if ( -r '/etc/mnttab' ) {
    $mnttab = Solaris::Disk::Mnttab->new( init => 1 );
    ok( $mnttab, "Half init OK" );
}
else {
    ok( 1, "Dummy test" );
}

$mnttab = Solaris::Disk::Mnttab->new( init => 1, );
ok( defined($mnttab), "Half init OK" );

$mnttab = Solaris::Disk::Mnttab->new(
    mnttab => "t/mnttab.txt",
    init   => 0,
);
ok( defined($mnttab), "Half init OK" );

if ( -x '/sbin/swap' ) {
    $mnttab = Solaris::Disk::Mnttab->new( mnttab => "t/mnttab.txt", );
    ok( defined($mnttab), "Half init OK" );
    $mnttab = Solaris::Disk::Mnttab->new(
        mnttab => "t/mnttab.txt",
        init   => 1,
    );
    ok( defined($mnttab), "Half init OK" );
}
else {
    ok( 1, "Dummy test" );
    ok( 1, "Dummy test" );
}

$mnttab = Solaris::Disk::Mnttab->new(
    swaptab => "t/swaptab.txt",
    init    => 0,
);
ok( defined($mnttab), "Half init OK" );

if ( -r '/etc/mnttab' ) {
    $mnttab = Solaris::Disk::Mnttab->new( swaptab => "t/swaptab.txt", );
    ok( defined($mnttab), "Half init OK" );
    $mnttab = Solaris::Disk::Mnttab->new(
        swaptab => "t/swaptab.txt",
        init    => 1,
    );
    ok( defined($mnttab), "Half init OK" );
}
else {
    ok( 1, "Dummy test" );
    ok( 1, "Dummy test" );
}

$mnttab = new Solaris::Disk::Mnttab(
    mnttab  => "t/swaptab.txt",
    swaptab => "t/swaptab.txt",
    init    => 0,
);
ok( defined($mnttab), "all parms, no init" );

$mnttab = Solaris::Disk::Mnttab->new(
    mnttab  => "t/swaptab.txt",
    swaptab => "t/swaptab.txt",
    init    => 1,
);
ok( defined($mnttab), "all parms, init" );

my $mnttab2 = $mnttab->new(
    mnttab  => "t/swaptab.txt",
    swaptab => "t/swaptab.txt",
    init    => 1,
);
ok( $mnttab, "all parms as hashref, init" );

