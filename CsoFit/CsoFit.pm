package JCMT::Tau::CsoFit;

=head1 NAME

JCMT::Tau::CsoFit - Process fits to CSO data

=head1 SYNOPSIS

 use JCMT::Tau::CsoFit;

 # Read in a file of tau fits
 $fit = new JCMT::Tau::CsoFit( $filename );

 # Get data for a specific night
 $night = $fit->get( 19990523 );

 # Get the tau for a specific time
 $csotau = $night->tau( 19990523.435 );

 # (over)Write a night of fits
 $fit->put( $night );  # Not yet implemented

 # Request expanded fit data spread over 100 points
 ($points, $times ) = $night->expand( 100 );

=cut

use strict;
use Carp;
use IO::File;

use vars qw/ $VERSION /;
$VERSION = "0.10";


=head1 DESCRIPTION

This module provides an interface for manipulating and reading
a file containing fits to the CSO tau data.

=head1 METHODS

=over 4

=item B<new>

Open the file containing the fits and read it in to the
returned object.

    $fit = new JCMT::Tau::CsoFit( $filename );

If the file does not exist, it will be created when the
data are written.

=cut

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    # Should be a filename specified
    return undef unless @_;

    my $filename = shift;

    my $obj = bless {}, $class;
    $obj->filename( $filename );
    return $obj;

}


=item B<filename>

Returns the filename currently associated with the object.

  $filename = $fit->filename;

If a filename is supplied (and no value has been set previously) the
contents of the file are automatically read into the object using
the C<readfits> method.

=cut

sub filename {
    my $self = shift;
    if (@_) {
	my $slurp = (defined $self->{File} ? 0 : 1);
	$self->{File} = shift;
	$self->readfits if $slurp;
    }
    return $self->{File};
}

=item B<add>

Add a new fit:

  $fit->add( $remove_overlap, $ut, $start, $end, [ @coeffs ],
             $eps, $stdev, $clip, $ymin, $ymax );

The first parameter is used to control how overlap regions are
handled.  If true, any previous fits that overlap the range of the
current fit are removed. If false, the current fit is stored in
addition to the previous fits.

Returns 1 if succesfull, C<undef> on failure.

=cut

sub add {
    my $self = shift;
    return undef unless $#_ == 9;

    # Create a new Fit object
    my $fit = JCMT::Tau::CsoFit::Fit->new();
    my ($rem, $ut, $start, $end, $coeffs, $eps, $stdev, $clip, $ymin, $ymax) = @_;

    $fit->{Label} = $ut;
    $fit->{Start} = $start;
    $fit->{End}   = $end;
    $fit->{Coeffs}= $coeffs;

    $self->{Epsilon}= $eps;
    $self->{SD}     = $stdev;
    $self->{Clip}   = $clip;
    $self->{YMin}   = $ymin;
    $self->{Ymax}   = $ymax;

    # Loop through the current entries looking for overlap
    # Start by retrieving the parameters for that night
    if (exists $self->{Data}->{$ut}) {
	my $ref = $self->{Data}->{$ut}; # simplify the code

	if ($rem) {

	    # Loop over each of the objects in the array
	    # Need to keep track of the index so the element can
	    # be removed
	    for my $i (0.. $#{ $ref } ) {
		
		my $part = $ref->[$i];

		# Check the start and end time
		if (($start > $part->start_time() &&
		     $start < $part->end_time()) ||
		    ($end > $part->start_time() &&
		     $end < $part->end_time() )
		   ) {

		    # remove it
		    splice(@{$ref}, $i,1);

		}

	    }

	}

    } else {
	# Create an array for this ut
	$self->{Data}->{$ut} = [];
    }

    # Store the fit
    push(@{$self->{Data}->{$ut}}, $fit);


    return 1;
}


=item B<readfits>

Forces the object to read (or reread) all the fits from disk
and in to memory. This method is invoked automatically the
first time if the C<new> method is called with an argument.
or when the C<filename> is modified.

Returns undef if an error occured.

=cut


