package JCMT::Tau::WVM;

=head1 NAME

JCMT::Tau::WVM - Manipulate Water Vapor Monitor data

=head1 SYNOPSIS

  use JCMT::Tau::WVM;
  use JCMT::Tau::WVMGDGraph;

  $wvm = new JCMT::Tau::WVM( Start_Time => $start,
                             End_Time   => $end);


  @trange = $wvm->tbounds;
  @stats = $wvm->stats;

=head1 DESCRIPTION

This class allows you to manipulate water vapor radiometer data.

=cut

use 5.006;
use warnings;
use strict;
use Carp;

use JCMT::Tau::WVM::WVMLib qw/ pwv2tau_bydate /;
use List::Util qw/ min max /;
use Fcntl qw/ SEEK_SET SEEK_CUR SEEK_END /;

# WVM data are quantized at 4 decimal places
use Statistics::Descriptive::Discrete;

use DateTime;
use DateTime::TimeZone;
use DateTime::Format::ISO8601;

use vars qw($VERSION);

$VERSION = '0.04';

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

Values are returned as epoch seconds.

=cut

sub tbounds {
  my $self = shift;
  my $min = min( keys %{$self->data});
  my $max = max( keys %{$self->data});
  return ($min, $max);
}

=item B<nsamples>

Return the number of WVM samples stored within this object.

 my $ns = $wvm->nsamples;

=cut

sub nsamples {
  my $self = shift;
  return scalar keys %{ $self->data };
}


=back

=head2 General Methods

=over 4

=item B<read_data>

Read the WVM data for the specified time range defined in C<start_time>
and C<end_time>

  $wvm->read_data();

Returns true if the read worked correctly and false if it failed.
Returns false if the read worked correctly but there were no data points
in the specified range.

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

      # determine file format:
      # old: decimal number of hours
      # new: formatted time and date
      my $firstline = <$DATAFILE>;
      seek($DATAFILE, 0, SEEK_SET);
      my $newformat = $firstline =~ /^[-0-9]{10}T[:0-9]{8} /;

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

      # For cases where we are only asking for a small chunk of the
      # file, it is much more efficient to seek directly to the relevant
      # position in the file rather than reading each line
      # If we read each line the data read for a 15 minute chunk can vary
      # from 0.05 sec to 0.37 second. We can do much better than that
      # once we know that the file is linear in time.
      # Only bother if the minhr is greater than 0
      if (! $newformat) {
        _seek_to_start( $DATAFILE, $minhr ) if $minhr > 0;
      }

      # loop over each line
      my $prevhr = 0; # start low. Add 24hr if previous is higher than next
      while (<$DATAFILE>) {
	  $_ =~ s/^\s+//;
	  my @string = split /\s+/, $_;
          my ($hour, $linedt);
          if ($newformat) {
            $linedt = DateTime::Format::ISO8601->parse_datetime($string[0]);
            $hour = $linedt->hour + ($linedt->minute / 60)
                                  + ($linedt->second / 3600);
          }
          else {
            $hour = $string[0];
          }

	  # Sometimes the next value is lower than the previous value
	  # If this happens, we need to add 24 since this indicates the
	  # file has gone slightly too big. This is problematic
	  # for the general case since this value should be read from the
	  # following file
	  $hour += 24 if $hour < $prevhr;
	  $prevhr = $hour;

	  # Check hour range
	  next if $hour < $minhr;
	  last if $hour > $maxhr;

	  # Convert fractional hour to an epoch
	  # by adding it to the base
	  # we could remove the clone step if we simply added the delta
	  # from each row to the next but that would introduce rounding
	  # errors by the end of the file
          my $time;

          # We also need the MJD although really we only need this to a day accuracy
          # so it could probably be cached.
          my $mjd;
          if ($newformat) {
            # In this format we already have the datetime object.
            $time = $linedt->hires_epoch();
            $mjd = $linedt->mjd();
          }
          else {
            my $dtdelta = $dt->clone->add( hours => $hour );
            $time = $dtdelta->hires_epoch;
            $mjd = $dtdelta->mjd;
          }
	  # print "pwv: $string[9] airmass: $string[1]  hr: $string[0] time: $time [$mjd]\n";
	  my $tau = sprintf("%6.4f", pwv2tau_bydate($mjd, $string[9]));

	  # Note that we do get rounding errors when using a integer
	  # second epoch. Just average
	  if (exists $wvmdata{$time}) {
	    $wvmdata{$time} = ($tau + $wvmdata{$time}) / 2;
	  } else {
	    $wvmdata{$time} = $tau;
	  }

      }
  }

  # did we get any data?
  return 0 unless scalar keys %wvmdata;

  # store the data
  $self->data(\%wvmdata);

  return 0 unless $numfiles;
  return 1;
}

