use ExtUtils::MakeMaker;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'JCMT::Tau::WVM',
    'VERSION_FROM' => 'WVM.pm', # finds $VERSION
);
