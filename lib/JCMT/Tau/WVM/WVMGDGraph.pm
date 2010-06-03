# Note that these methods are placed in the JCMT::Tau::WVM namespace
# so that the methods are available without requiring that the basic
# module needs access to graphics classes
package JCMT::Tau::WVM;

=head1 NAME

JCMT::Tau::WVMGraph - Plot WVM data

=head1 SYNOPSIS

 use JCMT::Tau::WVM;
 use JCMT::Tau::WVMGDGraph;

 $wvm = new JCMT::Tau::WVM(start_time => $s, end_time => $e);

 $gd = $wvm->graph();

=head1 DESCRIPTION

This module allows you to plot WVM data using GD.

=cut

use 5.006;
use strict;
use warnings;
use Carp;

use DateTime;
use GD::Graph::lines;

our $DEBUG = 0;

=head1 FUNCTIONS

=over 4

=item B<wvmgraph>

Construct a graph of WVM data. Returns a GD object.

  $gd = $wvm->graph;

=cut

sub graph {
  my $self = shift;

  my $start = $self->start_time;
  my $end   = $self->end_time;

  printf("START: $start\n") if $DEBUG;
  printf("END: $end\n") if $DEBUG;

  # only need to calculate epoch once
  my $sepoch = $start->epoch;
  my $eepoch = $end->epoch;

  # read the data
  my $wvmdata = $self->data;

  my @xvals;
  my @yvals;

  my $utc = new DateTime::TimeZone( name => 'UTC' );
  foreach my $i (sort keys %$wvmdata) {
      next unless ($i > $sepoch && $i < $eepoch);
      # only keep data that are on 10 second boundaries
      # this only works because we have 1 second samples
      if ( ($i%10 ) == 0) {
	  my $t = DateTime->from_epoch(epoch => $i, time_zone => $utc);

	  push @xvals, $t->strftime('%H:%M');
	  push @yvals, sprintf("%5.4f",$wvmdata->{$i});
      }

  }
  my $y_min = min(@yvals);
  my $y_max = max(@yvals);
  my @data_set = ([@xvals], [@yvals],);

  # Create plot here
  my $graph = GD::Graph::lines-> new(520,340);

  $graph->set( 
	       x_label => 'UT Time',
	       y_label => 'TAU',
	       title => 'JCMT WVM',
	       y_max_value => $y_max,
	       y_min_value => $y_min,

	       y_number_format => "%6.4f",
	       y_tick_number => 14,
	       y_label_skip => 2,
	       x_label_skip => 500,
	       box_axis => 0,
	       line_width => 3,
	       transparent => 0,

	       ) or die $graph->error;

  my $gd = $graph->plot(\@data_set) or croak $graph->error;
  return $gd;
}

=back

=head1 SEE ALSO

L<GD>, L<JCMT::Tau::WVM>

=head1 COPYRIGHT

Copyright (C) 2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Bernd Weferling, Tim Jenness

=cut

1;

