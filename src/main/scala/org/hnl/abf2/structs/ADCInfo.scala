package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * ADCInfo
 * <p>
 * Created on May 25, 2017.
 * <p>
 *
 * @author Jason White
 */
case class ADCInfo(
  // The ADC this struct is describing.
  nADCNum: Short,

  nTelegraphEnable: Short,
  nTelegraphInstrument: Short,
  fTelegraphAdditGain: Float,
  fTelegraphFilter: Float,
  fTelegraphMembraneCap: Float,
  nTelegraphMode: Short,
  fTelegraphAccessResistance: Float,

  nADCPtoLChannelMap: Short,
  nADCSamplingSeq: Short,

  fADCProgrammableGain: Float,
  fADCDisplayAmplification: Float,
  fADCDisplayOffset: Float,
  fInstrumentScaleFactor: Float,
  fInstrumentOffset: Float,
  fSignalGain: Float,
  fSignalOffset: Float,
  fSignalLowpassFilter: Float,
  fSignalHighpassFilter: Float,

  nLowpassFilterType: Byte,
  nHighpassFilterType: Byte,
  fPostProcessLowpassFilter: Float,
  nPostProcessLowpassFilterType: Byte,
  bEnabledDuringPN: Boolean,

  nStatsChannelPolarity: Short,

  lADCChannelNameIndex: Int,
  lADCUnitsIndex: Int,

  // sUnused: Vector[Byte],         // size = 128 bytes
  )

object ADCInfo extends StructDef[ADCInfo] {

  val size = 128

  implicit val codec: Codec[ADCInfo] = {
    (
      // The ADC this struct is describing.
      /* short */ ("nADCNum" | short16L) ::

      /* short */ ("nTelegraphEnable" | short16L) ::
      /* short */ ("nTelegraphInstrument" | short16L) ::
      /* float */ ("fTelegraphAdditGain" | floatL) ::
      /* float */ ("fTelegraphFilter" | floatL) ::
      /* float */ ("fTelegraphMembraneCap" | floatL) ::
      /* short */ ("nTelegraphMode" | short16L) ::
      /* float */ ("fTelegraphAccessResistance" | floatL) ::

      /* short */ ("nADCPtoLChannelMap" | short16L) ::
      /* short */ ("nADCSamplingSeq" | short16L) ::

      /* float */ ("fADCProgrammableGain" | floatL) ::
      /* float */ ("fADCDisplayAmplification" | floatL) ::
      /* float */ ("fADCDisplayOffset" | floatL) ::
      /* float */ ("fInstrumentScaleFactor" | floatL) ::
      /* float */ ("fInstrumentOffset" | floatL) ::
      /* float */ ("fSignalGain" | floatL) ::
      /* float */ ("fSignalOffset" | floatL) ::
      /* float */ ("fSignalLowpassFilter" | floatL) ::
      /* float */ ("fSignalHighpassFilter" | floatL) ::

      /* char */ ("nLowpassFilterType" | byte) ::
      /* char */ ("nHighpassFilterType" | byte) ::
      /* float */ ("fPostProcessLowpassFilter" | floatL) ::
      /* char */ ("nPostProcessLowpassFilterType" | byte) ::
      /* bool */ ("bEnabledDuringPN" | bool(8)) ::

      /* short */ ("nStatsChannelPolarity" | short16L) ::
      /* ABFLONG */ ("lADCChannelNameIndex" | int32L) ::
      /* ABFLONG */ ("lADCUnitsIndex" | int32L) ::

      /* char[46] */ ("sUnused" | vectorOfN(provide(46), byte).unit(Vector.fill(46)(0)))
    ).as[ADCInfo]
  }
}
