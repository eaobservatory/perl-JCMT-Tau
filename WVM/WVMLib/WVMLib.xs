#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wvmCal.h"

MODULE = JCMT::Tau::WVM::WVMLib	   PACKAGE = JCMT::Tau::WVM::WVMLib

double
pwv2tau(airmass, pwv)
  double airmass
  double pwv
