package JCMT::Tau::WVM;

=head1 NAME

JCMT::Tau::WVM - Manipulate Water Vapor Monitor data

=head1 SYNOPSIS

  use JCMT::Tau::WVM;

  $wvm = new JCMT::Tau::WVM( StartTime => $start,
                             EndTime   => $end);

  $gif = $wvm->graph( $filename );


=head1 DESCRIPTION

This class allows you to manipulate water vapor radiometer data including
the creation of plots.

=cut

use 5.006;
use warnings;
use strict;
use Carp;
use CGI qw(:all);
use Graph::GraphAxes;
use Graph::GraphAxesFile;
use Time::Piece;
use Time::Seconds;
use Time::Local;
use GD;

our $VERSION = '0.01';

# can override
our $DATA_DIR = "/jcmtdata/raw/wvm/";
our $maxval_on_graph=0.5;                # Upper limit on the graph

our $mm_water_to_csotau = 18.5;          # Conversion factor between
                                         # mm of water and CSO tau
                                         # equivalent (it's really
                                         # more complex than just a
                                         # constant but this will do
                                         # for now...)

our %plot_def=(xw => 500,                # Size of the plot
              yh => 300,
              xs => 60,
              xe => 20,
              ys => 25,
              ye => 50,
              );

# THESE ARE THE COEFICIENTS TO BE USED IN THE Convert SUBROUTINE

our @wvm_cso_coefs = (-0.37325545, 38.769126, -13.05137, -25.278241,
		      31.155206, -16.233469, 4.8036578, -0.86140855, 0.092759443,
		      -0.0055237545, 0.00013989644);
our @coefs_m1 = (0.038863637, -0.18578918, 0.034048884);
our @coefs_m2 = (-0.0073803229, 0.027694585, -0.010215906);
our @coefs_c = (-0.026203715, 1.1069635, 0.073422855);
our $ourLastTime = gmtime();
our $ourLastVal = 0.0;
our $running = 0;

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
		  };

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
    #    $wvm = undef unless $status;
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

=cut

