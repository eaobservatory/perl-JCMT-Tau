package JCMT::Tau::WVM;

=head1 NAME

JCMT::Tau::WVM - Manipulate Water Vapor Monitor data

=head1 SYNOPSIS

  use JCMT::Tau::WVM;
  use JCMT::Tau::WVMGDGraph;

  $wvm = new JCMT::Tau::WVM( StartTime => $start,
                             EndTime   => $end);


  $gif = $wvm->graph();


=head1 DESCRIPTION

This class allows you to manipulate water vapor radiometer data.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use JCMT::Tau::WVM::WVMLib qw/ pwv2tau /;
use List::Util qw/ min max /;

use DateTime;
use DateTime::TimeZone;

use vars qw($VERSION);

$VERSION = '0.03';

my $utc;
BEGIN {
  $utc = new DateTime::TimeZone( name => 'UTC' );
}

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Object constructor. Accepts arguments to specify StartTime and
EndTime.

  $wvm = new JCMT::Tau::WVM( Start_Time => $start, end_time => $end);

If an end and start time are specified the data file will be read
during instantiation. In that case returns undef if the data could not
be read.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  # create the object
  my $wvm = bless {
		   privateStartTime => undef,
		   privateEndTime  => undef,
		   privateData     => {},
		  }, $class;

  # configure it
  # Go through the input args invoking relevant methods
  for my $key (keys %args) {
    my $method = lc($key);
    if ($wvm->can($method)) {
      $wvm->$method( $args{$key});
    }
  }

  # read the data
  if (defined $wvm->start_time && defined $wvm->end_time) {
    my $status = $wvm->read_data();
    $wvm = undef unless $status;
  }
  return $wvm;
}

=back

=head2 Accessor methods

=over 4

=item B<data>

Retrieve (or set) the data hash associated with the specified times.

=cut

sub data {
  my $self = shift;
  if (@_) {
    $self->{privateData} = shift;
  }
  return $self->{privateData};
}


=item B<start_time>

Retrieve (or set) the start time associated with the WVM data stream
as a DateTime object.

  $time = $wvm->start_time();
  $wvm->start_time( $time );

These values are not updated once data are read (they are the search bounds
for the data read not the data bounds)

=cut

sub start_time {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "DateTime")) {
	      $self->{privateStartTime} = $val;
      } else {
	      croak "Must supply start time with an 'DateTime' object not '$val'";
      }
    } else {
      $self->{privateStartTime} = undef;
    }
  }
  return $self->{privateStartTime};
}

=item B<end_time>

Retrieve (or set) the end time associated with the WVM data stream
as a DateTime object.

  $time = $wvm->end_time();
  $wvm->end_time( $time );

These values are not updated once data are read (they are the search bounds
for the data read not the data bounds)

=cut

sub end_time {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "DateTime")) {
	      $self->{privateEndTime} = $val;
      } else {
	      croak "Must supply end time with an 'DateTime' object not '$val'";
      }
    } else {
      $self->{privateEndTime} = undef;
    }
  }
  return $self->{privateEndTime};
}

=item B<tbounds>

Returns the start and end time of the stored data set (as distinct from
the start and end time of the query)

  ($tmin, $tmax) = $wvm->tbounds;

=cut

sub tbounds {
  my $self = shift;
  my $min = min( keys %{$self->data});
  my $max = max( keys %{$self->data});
  return ($min, $max);
}

=back

=head2 General Methods

=over 4

=item B<read_data>

Read the WVM data for the specified time range defined in C<start_time>
and C<end_time>

  $wvm->read_data();

Returns true if the read worked correctly and false if it failed.

=cut

sub read_data {
  my $self = shift;

  my $numfiles;
  my %wvmdata;

  my $start = $self->start_time;
  my $end   = $self->end_time;

  #Get list of files in date range and parse each one

  local $/="\n"; # make sure newline is a newline

  foreach my $file ($self->_getFiles()) {
      $numfiles++;
      #chdir "$file" or die "Could not cd to $file";
      open my $DATAFILE, "<$file"
	  or die "Couldn't open $file: $!\n";

      # Try to minimize the number of DateTime objects we need to create
      my $dt = _getBaseDT( $file );

      # we need to calculate a min and max hour that we need to extract
      # from the current file. We do not want to read the whole file
      # if we are only interested in a subset of the night.
      my ($minhr, $maxhr);
      if ($dt->ymd eq $start->ymd) {
	# should be a method for this in DateTime
	$minhr = $start->hour + ( $start->minute / 60 ) +
	         ($start->second / 3600 );
      } else {
	$minhr = 0.0;
      }
      if ($dt->ymd eq $end->ymd) {
	$maxhr = $end->hour + ( $end->minute / 60 ) +
	         ($end->second / 3600 );
      } else {
	$maxhr = 24.0;
      }

      # loop over each line
      while (<$DATAFILE>) {
	  $_ =~ s/^\s+//;
	  my @string = split /\s+/, $_;

	  # Check hour range
	  next if $string[0] < $minhr;
	  last if $string[0] > $maxhr;

	  # Convert fractional hour to an epoch
	  # by adding it to the base
	  my $time = $dt->clone->add( hours => $string[0] )->epoch;

	  # print "pwv: $string[9] airmass: $string[1]  hr: $string[0]\n";
	  my $tau = sprintf("%6.4f", pwv2tau($string[1], $string[9]));

	  # Note that we do get rounding errors when using a integer
	  # second epoch. Just average
	  if (exists $wvmdata{$time}) {
	    $wvmdata{$time} = ($tau + $wvmdata{$time}) / 2;
	  } else {
	    $wvmdata{$time} = $tau;
	  }

      }
  }

  # store the data
  $self->data(\%wvmdata);

  return 0 unless $numfiles;
  return 1;
}

