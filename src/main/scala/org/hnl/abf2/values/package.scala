package org.hnl.abf2

/**
 * values
 * <p>
 * Created on May 31, 2017.
 * <p>
 *
 * @author Jason White
 */
package object values {
  val ABF_ADCCOUNT = 16 // number of ADC channels supported.
  val ABF_DACCOUNT = 4 // number of DAC channels supported.
  val ABF_EPOCHCOUNT = 10 // number of waveform epochs supported.
  val ABF_ADCUNITLEN = 8 // length of ADC units strings
  val ABF_ADCNAMELEN_USER = 8 // length of user-entered ADC channel name strings
  val ABF_ADCNAMELEN = 10 // length of actual ADC channel name strings
  val ABF_DACUNITLEN = 8 // length of DAC units strings
  val ABF_DACNAMELEN = 10 // length of DAC channel name strings
  val ABF_USERLISTLEN = 256 // length of the user list (V1.6)
  val ABF_USERLISTCOUNT = 4 // number of independent user lists (V1.6)
  val ABF_OLDFILECOMMENTLEN = 56 // length of file comment string (pre V1.6)
  val ABF_FILECOMMENTLEN = 128 // length of file comment string (V1.6)
  val ABF_PATHLEN = 256 // length of full path, used for DACFile and Protocol name.
  val ABF_CREATORINFOLEN = 16 // length of file creator info string
  val ABF_ARITHMETICOPLEN = 2 // length of the Arithmetic operator field
  val ABF_ARITHMETICUNITSLEN = 8 // length of arithmetic units string
  val ABF_TAGCOMMENTLEN = 56 // length of tag comment string
  val ABF_BLOCKSIZE = 512 // Size of block alignment in ABF files.
  val PCLAMP6_MAXSWEEPLENGTH = 16384 // Maximum multiplexed sweep length supported by pCLAMP6 apps.
  val PCLAMP7_MAXSWEEPLEN_PERCHAN = 1032258 // Maximum per channel sweep length supported by pCLAMP7 apps.
  val ABF_MAX_SWEEPS_PER_AVERAGE = 65500 // The maximum number of sweeps that can be combined into a
  // cumulative average (nAverageAlgorithm=ABF_INFINITEAVERAGE).
  val ABF_MAX_TRIAL_SAMPLES = 0x7FFFFFFF // Maximum length of acquisition supported (samples)
  // INT_MAX is used instead of UINT_MAX because of the signed
  // values in the ABF header.

  val ABF_WORDSIZE = 8
  val ABF_BLOCKBYTES = ABF_BLOCKSIZE * ABF_WORDSIZE
}
