#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wvmCal.h"

MODULE = JCMT::Tau::WVM::WVMLib	   PACKAGE = JCMT::Tau::WVM::WVMLib

double
pwv2tau(airmass, pwv)
  double airmass
  double pwv


void
tsky2pwv( airmass, tamb, tsky1, tsky2, tsky3 )
  float airmass
  float tamb
  float tsky1
  float tsky2
  float tsky3
 PREINIT:
  float tsky[3];
  float waterDens;
  float tau0;
  float tWat;
 PPCODE:
  tsky[0] = tsky1;
  tsky[1] = tsky2;
  tsky[2] = tsky3;

  wvmOpt(airmass, tamb, tsky, &waterDens, &tau0, &tWat);

  /* Currently we only return the pwv since we are not sure of the
     definitions of tWat and tau0 */
  PUSHs(sv_2mortal(newSVnv( (double)waterDens)));

void
wvmOpt( airmass, tamb, tsky1, tsky2, tsky3 )
  float airmass
  float tamb
  float tsky1
  float tsky2
  float tsky3
 PREINIT:
  float tsky[3];
  float waterDens;
  float tau0;
  float tWat;
 PPCODE:
  tsky[0] = tsky1;
  tsky[1] = tsky2;
  tsky[2] = tsky3;

  wvmOpt(airmass, tamb, tsky, &waterDens, &tau0, &tWat);

  /* Currently we only return the pwv since we are not sure of the
     definitions of tWat and tau0 */
  PUSHs(sv_2mortal(newSVnv( (double)waterDens)));
  PUSHs(sv_2mortal(newSVnv( (double)tau0)));
  PUSHs(sv_2mortal(newSVnv( (double)tWat)));

