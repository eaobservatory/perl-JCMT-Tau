#!/local/perl/bin/perl -XT

=head1 NAME

wvmsrv - SOAP server frontend for WVM archive

=cut

use 5.006;
use warnings;
use strict;

use JCMT::Tau::WVMServer;

use SOAP::Transport::HTTP;

SOAP::Transport::HTTP::CGI->dispatch_to("JCMT::Tau::WVMServer")
  ->options({compress_threshold=>500})
  ->handle;

