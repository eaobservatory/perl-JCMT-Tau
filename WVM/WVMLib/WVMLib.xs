#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wvmCal.h"

MODULE = WVM		PACKAGE = WVM		

double
pwv2tau(airmass, pwv)
		 double airmass
		 double	pwv
