use ExtUtils::MakeMaker;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $os = $Config{'osname'};
$os = 'Linux' if $os =~ /linux/i;

print "My os is: $os\n";
WriteMakefile(
    'NAME'	=> 'JCMT::Tau::WVM',
    'VERSION_FROM' => 'WVM.pm', # finds $VERSION
    'LIBS'	=> ["-L/jac_sw/itsroot/install/wvm/lib/$os -lwvmLib -lm "],   # e.g., '-lm' 
    'INC'	=> '-I/jac_sw/itsroot/install/wvm/include',     # e.g., '-I/usr/include/other' 
);
