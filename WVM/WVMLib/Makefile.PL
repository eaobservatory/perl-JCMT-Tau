use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'WVM',
    'VERSION_FROM' => 'WVM.pm', # finds $VERSION
    'LIBS'	=> ['-L/jac_sw/itsroot/install/wvm/lib/solaris -lwvmLib -lm '],   # e.g., '-lm' 
    'OBJECT' => "WVM.o",   #'OBJECT' => "WvmTau.o",
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '-I/jac_sw/itsroot/install/wvm/include',     # e.g., '-I/usr/include/other' 
);