=item B<stats>

Return statistics of the WVM samples.

  ($mean, $stdev, $median, $mode) = $wvm->stats;

=cut

sub stats {
  my $self = shift;

  # We know that certain values continue to appear in the data
  # set
  my $stats = Statistics::Descriptive::Discrete->new();
  $stats->add_data( values %{ $self->data } );

  return ( $stats->mean, $stats->standard_deviation,
	   $stats->median, $stats->mode );
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

=item B<_seek_to_start>

Move the supplied filehandle read position to the correct place in the
file to begin reading data (or at least close to it) for the correct hour.

  _seek_to_start( $fh, $starthr );

Start hour is the decimal hour in the first column of the file.

=cut

sub _seek_to_start {
  my ($fh, $refhr) = @_;

  # Get the filesize
  my $fsize = -s $fh;

  # read the first line to get a starting point
  my $lowhr = _quick_read( $fh );

  # reset seek position and return immediately if that line was 
  # valid
  if ($lowhr > $refhr) {
    seek( $fh, 0, SEEK_SET );
    return;
  }

  # Read a line to get an idea at the line length
  my $line = <$fh>;
  my $len = length( $line );

  # now seek to the end - 2 lines
  seek( $fh, (-2 * $len), SEEK_END);
  my $highhr = _quick_read( $fh, 1);

  # if the high value is lower than the low value we have
  # a file that has been written over at the end with an overflow
  # UT. This usually only happens when the WVM is running over the UT
  # boundary and averaging data over that boundary.
  # Add 24 hrs to the reference if the low is greater than high and
  # if there are more than two lines in the file (we could be unlucky
  # and have high > low by a very small amount
  $highhr += 24 if ($lowhr > $highhr && int($fsize/$len) > 2);

  # return immediately (without bothering to reset the seek
  # if start hour is too new)
  return if $highhr < $refhr;

  # Now we need to iterate to the start position
  my $lowpos = 0;
  my $highpos = $fsize;

  # Number of lines difference between high and low position
  # that indicates we should stop now
  my $threshold = 10 * $len;

  # time threshold. Stop if we are within this time period (and below
  # the reference hour
  my $tthresh = 0.1; # of an hour

  # Stop if high and low are closer than threshold bytes
  while ($highpos - $lowpos > $threshold) {
    # simple average (no gradient)
    #my $newpos = int (($highpos + $lowpos) / 2 );

    # Use a simple linear fit. This should be better than simply picking
    # the middle value each time but will only iterate quickly if the
    # time stream is fairly continuous. If it is chopped into little
    # clumps this may take a while to converge
    my $newpos = int ($lowpos + ( $refhr - $lowhr) * ( $highpos - $lowpos)
                  / ( $highhr - $lowhr));

    # Move to the test position and do a test read
    seek( $fh, $newpos, SEEK_SET);
    my $hr = _quick_read( $fh, 1);

    #print "Trying position $newpos and got hr $hr [low=$lowpos hi=$highpos]\n";

    last if !defined $hr;
    last if $hr == $refhr;
    if ($hr < $refhr) {
      # check the timing threshold and abort if we are close
      last if ($refhr - $hr) < $tthresh;
      $lowpos = $newpos;
      $lowhr = $hr;
    } else {
      $highpos = $newpos;
      $highhr = $hr;
    }

  }

  # at this point $low contains the best guess position
  # rewind two lines to be safe
  seek( $fh, (-2 * $len), SEEK_CUR);
  return;
}

# reads a line from the file, strips leading space and returns
# the first column value
# Args: $fh the filehandle, $flag  0/undef = read once. 1 = read twice
# the flag allows you to flush the first line after a partial seek
# returns undef if no line could be read
sub _quick_read {
  my $fh = shift;
  my $flag = shift;
  my $line = <$fh>;
  $line = <$fh> if $flag;
  return undef unless $line;

  # look for first number
  $line =~ s/^\s+//;
  return (split /\s+/,$line, 2)[0];
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

    # Need to start with just Y M and D
    my $date = new DateTime( year => $start->year,
			     month => $start->month,
			     day => $start->day
			   );

    # if the end date starts with 00:00 then we should not bother
    # opening the file
    my $enddate = new DateTime( year => $end->year,
				month => $end->month,
				day => $end->day,
			      );
    $enddate->subtract( seconds => 1 )
      if ($end->hour == 0 && $end->minute == 0 && $end->second == 0);


    my @files;
    # Now we can loop until our ref date is greater than the end date
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
