use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::Tau',
  'VERSION_FROM' => 'Tau.pm',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