sub readfits {
    my $self = shift;

    # Open the file
    my $file = $self->filename;
    my $io = new IO::File("< $file");
    return undef unless defined $io;

    # Somewhere to store the data
    my %data;

    # Read the file in a line at a time
    while (defined( my $line =<$io>)) {

	# Construct an object based on the information in this string
	my $night = JCMT::Tau::CsoFit::Fit->new( $line );
	next unless defined $night;
	my $ut = $night->label;
	next unless defined $ut;

	# Store this hash in a hash indexed by UTdate
	# that contains an array of these night hashes
	if (exists $data{ $ut }) {
	    push( @{ $data{ $ut } }, $night);
	} else {
	    $data{ $ut } = [ $night ];
	}

    }

    # Store the hash containing all the data in the object
    $self->{Data} = \%data;

    close($io) or croak "Error closing $file\n";

}

=item B<store>

Write the current fit data to disk. The filename is read from the object.

  $fit->store;

Returns 1 if successful, C<undef> otherwise.

=cut

sub store {
    my $self = shift;
    my $file = $self->filename;

    # Try opening the file for write
    unlink $file;
    my $io = new IO::File("> $file");

    if (defined $io) {

	# Loop through all the data keys
	foreach my $ut (keys %{$self->{Data}}) {

	    # Loop through all the sub fits
	    foreach my $fit (@{ $self->{Data}->{$ut} }) {

		# Get the freeze form of the data
		my $str = $fit->freeze;
		print $io "$str\n" or croak "Error writing to disk\n";

	    }

	}


    } else {
	return undef;
    }


    return 1;
}



=item B<tau>

Retrieve the tau for a specifc ut date and time. The time should
be given in C<YYYYMMDD.frac> format.

  $csotau = $fit->tau( 19990815.435 );

Returns C<undef> if no value could be determined.

=cut

sub tau {
    my $self = shift;
    my $time = shift;

    # Get the UT and the fraction
    my $ut = int($time);
    my $frac = $time - $ut;

    # Start by retrieving the parameters for that night
    if (exists $self->{Data}->{$ut}) {

	# Loop over each of the objects in the array
	for my $part (@{ $self->{Data}->{$ut} } ) {

	    # Calculate the tau value
	    my $tau = $part->calc($frac);

	    # Return it if good
	    return $tau if defined $tau;
	}

    }

    # Only get here if we failed
    return undef;

}

=item B<expand>

Return times and tau values spread evenly throughout the selected night.

  @expansion = $fit->expand( 19990815, $n );

The number of points per segment is specified using $n.
The return array has elements of the following structure:

  [
    [ @x ], [ @y ]
  ]

That is, an array of references to arrays of references to the x and
y coordinates of the expansion.

The number of elements in the array indicates the number of sub fits
required to correctly match the tau variation.

Returns C<undef> if no fits exist for the specified night.

=cut

sub expand {
    my $self = shift;
    my $ut = shift;
    my $n = shift;

    # Check that this night has a fit
    return undef unless exists $self->{Data}->{$ut};

    # Loop over each of the objects in the array
    my @results;
    for my $part (@{ $self->{Data}->{$ut} } ) {
	# Calculate the tau value
	my ($xref, $yref) = $part->expand($n);
	push(@results, [ $xref, $yref]);
    }

    return @results;
}


=item B<get>

Retrieve the fit objects associated with a specific UT date.

  @fits = $fit->get( 19990515 );

=cut

sub get {
    my $self = shift;
    my $ut = shift;

    if (exists $self->{Data}->{$ut}) {
	return @{ $self->{Data}->{$ut}};
    }
    return ();
}

=back

=head1 AUTHOR

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

Copyright (C) 2000 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=cut


package JCMT::Tau::CsoFit::Fit;

=begin __PRIVATE__

=head1 NAME

JCMT::Tau::CsoFit::Fit - Process individual fits

=head1 SYNOPSIS

    $night = new JCMT::Tau::CsoFit::Fit(
					Coeffs => [ ],
					Start  => $start,
					End    => $end,
				       );

=head1 DESCRIPTION

Class to process single fits to the CSO tau data. The important
information required by the class is:

=over 4

=item Coeffs

