package JCMT::Tau::SCUBA2;

=head1 NAME

JCMT::Tau::SCUBA2 - Tau conversions for SCUBA-2 filters

=head1 SYNOPSIS

   use JCMT::Tau;

   ($tau450, $status)   = get_tau('450', 'CSO', $csotau);
   ($trans850, $status) = transmission($airmass, $tau850);
   ($airmass, $status)  = airmass($elevation);

=head1 DESCRIPTION

SCUBA-2 variant of the JCMT::Tau module. The interface is identical
to that of JCMT::Tau but supports the SCUBA-2 filter names and the
SCUBA-2 filter tau relations.

=cut

use strict;
use warnings;

use JCMT::Tau ();

use Carp;
use vars qw($VERSION @ISA @EXPORT %Tau_Relation);

$VERSION = "1.00";

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(transmission get_tau airmass %Tau_Relation);

# These are the values in the SCUBA-2 calibration paper
%Tau_Relation = (
                 "CSO:450" => [ 26.0, -0.0120 ],
                 "CSO:850" => [  4.6, -0.0043 ],
);

# Calculate inverse
JCMT::Tau::_invert_relations( \%Tau_Relation );

# Call the original implementation with the new relation
sub get_tau {
  JCMT::Tau::get_tau_with_relation( @_[0..3], \%Tau_Relation );
}

# Provide stubs to call the original versions
*airmass = \&JCMT::Tau::airmass;
*transmission = \&JCMT::Tau::transmission;

=head1 SEE ALSO

JCMT::Tau, JCMT::Tau::WVM.

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

Copyright 2010 Science and Technology Facilities Council.
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
