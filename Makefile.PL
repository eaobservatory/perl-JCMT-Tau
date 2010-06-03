use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::Tau',
  'VERSION_FROM' => 'lib/JCMT/Tau.pm',
  'INC' => '-Iwvm-src',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