sub start_time {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Time::Piece")) {
	      $self->{privateStartTime} = $val;
	      #print "Set start_time to $self->{privateStartTime}->strftime()\n";
      } else {
	      croak "Must supply start time with a Time::Piece object";
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

=cut

sub end_time {
  my $self = shift;
  if (@_) {
    my $val = shift;
    if (defined $val) {
      if (UNIVERSAL::isa($val, "Time::Piece")) {
	      $self->{privateEndTime} = $val;
	      #print "Set end_time to $self->{privateEndTime}->strftime()\n";
      } else {
	      croak "Must supply end time with a Time::Piece object";
      }
    } else {
      $self->{privateEndTime} = undef;
    }
  }
  return $self->{privateEndTime};
}


=item B<getPlotDefs>
Make available the %plot_defs hash

    $wvm -> getPlotDefs();

=cut

sub getPlotDefs {
    return \%plot_def;
}


=item B<append_data>

Given a reference to a hash of new WVM data, append
this data to the current data.

  $wvm->append_data( \%newdata );

The new hash must be in the same form as required for
the Data() method.

Generally a private method called by read_new_data().

=cut

sub append_data {
   my $self = shift;
   my $newhash = shift;
   # Note that the Data() method returns a reference to the
   # actual data so we can modify the contents
   my $old = $self->data;
   %$old = ( %$old, %$newhash );
   return;
}


=back

=head2 General Methods

=over 4

=item B<read_new_data>

Read new data at the end of the file. defined in C<StartTime>
and C<EndTime>

  $wvm->read_new_data();

Returns true if the read worked correctly and false if it failed.

=cut

sub read_new_data {
    my $self = shift;

    my %newdata;
    my @files = $self->getFiles();
    
    #print "Files are: $_ \n", for @files;
    my $file = $files[$#files];

    if (! defined $file) {
	return -1;
    }
    #print "File is: $file\n";
    #chdir  $file or die "Couldn't cd to $file";
    my $size = (-s $file);
    open DATAFILE, $file;
    seek DATAFILE, -85*2, 2;	# Read backwards 2 lines from EOF

    my $floatUTtime;
    while (<DATAFILE>) {
	$_ =~ s/^\s+//;
	my @string = split /\s+/, $_;
	$floatUTtime = $string[1];
	my $time = getTime($floatUTtime, $file);
	$newdata{$time} = Convert($string[10], $string[2]);
	$ourLastVal = $newdata{$time};
	$ourLastTime = $time;
    }

 #   if ($running) {
	my $t = gmtime($ourLastTime);
	my $fileStr = $t->ymd("");
	my $processedFile = $DATA_DIR . $fileStr . "/" . "calibrated.wvm";
	#print "My filestr = $processedFile\n";
	open FILE, ">>$processedFile";
	print FILE "$floatUTtime   $ourLastVal\n";
	close FILE;
  #  }
    #Append this new data
    $self->append_data(\%newdata);
}


=item B<setRunning>

=cut

sub setRunning {
    $running = shift;
}


=item B<getLastVal>

=cut

sub getLastVal {
    return $ourLastVal;
}


=item B<getLastTime>

=cut
sub getLastTime {
    return $ourLastTime;
}

=back

=head2 General Methods

=over 4

=item B<read_data>

Read the WVM data for the specified time range defined in C<StartTime>
and C<EndTime>

  $wvm->read_data();

Returns true if the read worked correctly and false if it failed.

=cut

sub read_data {
  my $self = shift;

  my $tempTime;
  my $nofiles;
  my %wvmdata;
  #Get list of files in date range andparse each one

  foreach my $file ($self->getFiles()) {
      $nofiles++;
      #chdir "$file" or die "Could not cd to $file";
      open my $DATAFILE, "<$file"
	  or die "Couldn't open $file";
      local $/="\n";
      while (<$DATAFILE>) {
	  $_ =~ s/^\s+//;
	  my @string = split /\s+/, $_;
	  my $time = getTime($string[1], $file);

	  $wvmdata{$time} = Convert($string[10], $string[2]);
	  $tempTime = $time;
      }
  }

  # store the data
  $self->data(\%wvmdata);

  if ($nofiles) {
      return 0;
  }

  return 1;
}


=item B<getTime>

   Get the time in seconds since 1/1/1970. This crudely uses the file
   name to get the day, month, and year. The timestamp of the day in
   seconds is passed as the first arg and the filename is passed as
   the second arg. This works for now but is kind of lame. Should
   replace with Time::Piece object -> epoch.

    $epochSeconds = $wvm -> getTime($floatHourOfDay, $fileName);
=cut 

sub getTime {
    my $rawTime = shift;
    my $filestr = shift;

    $filestr =~ /(\d{4})(\d{2})(\d{2}).wvm$/;

    my $day = $3;
    my $month = $2;
    my $year = $1;

    my $secsInDay = int($rawTime * 3600);
    return $secsInDay + timegm(0, 0, 0, $day, $month-1, $year); #Time in seconds since 1/1/1970
}


=item B<getFiles>
    Get the list of files in current date range.

    $wvm -> getFiles();
=cut

sub getFiles {
    my $self = shift;

    my $start = $self->start_time;
    my $end   = $self->end_time;

    my ($date, $date1);
    my @files;

    for ($date=$start; $date <= $end+ONE_DAY; $date += ONE_DAY) {
	my $year=$date->year;
	my $month=$date->mon;
	if ($month < 10) {
	    $month="0".$month;
	}
	my $day = $date->mday;
	my $hour = $date->hour + $date->min/60;
	if ($day < 10) {
	    $day="0".$day;
	}

	my $file = "$DATA_DIR/$year$month$day/$year$month$day.wvm";
	if (-e $file) {
	    push @files, $file;
	}
    }
    return @files;
}



=item B<graph>

Construct a graph of WVM data. Accepts a filename or a Tk canvas
object.

  $gif = $wvm->graph( $filename );
  $wvm->graph( $canvas );

If a Tk canvas is passed in all elements on the canvas are removed prior
to plotting on it.

=cut

sub graph {
  my $self = shift;
  my $arg = shift;

  my $mode = '';
  my $g_f;
  my $graph_filename;

  if (ref($arg)) {
    if (UNIVERSAL::isa($arg,"Tk::Canvas")) {
      $mode = "Tk";
      $g_f=$arg;
    } else {
      croak "Unable to determine plotting mode with arg $arg";
    }
  } else {
    $mode = "GD";
    $graph_filename=$arg;
  }

  # read the data
  my $wvmdata = $self->data;

  # Create plot here

  my %graph_info;
  #$graph_info{xstart}=$self->start_time->epoch+$self->start_time->tzoffset;
  #$graph_info{xend}=$self->end_time->epoch+$self->end_time->tzoffset;

  $graph_info{xstart}=$self->start_time->epoch;
  $graph_info{xend}=$self->end_time->epoch;

  # START THE GRAPH

  my %colours;
  if ($mode eq 'GD') {
    $g_f= new GD::Image($plot_def{xw}, $plot_def{yh});
    $colours{black} = $g_f->colorAllocate(0,0,0);
    $colours{white} = $g_f->colorAllocate(255,255,255);
  }

  unless (scalar(keys %$wvmdata) == 0) {

    # FIND THE MAX AND MIN y-VALUES IN THE REQUIRED RANGE

    my @graph_info;
    my ($maxval, $minval);
    $maxval=-1000, $minval=1000;
    my $i;
    foreach $i (sort keys %$wvmdata) {
      if ($i < $graph_info{xstart} || $i > $graph_info{xend}) {
	next;
      }
      if ($wvmdata->{$i} < $minval) {
	$minval=$wvmdata->{$i};
      }
      if ($wvmdata->{$i} > $maxval) {
	$maxval=$wvmdata->{$i};
      }
    }

    if ($maxval == $minval) {
      $maxval= $maxval + 0.1;
      $minval= $minval - 0.1;
    }

    # LIMIT THE MAXIMUM TO AVOID PROBLEMS WHEN THE ROOF IS SHUT

    if ($maxval > $maxval_on_graph) {
      $maxval=$maxval_on_graph;
    }

    $graph_info{ystart}=$minval;
    $graph_info{yend}=$maxval;
    #      $graph_info{ystart}=0.16;
    #      $graph_info{yend}=0.215;

    # PLOT THE AXES

    my %canv_def;
    if ($mode eq 'GD') {
      Graph::GraphAxesFile::DrawAxes (\%plot_def, \%graph_info, $g_f, 1, \%canv_def, \%colours);
    } else {
      $g_f->delete('all');
      Graph::GraphAxes::DrawAxes (\%plot_def, \%graph_info, $g_f, 1, \%canv_def);
    }

    my $count_points=0;
    foreach $i (sort keys %$wvmdata) {
	
	if ($i < $graph_info{xstart} || $i > $graph_info{xend}) {next}
	$count_points++;
    }
    
    # FIND THE RATIO OF POINTS TO BE PLOTED TO AVAILABLE PIXELS
      
    my $skip_points=int($count_points/($plot_def{xw}-$plot_def{xs}-$plot_def{xe}))+1;
      

    # PLOT THE DATA

    my $firstpoint=0;
    my $tempcounter=0;
    my ($timetemp,$wvmtemp);
    foreach $i (sort keys %$wvmdata) {
      if ($i < $graph_info{xstart} || $i > $graph_info{xend}) {next;} 
      if ($firstpoint == 0) {
	$timetemp=$i;
	$wvmtemp=$wvmdata->{$i};
	$firstpoint=1;
      }

      unless ($tempcounter == 0) {
	  $tempcounter++;
	  if ($tempcounter >= $skip_points) {
	      $tempcounter=0;
	  }
	  next;
      }

      #if ($i-$timetemp < 10) {
      my $toffset = $timetemp - $graph_info{xstart};
      $toffset = $toffset->seconds if UNIVERSAL::can($toffset, "seconds");
      my $ioffset = $i - $graph_info{xstart};
      $ioffset = $ioffset->seconds if UNIVERSAL::can($ioffset, "seconds");
      if ($mode eq 'GD') { 
	  $g_f -> line (
			($toffset) * $canv_def{xr} + $plot_def{xs},
			($plot_def{yh}-$plot_def{ye})-($wvmtemp-$graph_info{ystart}) * $canv_def{yr},
			($ioffset) * $canv_def{xr} + $plot_def{xs},
			($plot_def{yh}-$plot_def{ye})-($wvmdata->{$i} - $graph_info{ystart} ) * $canv_def{yr}, $colours{white}
			);
      } else {
	  $g_f -> createLine (
			      ($toffset) * $canv_def{xr} + $plot_def{xs},
			      ($plot_def{yh}-$plot_def{ye})-($wvmtemp-$graph_info{ystart}) * $canv_def{yr},
			      ($ioffset) * $canv_def{xr} + $plot_def{xs},
			      ($plot_def{yh}-$plot_def{ye})-($wvmdata->{$i} - $graph_info{ystart} ) * $canv_def{yr},
			      -fill =>"#FFF"
			      );
      }
      #}
      $timetemp=$i;
      $wvmtemp=$wvmdata->{$i};

      $tempcounter++;
      if ($tempcounter >= $skip_points) {$tempcounter=0}
      
    }
  } else {
    if ($mode eq 'GD') {
      $g_f -> string(gdLargeFont, 10,10, "No WVM data was found for this date range", $colours{white});
    } else {
      $g_f -> createText (10, 10, text => "No WVM data was found for this date range", -fill => "#fff");
    }
  }


  # BIND THE MOUSE BUTTON TO DRAW RECTANGLES IN GRAPH

  #$g_f -> Tk::bind ("<Button-1>", [DrawRect(), Ev('x'), Ev('y'), $plot_def, $canv_def, $graph_info, $range, $wvmdata,"1", $scalevalue]);


  # WRITE A FILE TO DISK IF APPROPRIATE

  #   print "mode $mode file $graph_filename\n";
  if ($mode eq 'GD' && $graph_filename eq 'web') {
    print header(-type=>'image/gif');
    binmode STDOUT;
    print $g_f->png;
  } elsif ($mode eq 'GD' && $graph_filename =~ /\w+/) {
    open GRAPH, ">$graph_filename";
    binmode GRAPH; 

    print GRAPH $g_f->png;

    close GRAPH;
    chmod 0666, $graph_filename;
  }

  return $g_f;
}


# #*******************************************************************************************

# sub DrawRect {
#     my ($gptr_f, $x, $y, $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue);
#     ($gptr_f, $x, $y, $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue) = @_;

#     $x=$gptr_f -> canvasx($x);
#     $y=$gptr_f -> canvasy($y);

#     # NOTE THE STARTING POSITION (DON'T LET IT BE OUTSIDE THE GRAPH)

#     if ($x < $plot_def->{xs}) {$x=$plot_def->{xs}}
#     if ($y > $plot_def->{yh}-$plot_def->{ye}) {$y=$plot_def->{yh}-$plot_def->{ye}}
#     if ($x > $plot_def->{xw}-$plot_def->{xe}) {$x=$plot_def->{xw}-$plot_def->{xe}}
#     if ($y < $plot_def->{ys}) {$y=$plot_def->{ys}}

#     my $startx=$x;
#     my $starty=$y;

#     # CREATE THE RECTANGLE

#     $gptr_f -> createRectangle ($x, $y, $x, $y, -tag => "rect", -outline => "#fff");

#     # CREATE THE MOVEMENT AND FINISH BINDINGS

#     $gptr_f -> Tk::bind ("<Motion>", [ChangeSize(), Ev('x'), Ev('y'), $startx, $starty, 0,$plot_def,
# 				      $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue]);

#     $gptr_f -> Tk::bind ("<ButtonRelease-1>", [ChangeSize(), Ev('x'), Ev('y'), $startx, $starty, 1,
# 					       $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue]);
# }
   
# #*******************************************************************************************
# =item B<ChangeSize>
    
# # RESIZE THE RECTANGLE AS THE MOUSE MOVES
# =cut

# sub ChangeSize {

#     my ($gptr_f, $x, $y,$startx, $starty, $flag, $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue)=@_;

#     $x=$gptr_f -> canvasx($x);
#     $y=$gptr_f -> canvasy($y);

#     # DON'T LET THE BOX GROW OUTSIDE THE GRAPH

#     if ($x < $plot_def->{xs}) {$x=$plot_def->{xs}}
#     if ($y > $plot_def->{yh}-$plot_def->{ye}) {$y=$plot_def->{yh}-$plot_def->{ye}}
#     if ($x > $plot_def->{xw}-$plot_def->{xe}) {$x=$plot_def->{xw}-$plot_def->{xe}}
#     if ($y < $plot_def->{ys}) {$y=$plot_def->{ys}}

#     $gptr_f -> coords("rect", $startx, $starty, $x, $y);

#     # IF THE MOUSE BUTTON WAS RELEASED WE'VE FINISHED

#     if ($flag) {
# 	$gptr_f -> Tk::bind ("<ButtonRelease-1>", "");
# 	$gptr_f -> Tk::bind ("<Motion>", "");
# 	$gptr_f -> Tk::bind ("<Button-1>", [TestForReRun() ,$startx, $starty, $x, $y, Ev('x'), Ev('y'), $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue]);
#     }

# }


# =item B<TestForReRun>

# CHECK TO SEE IF WINDOW SHOULD BE REDRAWN OR JUST THE RECTANGLE DESTROYED

# =cut

# sub TestForReRun  {

#     my ($gptr_f, $startx, $starty, $x, $y, $x2, $y2, $plot_def, $canv_def, $graph_info, $range, $wvmdata, $sub, $scalevalue)=@_;
#     my $temp;

#     $x2=$gptr_f -> canvasx($x2);
#     $y2=$gptr_f -> canvasy($y2);

#     # SWAP THE X VALUES (& Y VALUES) IF NECESSARY So START VALUE IS ALWAYS THE SMALLER
#     # (COVERS THE CASE WHEN THE BOX IS DRAW FROM RIGHT TO LEFT)

#     if ($startx > $x) {
# 	$temp=$x;
# 	$x=$startx;
# 	$startx=$temp;
#     }
#     if ($starty > $y) {
# 	$temp=$y;
# 	$y=$starty;
# 	$starty=$temp;
#     }      

#     # WAS THE POINT CLICKED ON WITHIN THE BOX?

#     if ($x2 < $x && $x2 > $startx && $y2 < $y && $y2 > $starty) {
# 	my ($xstart, $ystart, $xend, $yend);
# 	$xstart=($startx-$plot_def->{xs})/$canv_def->{xr}+$graph_info->{xstart};
# 	$xend=($x-$plot_def->{xs})/$canv_def->{xr}+$graph_info->{xstart};
# 	$yend=($plot_def->{yh}-$plot_def->{ye}-$starty)/$canv_def->{yr}+$graph_info->{ystart};
# 	$ystart=($plot_def->{yh}-$plot_def->{ye}-$y)/$canv_def->{yr}+$graph_info->{ystart};
# 	$gptr_f -> delete ("rect");

# 	$graph_info->{xstart}=$xstart;
# 	$graph_info->{xend}=$xend;
# 	$graph_info->{ystart}=$ystart;
# 	$graph_info->{yend}=$yend;

# 	# YES, IT WAS IN THE BOX SO REDRAW THE GRAPH

# 	if ($sub == 1) {
#             &ReadData ("-1", $graph_info, $canv_def, $plot_def, $range, $wvmdata);
#             &DrawGraph (\%graph_info, \%canv_def, \%plot_def, $range, $wvmdata, $scalevalue, "-1");
# 	} elsif ($sub == 2) {
#             &ReadData ("-1", $graph_info, $canv_def, $plot_def, $range, $wvmdata);
#             &DrawGraph (\%graph_info, \%canv_def, \%plot_def, $range, $wvmdata, $scalevalue, "-1");
# 	}

# # IT WAS OUTSIDE THE BOX SO JUST DESTROY THE BOX (AND RESTORE THE ORIGINAL BINDING)

#     } else {
# 	$gptr_f -> delete ("rect");
# 	$gptr_f -> Tk::bind ("<Button-1>", [DrawRect(), Ev('x'), Ev('y'), $plot_def, $canv_def, 
# 					    $graph_info, $range, $wvmdata, $sub, $scalevalue]);
#     }
# }



=item B<Convert>
Apply the conversion to scale from mmH20 vapor into tau225

    $result = $wvm -> Convert($mmH20, $airmass);

=cut

sub Convert {

  # ACCEPTS AS INPUT A READING FROM THE WVM IN mm AND AND AIRMASS
  # RETURNS A WVM READING IN "CSO TAU225 EQUIVALENT" UNITS, CORRECTED FOR AIRMASS

  my ($wvm_old, $airmass) = @_;

  # UNCOMMENT THIS LINE TO HAVE NO CORRECTIONS APPLIED  (OTHER THAN /18.5)
  #      return $wvm_old/18.5;

  # APPLY THE AIRMASS CORRECTION (LINEAR MODE)

  #      my $const_m =-0.020508261*$string[10]**2+0.010012658*$string[10]-0.0025479443;
  #      my $const_c =0.048897956*$string[10]**2+0.84595076*$string[10]+0.14592531;
  #      my $correction = ($const_m+$const_c)-($const_m*$air_mass+$const_c);
  #      $wvm_temp=$wvm_old+$correction;

  # APPLY THE AIRMASS CORRECTION (POLYNOMIAL MODE)

  my $const_m2 = $coefs_m2[0] * $wvm_old**2 + $coefs_m2[1] *$wvm_old + $coefs_m2[2];
  my $const_m1  = $coefs_m1[0]  *$wvm_old**2 + $coefs_m1[1]  *$wvm_old + $coefs_m1[2];
  my $const_c  = $coefs_c[0]  *$wvm_old**2 + $coefs_c[1]  *$wvm_old + $coefs_m1[2];
  my $correction = ($const_m2+$const_m1+$const_c)-($const_m2*$airmass**2+$const_m1*$airmass+$const_c);

  my $wvm_temp = $wvm_old + $correction;

  # APPLY THE CSO TAU CONVERSION

  my $j;
  my $mult=0;
  for ($j=0; $j<=$#wvm_cso_coefs; $j++) {
    $mult += $wvm_cso_coefs[$j]*$wvm_temp**($j);
  }

  my $wvm_new = $wvm_temp/$mult;

  # RETURN THE CORRECTED AND CONVERTED WVM VALUE

  return $wvm_new;
}

=back

=head1 NOTES

The data directory can be overidden by setting $JCMT::Tau::WVM::DATA_DIR.

=head1 COPYRIGHT

Copyright (C) 2001-2002 Particle Physics and Astronomy Research Council.
All Rights Reserved.

=head1 AUTHORS

Robin Phillips E<lt>r.phillips@jach.hawaii.eduE<gt>.

Translated into the JCMT::Tau::WVM module by Tim
Jenness E<lt>t.jenness@jach.hawaii.eduE<gt>.

=cut

    1;
