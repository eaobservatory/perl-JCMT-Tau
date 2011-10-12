#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "wvmCal.h"

#include "arrays.h"

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

void
wvmEst( airmass, pwvlos, twat, tau0 )
  float airmass
  float pwvlos
  float twat
  float tau0
 PREINIT:
  float TBRI[3];
  float TTAU[3];
  float TEFF[3];
  float AEFF[3];
  AV * pTBRI;
  AV * pTTAU;
  AV * pTEFF;
  AV * pAEFF;
 PPCODE:
  wvmEst( airmass, pwvlos, twat, tau0,
          TBRI, TTAU, TEFF, AEFF );


  pTBRI = newAV();
  unpack1D( newRV_noinc((SV*)pTBRI), TBRI, 'f', 3 );
  XPUSHs( newRV_noinc((SV*)pTBRI));

  pTTAU = newAV();
  unpack1D( newRV_noinc((SV*)pTTAU), TTAU, 'f', 3 );
  XPUSHs( newRV_noinc((SV*)pTTAU));

  pTEFF = newAV();
  unpack1D( newRV_noinc((SV*)pTEFF), TEFF, 'f', 3 );
  XPUSHs( newRV_noinc((SV*)pTEFF));

  pAEFF = newAV();
  unpack1D( newRV_noinc((SV*)pAEFF), AEFF, 'f', 3 );
  XPUSHs( newRV_noinc((SV*)pAEFF));

