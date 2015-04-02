use strict;
use warnings;
use File::Spec;
use Module::Build;

my $file = File::Spec->catfile( "lib", "JCMT", "Tau.pm" );

my $build = Module::Build->new
  (
   module_name => "JCMT::Tau",
   abstract_from => $file,
   license => "gpl",
   author => [
              'Tim Jenness <tjenness@cpan.org>',
             ],
   dist_version => '1.11',
   meta_merge => {
               resources =>  {
                              repository => "git://github.com/eaobservatory/perl-JCMT-Tau.git",
                             },
                },
   requires => {
                "DateTime" => 0,
                "DateTime::TimeZone" => 0,
                "DateTime::Format::Strptime" => 0,
                "DateTime::Format::ISO8601" => 0,
                "Statistics::Descriptive::Discrete" => 0,
               },
   recommends => {
                  "SOAP::Lite" => 0,
                  "GD::Graph" => 0,
                 },
   build_requires => {
                      "Test::More" => 0,
                     },
   c_source => [ "wvm-src" ],
  );

$build->create_build_script;

