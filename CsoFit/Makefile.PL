use ExtUtils::MakeMaker;
WriteMakefile(
  'NAME'         => 'JCMT::Tau::CsoFit',
  'VERSION_FROM' => 'CsoFit.pm',
  'dist'         => { COMPRESS => "gzip -9f" }
  ); 
