package JCMT::Tau::WVM::WVMLib;

=head1 NAME

JCMT::Tau::WVM::WVMLib - Interface to the WVM C library

=head1 SYNOPSIS

  use JCMT::Tau::WVM::WVMLib qw/ pwv2tau /;

  $tau = pwv2tau( );

=head1 DESCRIPTION

Perl interface to the C WVM library.


=cut


require Exporter;
require DynaLoader;

use strict;
use warnings;

use vars qw/ @ISA @EXPORT_OK $VERSION /;
$VERSION = '0.01';


@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw/ pwv2tau /;

JCMT::Tau::WVM::WVMLib->bootstrap( $VERSION );


=head1 FUNCTIONS

=over 4

=item B<pwv2tau>

Convert precipitable water vapor to 225GHZ tau.

  $tau = pwv2tau( $airmass, $pwv );

=back

=head1 COPYRIGHT

Copyright 2004 (C) Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

1;
