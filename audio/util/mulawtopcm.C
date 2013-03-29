#include <iostream.h>

/*
** This routine converts from ulaw to 16 bit linear.
**
** Craig Reese: IDA/Supercomputing Research Center
** 29 September 1989
**
** References:
** 1) CCITT Recommendation G.711  (very difficult to follow)
** 2) MIL-STD-188-113,"Interoperability and Performance Standards
**     for Analog-to_Digital Conversion Techniques,"
**     17 February 1987
**
** Input: 8 bit ulaw sample
** Output: signed 16 bit linear sample
*/

short
ulaw2linear(unsigned char ulawbyte)
{
  static short exp_lut[8] = {0,132,396,924,1980,4092,8316,16764};
  short sign, exponent, mantissa, sample;

  ulawbyte = ~ulawbyte;
  sign = (ulawbyte & 0x80);
  exponent = (ulawbyte >> 4) & 0x07;
  mantissa = ulawbyte & 0x0F;
  sample = exp_lut[exponent] + (mantissa << (exponent + 3));
  if (sign != 0) sample = -sample;

  cout << "sign " << sign << " exponent " << exponent
       << " exp_lut[exp] " << exp_lut[exponent]
       << " mantissa " << mantissa << endl;
  return(sample);
}

main (void)
{
  short	x;
  short pcm;
  
  while (cin >> x) {
    unsigned char ulaw = (unsigned char) x;
    pcm = ulaw2linear(ulaw);
    cout << "mu-law " << x << "/" << hex << x << dec <<
      " -> decimal " << pcm << "/" << hex << pcm << dec << endl;
  }
}

