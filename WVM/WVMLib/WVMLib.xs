#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wvmCal.h"

MODULE = JCMT::Tau::WVM		PACKAGE = JCMT::Tau::WVM		

double
pwv2tau(airmass, pwv)
		 double airmass
		 double	pwv
