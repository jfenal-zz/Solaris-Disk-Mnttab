package Solaris::Disk::Mnttab;

use strict;
use warnings;
use Carp;

#use vars qw( %Device2MountPoint %MountPoint2Device );

#require Exporter;
#our %EXPORT_TAGS = ( 'all' => [ qw( PartType PartFlag ) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.04';
my $mnttabsource  = '/etc/mnttab';
my $swaptabsource = '/sbin/swap -l |';

my @validfs = qw( ufs vxfs proc tmpfs );

=head1 NAME

Solaris::Disk::Mnttab - Read Solaris list of mounted devices

=head1 SYNOPSIS

  use Solaris::Disk::Mnttab;

  $mnttab = Solaris::Disk::Mnttab->new(%options);

=head1 DESCRIPTION

Solaris::Disk::Mnttab aims to provide methods to read Solaris'
current mounted device table.

Two tables are read: F</etc/mnttab> and the result of C<`swap -l`>.

=head1 SUBROUTINES/METHODS

=head2 C<new>

The C<new> method returns a new Solaris::Disk::Mnttab object.

No initialisation nor information read.

  $mnttab = Solaris::Disk::Mnttab->new();

Initialise and read tables, from optional sources

  $mnttab = Solaris::Disk::Mnttab->new( init => 1,
                                      [ mnttab => '/etc/mnttab', ]
                                      [ swaptab => 'swap -l |', ]
                                      );

=cut

sub new {
    my ( $class, @args ) = @_;
    $class = ref($class) || $class;

    my $self = {};

    my %parms;
    my $i = 0;
    my $re = join q(|), qw( init mnttab swaptab );
    $re = qr{ \A (?:$re) \z }imxs;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice @args, $i, 2;
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }

    # shouldn't be anything left in @args
    carp "Unknown parameter(s): @args" if scalar @args;

    bless $self, $class;

    if ( defined $parms{init} && $parms{init} ) {
        if ( defined $parms{mnttab} ) {
            $self->readmtab( mnttab => $parms{mnttab} );
        }
        else {
            $self->readmtab();
        }
        if ( defined $parms{swaptab} ) {
            $self->readstab( swaptab => $parms{swaptab} );
        }
        else {
            $self->readstab();
        }
    }

    return $self;
}

=head2 C<readmtab>

The C<readmtab> method allows one to (re-)read the F</etc/mnttab> or, if
specified, the source given by the C<mnttab> argument.

  $mnttab->readmtab;    # reads from system /etc/mnttab
  $mnttab->readmtab( mnttab => 'mymnttabdump.txt');

=cut

sub readmtab {
    my ( $self, @args ) = @_;

    my %parms;
    my $i = 0;
    my $re = join q(|), qw( mnttab );    # mnttabdir
    $re = qr{ \A (?:$re) \z }imxs;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice @args, $i, 2;
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }

    # shouldn't be anything left in @args
    carp "Unknown parameter(s): @args" if @args;

    # croak "You cannot specify both mnttab and mnttabdir parameters"
    #   if ( defined( $parms{mnttab} ) && defined( $parms{mnttabdir} ) );

    my $source = defined $parms{mnttab} ? $parms{mnttab} : $mnttabsource;

    if ( open my $mtab, '<', $source ) {
        my $validfs = join q(|), @validfs;
        $validfs = qr{ \A (?:$validfs) \z }imxs;
        while (<$mtab>) {
            chomp;
            my ( $dev, $mp, $fstype, $opts, $inode );
            ( $dev, $mp, $fstype, $opts, $inode ) = split qr{ \s+ }imxs;
            next if !defined $mp;
            next if !defined $fstype;
            next if !defined $opts;
            next if !defined $inode;

            if ( $fstype =~ $validfs ) {
                $dev =~ s{ \A .*\/ }{}imxs;
                $self->{dev2mp}{$dev} = $mp;
                $self->{mp2dev}{$mp}{device} = $dev;
                my %options = map { $_ => 1 } split qr{ , }imxs, $opts;
                foreach ( keys %options ) {
                    if ( $_ eq q{} ) {
                        delete $options{$_};
                    }
                }
                @{ $self->{mp2dev}{$mp}{options} } = sort keys %options;
                $self->{mp2dev}{$mp}{inode}  = $inode;
                $self->{mp2dev}{$mp}{fstype} = $fstype;
            }
        }
        close $mtab
          or carp "Can't close mnttab source $source";
    }
    else {
        carp "Can't open mnttab source $source";
    }

    return;
}

=head2 C<readstab>

The C<readstab> method allows one to (re-)read the swap table, as given by
the C</sbin/swap -l> command.

If specified, the source given by the C<swaptab> argument is used instead.

  $mnttab->readstab;    # reads from "swap -l"
  $mnttab->readstab( swaptab => 'myswap-l.txt');

=cut

sub readstab {
    my ( $self, @args ) = @_;

    my %parms;
    my $i = 0;
    my $re = join q(|), qw( swaptab );    # swaptabdir
    $re = qr{\A (?:$re) \z }imxs;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice @args, $i, 2;
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }

    # shouldn't be anything left in @args
    carp "Unknown parameter(s): @args" if @args;

    #    croak "You cannot specify both swaptab and swaptabdir parameters"
    #      if ( defined( $parms{swaptab} ) && defined( $parms{swaptabdir} ) );

    my $source = defined( $parms{swaptab} ) ? $parms{swaptab} : $swaptabsource;

    if ( ( -f '/sbin/swap' || $swaptabsource ne $source ) && open my $stab,
        '<', $source )
    {
        while (<$stab>) {
            chomp;
            my ( $dev, $devn, $slo, $sbl, $sfree ) = split qr{ \s+
            }imxs;
            next if !defined $devn;
            next if !defined $slo;
            next if !defined $sbl;
            next if !defined $sfree;

            # pass the header line
            next if $dev eq 'swapfile';
            next if $dev !~ m{ \A / }imxs;

            # strip path to device file
            if ( $dev =~ m{ dsk }imxs ) {
                $dev =~ s{ \A .* \/ }{}imxs;
                $self->{dev2mp}{$dev} = 'swap';

                # This is not really a mount point, so don't feed the reverse...
            }
            $self->{swap}{$dev}{device}  = $dev;
            $self->{swap}{$dev}{devnum}  = $devn;
            $self->{swap}{$dev}{swaplo}  = $slo;
            $self->{swap}{$dev}{swaplen} = $sbl;
            $self->{swap}{$dev}{free}    = $sfree;
        }
        close $stab
          or carp "Can't close from swap tab source : $source";
    }
    else {
        carp "Can't open swap tab source : $source";
    }

    return;
}

1;

__END__

=head1 DIAGNOSTICS

Could be also in the L<BUGS> sections. Heavy usage of C<carp>, so
mainly a matter of looking at (non-blocking) error messages.

=head1 CONFIGURATION AND ENVIRONMENT

This module is supposed to run on Solaris, but it's been a long time
I haven't had access to such a machine.

=head1 DEPENDENCIES

Solaris local file F</etc/mnttab> & command C</sbin/swap>.

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

See L<DIAGNOSTICS>.

=head1 AUTHOR

Jérôme Fenal <jfenal@free.fr>

=head1 VERSION

This is version 0.04 of the Solaris::Disk::Mnttab


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2004, 2005, 2010 Jérôme Fenal. All Rights Reserved

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.


=head1 SEE ALSO

See L<Solaris::Disk::VTOC(3pm)> to access slice information.
See L<Solaris::Disk::SVM(3pm)> to access SDS/SVM device information.

