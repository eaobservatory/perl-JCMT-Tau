use ExtUtils::MakeMaker;
use Config;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $itsroot = "/jac_sw/itsroot/install/wvm";

my $os = $Config{'osname'};
$os = 'Linux' if $os =~ /linux/i;

print "My os is: $os\n";
WriteMakefile(
    'NAME'	=> 'JCMT::Tau::WVM::WVMLib',
    'VERSION_FROM' => 'WVMLib.pm', # finds $VERSION
    'LIBS'	=> ["-L$itsroot/lib/$os -lwvmLib -lm "],   # e.g., '-lm' 
    'INC'	=> "-I$itsroot/include",     # e.g., '-I/usr/include/other' 
);
