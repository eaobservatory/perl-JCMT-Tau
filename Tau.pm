package JCMT::Tau;

#------------------------------------------------------------------------------

=head1 NAME

JCMT::Tau - Module for dealing with sky opacity related topics.

=head1 SYNOPSIS

 use JCMT::Tau;

 ($tau450, $status)   = get_tau(450, 'CSO', $csotau);
 ($trans850, $status) = transmission($airmass, $tau850);
 ($airmass, $status)  = airmass($elevation);


=head1 DESCRIPTION

It is often the case that the zenith sky opacity at 450 or 850 microns is 
unknown, but the opacity at 225 GHz is available from the Caltech Submillimeter
Observatory (http://puuoo.caltech.edu/index.html). The empirical relationships 
between 450 Tau and 850 Tau with CSO Tau have been derived from past skydips at
the JCMT. Similar relations have also been derived for 350 and 750 microns, 
although there is currently very little data to support them. This module 
presently contains two functions: get_tau for retrieving sky opacity at 450, 
850, 350 and 750  microns and transmission for calculating the atmospheric 
transmission coefficient at a given airmass and sky opacity.

=cut

#------------------------------------------------------------------------------

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT %Tau_Relation);

$VERSION = "1.03";

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(transmission get_tau airmass %Tau_Relation);

#------------------------------------------------------------------------------
#                            *** Functions ***
#------------------------------------------------------------------------------

=head1 FUNCTION CALLS

There are only two functions, both of which are imported when the module is
called.

=cut

#------------------------------------------------------------------------------

=head2 RETRIEVING TAU:

  ($tau450,$status) = get_tau('450','CSO',$cso_tau);

=head2 Parameters

=over

=item 1.

The first parameter is a string naming the Tau value that is desired, which 
can be '450','850', '350' or '750'.

=item 2.

The second parameter is a string naming the source Tau value from which the 
target Tau value will be derived. Must be one of the following:  '450', '850',
'350', '750', or 'CSO'.

*NOTE: You cannot use 350 and 750 to derive 450 and 850, and vice versa.

=item 3.

The last parameter is the numerical value of the source Tau.

=back

=head2 Return Values

get_tau returns a 2-element list. The first element is the value of the target
Tau as calculated. The second is a scalar containing the exit status of the
function:

 status = 0: successful
         -1: failed due to invalid parameters
         -2: target Tau = source Tau (but still returns 
             correct number)

=head2 Storing Current Coefficients

The actual coefficients of the relation y = a(x + b) where x and y are zenith
sky opacities at different wavelengths are stored in a hash which is imported
when the module is used, called %Tau_Relation. The keys are of the form 'x:y',
and each element of the hash is an array containing a and b. For instance:

  'CSO:450' => [25, -.011] 

where y=450, x=CSO, a=25, b=-.011, and 'CSO:450' is a key for %Tau_Relation

=cut

#------------------------------------------------------------------------------

# First define a hash which contains the current best guesses for each 
# relation. Each key is of the form x:y where x and y are opacity values in 
# the relation y = a(x + b), and each element of the hash is an array 
# containing a and b.
# The reverse relationships are calculated immediately afterwards

%Tau_Relation = (
		 'CSO:450' => [25, -.011],
		 '850:450' => [5.61, -.01],
		 'CSO:850' => [4.29, -.006],
		 'CSO:350' => [28, -.012],
		 '750:350' => [2.6, -.004],
		 'CSO:750' => [9.3, -.007],
		 'CSO:1350'=> [1.4, 0.0 ],
		 'CSO:1300'=> [1.4, 0.0 ],
		 'CSO:2000'=> [0.9, 0.0],
#		 '450:850' => [.18, .056],
#		 '350:750' => [.385, .01],
		);

# Generate inverse conversion coefficients
# Do not want to have to support a table that has entries for
# both ways

foreach my $key (keys %Tau_Relation) {
  my ($from, $to) = split(/:/, $key);
  # Calculate newkey
  my $newkey = "$to:$from";

  # If the newkey is not present in the list (probably shouldnt be)
  # calculate and store the coefficients
  unless (exists $Tau_Relation{$newkey}) {

    # Inversion of the formulae gives:
    #   a' = 1/a
    #   b' = -ab
    my $aprime = 1/ $Tau_Relation{$key}->[0];
    my $bprime = -1 * $Tau_Relation{$key}->[0] * $Tau_Relation{$key}->[1];
  
    $Tau_Relation{$newkey} = [$aprime, $bprime];
  }
}


