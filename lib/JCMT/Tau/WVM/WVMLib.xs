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
  float rms;
 PPCODE:
  tsky[0] = tsky1;
  tsky[1] = tsky2;
  tsky[2] = tsky3;

  wvmOpt(airmass, tamb, tsky, &waterDens, &tau0, &tWat, &rms);

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
  float rms;
 PPCODE:
  tsky[0] = tsky1;
  tsky[1] = tsky2;
  tsky[2] = tsky3;

  wvmOpt(airmass, tamb, tsky, &waterDens, &tau0, &tWat, &rms);

  PUSHs(sv_2mortal(newSVnv( (double)waterDens)));
  PUSHs(sv_2mortal(newSVnv( (double)tau0)));
  PUSHs(sv_2mortal(newSVnv( (double)tWat)));
  PUSHs(sv_2mortal(newSVnv( (double)rms)));


void
wvmOptMulti( airmass, tamb, tskys )
  float *airmass
  float *tamb
  float *tskys
 PREINIT:
  float waterDens;
  float tau0;
  float tWat;
  float waterDensErr;
  float tau0Err;
  float tWatErr;
  float rms;
  int n;
 PPCODE:

  n = av_len((AV*)SvRV(ST(0))) + 1;

  wvmOptMulti(n, airmass, tamb, tskys, &waterDens, &tau0, &tWat,
          &waterDensErr, &tau0Err, &tWatErr, &rms);

  /* Currently we only return the pwv since we are not sure of the
     definitions of tWat and tau0 */
  PUSHs(sv_2mortal(newSVnv( (double)waterDens)));
  PUSHs(sv_2mortal(newSVnv( (double)tau0)));
  PUSHs(sv_2mortal(newSVnv( (double)tWat)));
  PUSHs(sv_2mortal(newSVnv( (double)waterDensErr)));
  PUSHs(sv_2mortal(newSVnv( (double)tau0Err)));
  PUSHs(sv_2mortal(newSVnv( (double)tWatErr)));
  PUSHs(sv_2mortal(newSVnv( (double)rms)));


void
wvmEst( airmass, pwvlos, twat, tau0 )
  double airmass
  double pwvlos
  double twat
  double tau0
 PREINIT:
  double TBRI[3];
  double TTAU[3];
  double TEFF[3];
  double AEFF[3];
  AV * pTBRI;
  AV * pTTAU;
  AV * pTEFF;
  AV * pAEFF;
 PPCODE:
  wvmEst( airmass, pwvlos, twat, tau0,
          TBRI, TTAU, TEFF, AEFF );


  pTBRI = newAV();
  unpack1D( newRV_noinc((SV*)pTBRI), TBRI, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pTBRI));

  pTTAU = newAV();
  unpack1D( newRV_noinc((SV*)pTTAU), TTAU, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pTTAU));

  pTEFF = newAV();
  unpack1D( newRV_noinc((SV*)pTEFF), TEFF, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pTEFF));

  pAEFF = newAV();
  unpack1D( newRV_noinc((SV*)pAEFF), AEFF, 'd', 3 );
  XPUSHs( newRV_noinc((SV*)pAEFF));

