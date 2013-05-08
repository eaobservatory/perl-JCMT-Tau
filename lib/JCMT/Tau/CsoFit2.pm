package JCMT::Tau::CsoFit2;

=head1 NAME

JCMT::Tau::CsoFit2 - Process fits to CSO data created by csofit.py.

=head1 SYNOPSIS

 use JCMT::Tau::CsoFit2;

 # Read in a file of tau fits.
 $fit = new JCMT::Tau::CsoFit2( $filename );

 # Get a subset of fits for a specific range (speeds up calcs).
 # $t0 and $t1 should be unix timestamps, ie DateTime::epoch().
 $subset = $fit->get( $t0, $t1 );

 # Get the tau for a specific time.
 # This is a weighted average of overlapping fits, where each fit
 # is weighted with a simple smoothstep envelope.
 # $t should be a unix timestamp, ie DateTime::hires_epoch().
 $csotau = $subset->tau( $t );

=cut

use strict;
use warnings;

use DateTime::Format::Strptime;
use IO::File;

use vars qw/ $VERSION /;
$VERSION = "0.11";

=head1 DESCRIPTION

This module provides an interface for reading a file containing
fits to the CSO tau data produced by csofit.py.

=head1 METHODS

=over 4

=item B<new>

Open the file containing the fits and read it in to the
returned object.

    $fit = JCMT::Tau::CsoFit2( $filename );

=cut

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    return undef unless @_;

    my $strp = DateTime::Format::Strptime->new(
        pattern => '%Y-%m-%dT%H:%M:%S',
        time_zone => 'UTC',
    );

    my @fits;
    my $filename = shift;
    my $io = new IO::File("< $filename");
    while (defined( my $line =<$io>)) {
        # split this line, iso0, iso1, deg, coefs[deg+1], rms_limit, dev_limit
        my @toks = split(/\s+/, $line);
        push(@fits, [
            $strp->parse_datetime($toks[0])->hires_epoch(),
            $strp->parse_datetime($toks[1])->hires_epoch(),
            @toks[3..(3+$toks[2])],
            $toks[6 + $toks[2]],
            ]
        );
    }
    close($io);

    my $obj = bless {}, $class;
    $obj->{filename} = $filename;
    $obj->{fits} = \@fits;
    return $obj;
}

=item B<get>

Get a subset of the current fits as a new CsoFit2 object.
$t0 and $t1 are unix timestamps ala DateTime::epoch().

    $subset = $fit->get( $t0, $t1 );

=cut

sub get {
    my $self = shift;
    my $t0 = shift;
    my $t1 = shift;

    # 1s fudge for proper blending in tau()
    $t0 -= 1.0;
    $t1 += 1.0;

    my @subset;
    foreach my $fref (@{$self->{fits}}) {
        if($$fref[1] > $t0 && $$fref[0] < $t1) {
            push(@subset, $fref);
        }
    }

    my $obj = bless {};
    $obj->{filename} = $self->{filename};
    $obj->{fits} = \@subset;
    return $obj;
}

=item B<tau>

Calculate blended tau at given time.
Returns undef for unfitted times.
$t is a unix timestamps ala DateTime::hires_epoch().

    $csotau = $subset->tau( $t );

=cut

sub tau {
    my $self = shift;
    my $t = shift;
    my $w = 0.0;
    my $y = 0.0;
    foreach my $fref (@{$self->{fits}}) {
        my $width = $$fref[1] - $$fref[0];
        my $center = ($$fref[1] + $$fref[0]) * 0.5;
        # calc weight -- double smoothstep with 1s fudge.
        my $fw = 1.0 - (abs($t - $center) / ($width*0.5 + 1.0));
        if ($fw < 0.0) { $fw = 0.0; }
        $fw = 3.0*$fw*$fw - 2.0*$fw*$fw*$fw;
        # evaluate fit polynomial at this point
        my $fy = 0.0;
        my $ft = ($t - $$fref[0]) / $width;
        my $last = $#{$fref} - 1;
        my $deg = $last - 2;
        foreach my $c (@$fref[2..$last]) {
            $fy += ($ft**$deg) * $c;
            $deg--;
        }
        $y += $fw * $fy;
        $w += $fw;
    }
    if ($w == 0.0) { $y = undef; } else { $y /= $w; }
    return $y;
}

=item B<mar>

Return weighted MAR from the fits which
apply at a given time.

    $mar = $subset->mar($t);

=cut

sub mar {
    my $self = shift;
    my $t = shift;

    my $m = 0.0;
    my $w = 0.0;

    foreach my $fref (@{$self->{'fits'}}) {
        # Same calculation of $fw as in tau() above...
        my $width = $$fref[1] - $$fref[0];
        my $center = ($$fref[1] + $$fref[0]) * 0.5;
        # calc weight -- double smoothstep with 1s fudge.
        my $fw = 1.0 - (abs($t - $center) / ($width * 0.5 + 1.0));

        next if $fw < 0.0;

        $m += $fw * $fref->[-1];
        $w += $fw;
    }

    return undef if $w == 0.0;
    return $m / $w;
}

=back

=head1 AUTHOR

Ryan Berthold E<lt>r.berthold@jach.hawaii.eduE<gt>

Copyright (C) 2013 Science And Technology Facilities Council.
All Rights Reserved.

=head1 LICENCE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 3 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied
warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
MA 02111-1307, USA

=cut

1;
