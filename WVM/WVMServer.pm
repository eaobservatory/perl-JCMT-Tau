package JCMT::Tau::WVM::Server;

=head1 NAME

JCMT::Tau::WVM::Server - WVM archive server class

=head1 SYNOPSIS

  $stats = JCMT::Tau::WVM::Server->stats( $start, $end );

=head1 DESCRIPTION

This class provides wrapper methods for the C<JCMT::Tau::WVM>
class providing access to the WVM archive via SOAP services.

=cut

use 5.006;
use strict;
use warnings;

use JCMT::Tau::WVM;
use DateTime;
use DateTime::Format::ISO8601;


use vars qw/ $VERSION /;

$VERSION = '0.01';

=head1 METHODS

=over 4

=item B<stats>

For the two supplied dates (strings in ISO format), returns the
mean 225 GHz tau and standard deviation, along with other statistics.

  $result = $soap->stats( '2004-10-17T12:00', '2004-10-17T12:15' );

The result is returned as an array (a reference to an array for
a perl caller). Members of the array are:

  mean
  standard deviation
  median
  number of WVM samples in date range

=cut

sub stats {
  my ($start, $end) = @_;

  my $stime = DateTime::Format::ISO8601->parse_datetime( $start );
  my $etime = DateTime::Format::ISO8601->parse_datetime( $end );

  my $wvm = new JCMT::Tau::WVM( start_time => $stime, end_time => $etime );

  if ($wvm) {
    my @stats = $wvm->stats;
    my $nsamp = $wvm->nsamples;
    # soap requires ref to array
    return [$stats[0], $stats[1], $stats[2], $nsamp];
  } else {
    die "No data available between times $start to $end\n";
  }

}

=back

=head1 SEE ALSO

L<JCMT::Tau::WVM>, L<SOAP::Lite>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.


=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

1;