Reference to an array containing the polynomial coefficients.

=item Start

Start of the valid range for the polynomial.

=item End

End of the valid range for the polynomial.

=back

=head1 METHODS

The following methods are provided:

=over 4

=item B<new>

Constructor. Requires a hash with keys C<Coeffs>, C<Start>
and C<End>

Returns undef on error.

=cut

# Internal package dealing with an individual fit rather than
# a collection of fits

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $obj = bless {}, $class;
    if (@_) {
	$obj->thaw($_[0])
	    or return undef;
    }

    return $obj;
}

=item B<start_time>

Retrieve (or set) the valid start time of the fit.

=cut

sub start_time {
    my $self = shift;
    if (@_) { $self->{Start} = shift; }
    return $self->{Start};
}

=item B<end_time>

Retrieve (or set) the valid end time of the fit.

=cut

sub end_time {
    my $self = shift;
    if (@_) { $self->{End} = shift; }
    return $self->{End};
}

=item B<end_time>

Retrieve (or set) the valid end time of the fit.

=cut

sub label {
    my $self = shift;
    if (@_) { $self->{Label} = shift; }
    return $self->{Label};
}



=item C<thaw>

Takes a string (previously frozen with the C<freeze> method) and
populates the object state with it.

  $night->thaw( $string );

Called automatically by the new method.

Returns 1 if successful; C<undef> on error.

=cut

sub thaw {
    my $self = shift;

    # Split the string into an array
    my $line = shift;
    my @bits = split(/\s+/, $line);

    # Check that the array is the right size
    # Need to do this in two stages
    return undef if $#bits < 4;
    return undef if $#bits < ($bits[3]+4);

    # Read out the bits we are interested in
    $self->{Coeffs} = [ @bits[4..(4+$bits[3])] ];
    $self->{Start}  = $bits[1];
    $self->{End}    = $bits[2];
    $self->{Label}  = $bits[0];  # UT date
    my $offset = 1 + 4 + $bits[3];

    $self->{Epsilon}= $bits[$offset];
    $self->{SD}     = $bits[$offset+1];
    $self->{Clip}   = $bits[$offset+2];
    $self->{YMin}   = $bits[$offset+3];
    $self->{Ymax}   = $bits[$offset+4];

    # looks okay
    return 1;
}


=item C<freeze>

Convert the object to a string suitable for storing to disk.

  $string = $night->freeze;

=cut

sub freeze {
    my $self = shift;
    my @data = (
		$self->{Label},
		$self->{Start},
		$self->{End},
		$#{ $self->{Coeffs} },
		@{ $self->{Coeffs} },
		$self->{Epsilon},
		$self->{SD},
		$self->{Clip},
		$self->{YMin},
		$self->{Ymax},
	       );

    return join(" ", @data);
}

=item B<calc>

Calculate the fitted value for a specified x coordinate

  $value = $night->calc( 0.25 );

Returns C<undef> if the time is out of range.

=cut

sub calc {
    my $self = shift;
    my $frac = shift;

    # Check range
    return undef if ($frac < $self->start_time() || $frac > $self->end_time);

    # Calculate the result
    my $val = 0;
    my $n = 0;
    for my $c ( @{ $self->{Coeffs} } ) {
	$val += $c * $frac**$n;
	$n++; # could n++ on previous line
    }
    return $val;
}


=item B<expand>

Translate the fit coefficients into an array of calculated values
for times spread evenly through the valid range.

  ($xref, $yref) = $night->expand( $n );

Where C<$n> is the number of points to use and xref and yref are references to
arrays of the x coordinates and the y coordinates.

=cut

sub expand {
    my $self = shift;
    my $n = shift;

    my $xrange = $self->end_time() - $self->start_time();
    my (@x, @y);
    for my $i (1..$n) {
	my $xval = $self->start_time() + ( $i/$n * $xrange );
	my $yval = $self->calc( $xval );
	if (defined $yval) {
	    push(@x, $xval);
	    push(@y, $yval);
	}
    }
    return (\@x, \@y);
}


=back

=end __PRIVATE__

=cut



1;