# Now the subroutine for calculating values

sub get_tau ($$$) {

  my $name = uc($_[1]) . ':' . uc($_[0]);

  # Strip any annoying spaces of the strings
  $name =~ s/\s//g;

  # Check to see if arg 3 is defined and is a number
  # First see if source Tau value is reasonable:
  unless ( defined $_[2] && number($_[2]) && $_[2]>=0) {
    return (0,-1);
  }

  # If good parameters, find the return value of tau

  if ( exists $Tau_Relation{$name} ) {
    return $Tau_Relation{$name}[0]*($_[2] + $Tau_Relation{$name}[1]),0;
  }

  # If target Tau = source Tau, just return the value that was given

  if ($_[0] eq $_[1]) {
    return $_[2],-2;
  }

  # If we haven't returned a good value yet, the parameters are bad
  # so return -1 status.

  return (0,-1);
  
}

#------------------------------------------------------------------------------

=head2 SKY TRANSMISSION COEFFICIENT:

  ($trans450,$status) = transmission($airmass,$tau450);

=head2 Parameters

=over

=item 1.

The first parameter is the airmass.

=item 2.

The second parameter is the sky opacity at whatever wavelength is desired.

=back

=head2 Return Values

transmission returns a 2-element list. The first element is the atmospheric
transmission coefficient at whatever wavelength the sky opacity applied to. 
The second is a scalar containing the exit status of the function:

  status = 0: successful
          -1: failed 

=cut

#------------------------------------------------------------------------------

sub transmission ($$) {
  my $airmass = $_[0];
  my $tau = $_[1];

  # check validity of airmass and tau

  unless ( number($airmass) && $airmass>=1 && number($tau) && $tau>=0) {
    return (0,-1);
  }

  # Finally, return the transmission coefficient as a function of airmass and
  # zenith sky opacity

  return (exp( -$tau*$airmass),0);
}

=head2 AIRMASS CALCULATION

 ($airmass, $status) = airmass($elevation);

Calculate the airmass for a given elevation. This is a simplistic
calculation and should not be used for low elevations (airmass>2) 
- use Astro::SLA slaAirmas() for a more accurate calculation.

=head2 Parameters

=over 4

=item 1.

The first parameter is the elevation. Should be given in degrees.

=back

=head2 Return Values

airmass() returns a 2-element array. The first element is the
airmass for the given elevation. The second is the exit status
of the function:

  status = 0: successful
          -1: failed

=cut

sub airmass ($) {
  croak 'Usage: airmass($elevation)' unless scalar(@_) == 1;

  my $el = shift;

  # Check that it is a number
  unless (defined $el && number($el) && $el>0) {
    return (0,-1);
  }

  # Noddy airmass calculation
  return (1 / sin( $el * 3.141592654 / 180.0), 0);

}


# Returns true if the parameter given is a valid number

sub number ($) {
  my $num = shift;
  return 0 unless defined $num;
  $num =~ s/\s//g;  # strip spaces
  return $num =~ /^(\d+\.?\d*|\.\d+)$/;
}

#------------------------------------------------------------------------------
# End of PERL code and documentation footer.
#------------------------------------------------------------------------------
1;

=head1 NOTES

The empirical relationships are all assumed to be linear. This is valid over
most useful observing conditions, but it should be noted that 450 Tau as
returned by get_tau will be invalid for CSO Tau above 0.1 and 850 Tau
above 0.5, due to extra absorption mechanisms in the atmosphere. 

If possible, 450 Tau should be derived from 850 Tau rather than CSO Tau. The 
reason is that the relation between 450 Tau and 850 Tau is known with greater
certainty: Every time a skydip is performed by the JCMT, data is collected 
simultaneously at 450 microns and 850 microns, thus eliminating uncertainty in 
time. There is much more uncertainty when including observations by the CSO,
simply because it is a different instrument, and observations are not taken
simulatenously with the JCMT.

Although it is possible to derive 850 Tau from 450 Tau, it is not a good idea.
Measurements at 450 Microns have a high degree of uncertainty, so you are 
better off deriving from CSO Tau.

The 350 and 750 Tau ratios are only a first guess, based on roughly 20 data
points.

The 1350 and 2000 micron values are actually derived from UKT14 data.
The SCUBA skydip system is not yet reliable at these wavelengths.

=head1 AUTHOR

Module created by Edward Chapin, echapin@jach.hawaii.edu
Extended by Tim Jenness, t.jenness@jach.hawaii.edu.

=cut
