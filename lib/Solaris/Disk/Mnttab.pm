package Solaris::Disk::Mnttab;

use strict;
use warnings;
use Carp;
#use vars qw( %Device2MountPoint %MountPoint2Device );

#require Exporter;
#our %EXPORT_TAGS = ( 'all' => [ qw( PartType PartFlag ) ] );
#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = "0.01";
my $mnttabSource = '/etc/mnttab';
my $swaptabSource = '/sbin/swap -l |';

my @validfs = qw( ufs vxfs proc tmpfs );

=head1 NAME

Solaris::Disk::Mnttab

=head1 SYNOPSIS

  use Solaris::Disk::Mnttab;

  $mnttab = Solaris::Disk::Mnttab::new(%options);

=head1 DESCRIPTION

Solaris::Disk::Mnttab aims to provide methods to read Solaris'
current mounted device table.

Two tables are read: F</etc/mnttab> and the result of C<`swap -l`>.

=head1 METHODS

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
    my $re = join "|", qw( init mnttab swaptab );
    $re = qr/^(?:$re)$/;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice( @args, $i, 2 );
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }
    # shouldn't be anything left in @args
    croak "Unknown parameter(s): @args" if @args;

    bless $self, $class;

    if ( defined $parms{init} && $parms{init} ) {
        if ( defined($parms{mnttab})) {
            $self->readmtab(mnttab => $parms{mnttab});
        }
        else {
            $self->readmtab();
        }
        if ( defined($parms{swaptab})) {
            $self->readstab( swaptab => $parms{swaptab} );
        }
        else {
            $self->readstab();
        }
    }

    $self;
}

=head2 C<readmtab>

The C<readmtab> method allows one to (re-)read the F</etc/mnttab> or, if
specified, the source given by the C<mnttab> argument.

  $mnttab->readmtab;    # reads from system /etc/mnttab
  $mnttab->readmtab( mnttab => 'mymnttabdump.txt');

=cut
sub readmtab
{
    my ($self, @args) = @_;

    my %parms;
    my $i = 0;
    my $re = join "|", qw( mnttab mnttabdir );
    $re = qr/^(?:$re)$/;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice( @args, $i, 2 );
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }

    croak "You cannot specify both mnttab and mnttabdir parameters"
      if (defined($parms{mnttab}) && defined($parms{mnttabdir} ) );

    my $source = defined($parms{mnttab})
                       ? $parms{mnttab}
                       : defined( $parms{mnttabdir} )
                           ? $parms{mnttabdir}.'/mnttab.txt'
                           : $mnttabSource;
    open MTAB, $source
      or croak "Can't open mptab source $source";

    my $validfs = join '|', @validfs;
    $validfs = qr/^(?:$validfs)$/;
    while (<MTAB>) {
        chomp;
        my ( $dev, $mp, $fstype, $opts, $inode );
        ( $dev, $mp, $fstype, $opts, $inode ) = split /\s+/;

        if ( $fstype =~ $validfs ) {
            $dev =~ s!.*\/!!;
            $self->{dev2mp}{$dev} = $mp;
            $self->{mp2dev}{$mp}{device}  = $dev;
            my %options = map { $_ => 1 }  split /,/, $opts;
            foreach (keys %options) {
                delete($options{$_}) if $_ eq '';
            }
            @{$self->{mp2dev}{$mp}{options}} = keys %options;
            $self->{mp2dev}{$mp}{inode}   = $inode;
            $self->{mp2dev}{$mp}{fstype}  = $fstype;
        }
    }
    close MTAB;
}


=head2 C<readstab>

The C<readstab> method allows one to (re-)read the swap table, as given by
the C</sbin/swap -l> command.

If specified, the source given by the C<swaptab> argument is used instead.

  $mnttab->readstab;    # reads from "swap -l"
  $mnttab->readstab( swaptab => 'myswap-l.txt');

=cut
sub readstab
{
    my ($self, @args) = @_;

    my %parms;
    my $i = 0;
    my $re = join "|", qw( swaptab swaptabdir );
    $re = qr/^(?:$re)$/;
    while ( $i < @args ) {
        if ( $args[$i] =~ $re ) {
            my ( $k, $v ) = splice( @args, $i, 2 );
            $parms{$k} = $v;
        }
        else {
            $i++;
        }
    }

    croak "You cannot specify both swaptab and swaptabdir parameters"
      if (defined($parms{swaptab}) && defined($parms{swaptabdir}) );

    my $source = defined($parms{swaptab})
                       ? $parms{swaptab}
                       : defined( $parms{swaptabdir} )
                           ? $parms{swaptabdir}.'/swaptab.txt'
                           : $swaptabSource;


    open STAB, $source
      or croak "Can't read from swap tab source : $source";

    while (<STAB>) {
        chomp;
        my ( $dev, $devn, $slo, $sbl, $sfree) = split /\s+/;

        # pass the header line
        next if $dev eq 'swapfile';
        
        # strip path to device file
        if ($dev =~ m/dsk/) {
            $dev =~ s!.*\/!!;
            $self->{dev2mp}{$dev} = 'swap';
            # This is not really a mount point, so don't feed the reverse...
        }
        $self->{swap}{$dev}{device}  = $dev;
        $self->{swap}{$dev}{devnum}  = $devn;
        $self->{swap}{$dev}{swaplo}  = $slo;
        $self->{swap}{$dev}{swaplen} = $sbl;
        $self->{swap}{$dev}{free}    = $sfree;
    }
    close STAB;
}

'Solaris::Disk::Mnttab';

__END__

=head1 AUTHOR

Jérôme Fenal <jfenal@free.fr>

=head1 VERSION

This is version 0.1 of the Solaris::Disk::Mnttab


=head1 COPYRIGHT

Copyright (C) 2004 Jérôme Fenal. All Rights Reserved

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.


=head1 SEE ALSO

See L<Solaris::Disk::VTOC(3pm)> to access slice information.
See L<Solaris::Disk::SVM(3pm)> to access SDS/SVM device information.

