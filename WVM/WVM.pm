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

use Time::Piece qw/ :override /;
use Time::Seconds;
use Time::Local;

use vars qw($VERSION);

$VERSION = '0.02';

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
as a Time::Piece object.

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
      if (UNIVERSAL::can($val, "epoch")) {
	      $self->{privateStartTime} = $val;
	      #print "Set start_time to $self->{privateStartTime}->strftime()\n";
      } else {
	      croak "Must supply start time with an object that has the 'epoch' method";
      }
    } else {
      $self->{privateStartTime} = undef;
    }
  }
  return $self->{privateStartTime};
}

=item B<end_time>

Retrieve (or set) the end time associated with the WVM data stream
as a Time::Piece object.

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
      if (UNIVERSAL::can($val, "epoch")) {
	      $self->{privateEndTime} = $val;
	      #print "Set end_time to $self->{privateEndTime}->strftime()\n";
      } else {
	      croak "Must supply end time with an object that has the 'epoch' method";
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
  #Get list of files in date range andparse each one

  foreach my $file ($self->_getFiles()) {
      $numfiles++;
      #chdir "$file" or die "Could not cd to $file";
      open my $DATAFILE, "<$file"
	  or die "Couldn't open $file: $!\n";
      local $/="\n";
      while (<$DATAFILE>) {
	  $_ =~ s/^\s+//;
	  my @string = split /\s+/, $_;

	  # Convert fractional hour to an epoch
	  my $time = _getTime($string[0], $file);

	  # print "wvm_old: $string[9] airmass: $string[1]\n";

	  $wvmdata{$time} = sprintf("%6.4f", pwv2tau($string[1], $string[9]));
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

=cut

sub table {
  my $self = shift;
  my %args = @_;

  my $start = ( exists $args{start} ? $args{start}->epoch : 0 );
  my $end   = ( exists $args{end} ? $args{end}->epoch : 1e10 );

  my $data = $self->data;

  my @rows = map {
    my $t = gmtime( $_ );
    sprintf( "%f\t%f\t%s", $t->mjd, $data->{$_}, $t->datetime );
  } grep { $_ > $start && $_ < $end } sort keys %$data;

  return (wantarray ? @rows : join ("\n", @rows) );

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

=item B<_getTime>

Get the time in seconds since 1/1/1970. This crudely uses the file
name to get the day, month, and year. The timestamp of the day in
seconds is passed as the first arg and the filename is passed as
the second arg. This works for now but is kind of lame. Should
replace with Time::Piece object -> epoch.

    $epochSeconds = _getTime($floatHourOfDay, $fileName);

=cut

sub _getTime {
    my $rawTime = shift;
    my $filestr = shift;

    $filestr =~ /(\d{4})(\d{2})(\d{2}).wvm$/;

    my $day = $3;
    my $month = $2;
    my $year = $1;

    my $secsInDay = int($rawTime * 3600);
    return $secsInDay + timegm(0, 0, 0, $day, $month-1, $year); #Time in seconds since 1/1/1970
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

    my $date = $start;
    my $tp = $date->isa('Time::Piece');
    my @files;
    while ($date < $end) {
        my $ymd = $date->strftime('%Y%m%d');
	my $file = File::Spec->catfile( $self->data_root, $ymd, "$ymd.wvm");
	push @files, $file if -e $file;
	if ($tp) {
	  $date += ONE_DAY;
	} else {
	  $date->add( days => 1 );
	}

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
