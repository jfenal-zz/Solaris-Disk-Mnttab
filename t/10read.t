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

plan tests => 3;

BEGIN { use_ok('Solaris::Disk::Mnttab'); }
require_ok('Solaris::Disk::Mnttab');

my $mnttab = new Solaris::Disk::Mnttab(
    mnttab  => "t/mnttab.txt",
    swaptab => "t/swaptab.txt",
    init    => 1,
);


is_deeply(
    $mnttab,
    bless(
        {
            'swap' => {
                '/dev/garbage1' => {
                    'free'    => '2624560',
                    'device'  => '/dev/garbage1',
                    'swaplo'  => '16',
                    'devnum'  => '32,57',
                    'swaplen' => '2624560'
                },
                'c0t8d0s1' => {
                    'free'    => '2624560',
                    'device'  => 'c0t8d0s1',
                    'swaplo'  => '16',
                    'devnum'  => '32,57',
                    'swaplen' => '2624560'
                },
                'c0t0d0s1' => {
                    'free'    => '2624560',
                    'device'  => 'c0t0d0s1',
                    'swaplo'  => '16',
                    'devnum'  => '32,1',
                    'swaplen' => '2624560'
                }
            },
            'dev2mp' => {
                'swap'     => '/tmp',
                'c0t3d0s0' => '/',
                'c0t8d0s1' => 'swap',
                'c0t0d0s1' => 'swap',
                'proc'     => '/proc',
                'c0t1d0s6' => '/usr'
            },
            'mp2dev' => {
                '/' => {
                    'device'  => 'c0t3d0s0',
                    'options' => [ 'rw', 'suid' ],
                    'fstype'  => 'ufs',
                    'inode'   => '693186371'
                },
                '/proc' => {
                    'device'  => 'proc',
                    'options' => [ 'rw', 'suid' ],
                    'fstype'  => 'proc',
                    'inode'   => '693186371'
                },
                '/tmp' => {
                    'device'  => 'swap',
                    'options' => [ 'dev=0' ],
                    'fstype'  => 'tmpfs',
                    'inode'   => '693186373'
                },
                '/usr' => {
                    'device'  => 'c0t1d0s6',
                    'options' => [ 'rw', 'suid' ],
                    'fstype'  => 'ufs',
                    'inode'   => '693186371'
                }
            }
        },
        'Solaris::Disk::Mnttab'
    )
);

is($mnttab->{swap}->{swapfile}, undef, "Should not have read the header line");