=item B<table>

Returns an array of table rows. Columns are MJD, tau_225, ISO 8601 YMD.

  @rows = $wvm->table;

Two optional arguments can be supplied to control the range of data
returned.

  @rows = $wvm->table( start => $start, end => $end );

These must be objects with an epoch() method returning epoch seconds.
In scalar context returns the strings.

If the 'stdout' option is set to true, the data are sent immediately
to the default filehandle. This will save some memory if all you want to
do is print the data. In that case there is no return value.

  $wvm->table( stdout => 1 );

=cut

sub table {
  my $self = shift;
  my %args = @_;

  my $start = ( exists $args{start} ? $args{start}->epoch : 0 );
  my $end   = ( exists $args{end} ? $args{end}->epoch : 1e10 );

  my $data = $self->data;

  my $fmt = "\%f\t\%f\t\%s";
  if ($args{stdout}) {
    # print straight to STDOUT
    $fmt .= "\n";
    for my $i (sort keys %$data) {
      next unless ($i > $start && $i < $end);

      # cut and paste. Ouch
      my $t = DateTime->from_epoch ( epoch => $i, time_zone => $utc );
      printf( $fmt, $t->mjd, $data->{$i}, $t->datetime );
    }
  } else {
    my @rows = map {
      my $t = DateTime->from_epoch ( epoch => $_, time_zone => $utc );
      sprintf( $fmt, $t->mjd, $data->{$_}, $t->datetime );
    } grep { $_ > $start && $_ < $end } sort keys %$data;

    return (wantarray ? @rows : join ("\n", @rows) );
  }
}

=back

=head2 Class Methods

=over 4

=item C<data_root>

Control the base directory for obtaining data.

  $root = JCMT::Tau::WVM->data_root();
  JCMT::Tau::WVM->data_root( $newroot );

=cut

  {
    my $DATA_ROOT = "/jcmtdata/raw/wvm";
    sub data_root {
      my $self = shift;
      if (@_) {
	$DATA_ROOT = shift;
      }
      return $DATA_ROOT;
    }
  }


=back

=begin __PRIVATE__

=head1 PRIVATE FUNCTIONS AND METHODS

=over4

=item B<_getBaseDT>

Derive a base DateTime object from the filename.

  $dt = _getBaseDT( $file );

Assumes file looks like YYYYMMDD.wvm

=cut

sub _getBaseDT {
  my $file = shift;

  $file =~ /(\d{4})(\d{2})(\d{2}).wvm$/;

  my $day = $3;
  my $month = $2;
  my $year = $1;

  return DateTime->new( year => $year,
			month => $month,
			day => $day,
			time_zone => $utc
		      );
}

=item B<_getTime>

Get the time in seconds since 1/1/1970. This uses the file
name to get the day, month, and year. The decimal hours of the day
is passed as the first arg and the filename is passed as
the second arg.

    $epochSeconds = _getTime($floatHourOfDay, $fileName);

=cut

# We need a per-file cache for the root date
  {
    # but we do not want to cache every day we have read just the most
    # recent
    my $current_dt;
    my $current_file;

    sub _getTime {
      my $dechr = shift;
      my $filestr = shift;

      my $dt;
      if (defined $current_file && $current_file eq $filestr) {
	$dt = $current_dt->clone;
      } else {
	
	$filestr =~ /(\d{4})(\d{2})(\d{2}).wvm$/;

	my $day = $3;
	my $month = $2;
	my $year = $1;

	# copy into cache
	$current_file = $filestr;
	$current_dt = DateTime->new( year => $year,
				     month => $month,
				     day => $day,
				     time_zone => $utc
				   );
	$dt = $current_dt->clone;
      }

      $dt->add( hours => $dechr );
      return $dt->epoch;
    }
  }


=item B<_getFiles>

Get the list of files in current date range.

    @files = $wvm->_getFiles();

Helper method for C<read_data>.

=cut

sub _getFiles {
    my $self = shift;

    my $start = $self->start_time;
    my $end   = $self->end_time;
    my $date = $start->clone;

    my @files;
    while ($date < $end) {
        my $ymd = $date->strftime('%Y%m%d');
	my $file = File::Spec->catfile( $self->data_root, $ymd, "$ymd.wvm");
	push @files, $file if -e $file;
	$date->add( days => 1 );
    }
    return @files;
}

=back

=head1 SEE ALSO

L<JCMT::Tau::WVM::WVMLib>, L<JCMT::Tau::WVMGDGraph>

=head1 COPYRIGHT

Copyright (C) 2001-2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Tim Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>

=cut

1;
__END__
