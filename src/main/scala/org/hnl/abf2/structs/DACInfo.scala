package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * DACInfo
 * <p>
 * Created on May 25, 2017.
 * <p>
 *
 * @author Jason White
 */
case class DACInfo(
  // The DAC this struct is describing.
  nDACNum: Short,

  nTelegraphDACScaleFactorEnable: Short,
  fInstrumentHoldingLevel: Float,

  fDACScaleFactor: Float,
  fDACHoldingLevel: Float,
  fDACCalibrationFactor: Float,
  fDACCalibrationOffset: Float,

  lDACChannelNameIndex: Int,
  lDACChannelUnitsIndex: Int,

  lDACFilePtr: Int,
  lDACFileNumEpisodes: Int,

  nWaveformEnable: Short,
  nWaveformSource: Short,
  nInterEpisodeLevel: Short,

  fDACFileScale: Float,
  fDACFileOffset: Float,
  lDACFileEpisodeNum: Int,
  nDACFileADCNum: Short,

  nConditEnable: Short,
  lConditNumPulses: Int,
  fBaselineDuration: Float,
  fBaselineLevel: Float,
  fStepDuration: Float,
  fStepLevel: Float,
  fPostTrainPeriod: Float,
  fPostTrainLevel: Float,
  nMembTestEnable: Short,

  nLeakSubtractType: Short,
  nPNPolarity: Short,
  fPNHoldingLevel: Float,
  nPNNumADCChannels: Short,
  nPNPosition: Short,
  nPNNumPulses: Short,
  fPNSettlingTime: Float,
  fPNInterpulse: Float,

  nLTPUsageOfDAC: Short,
  nLTPPresynapticPulses: Short,

  lDACFilePathIndex: Int,

  fMembTestPreSettlingTimeMS: Float,
  fMembTestPostSettlingTimeMS: Float,

  nLeakSubtractADCIndex: Short //
  // sUnused: Vector[Byte],     // size = 256 bytes
  )

object DACInfo extends StructDef[DACInfo] {

  val size = 256

  implicit val codec: Codec[DACInfo] = {
    (
      // The DAC this struct is describing.
      /* short */ ("nDACNum" | short16L) ::

      /* short */ ("nTelegraphDACScaleFactorEnable" | short16L) ::
      /* float */ ("fInstrumentHoldingLevel" | floatL) ::

      /* float */ ("fDACScaleFactor" | floatL) ::
      /* float */ ("fDACHoldingLevel" | floatL) ::
      /* float */ ("fDACCalibrationFactor" | floatL) ::
      /* float */ ("fDACCalibrationOffset" | floatL) ::

      /* ABFLONG */ ("lDACChannelNameIndex" | int32L) ::
      /* ABFLONG */ ("lDACChannelUnitsIndex" | int32L) ::

      /* ABFLONG */ ("lDACFilePtr" | int32L) ::
      /* ABFLONG */ ("lDACFileNumEpisodes" | int32L) ::

      /* short */ ("nWaveformEnable" | short16L) ::
      /* short */ ("nWaveformSource" | short16L) ::
      /* short */ ("nInterEpisodeLevel" | short16L) ::

      /* float */ ("fDACFileScale" | floatL) ::
      /* float */ ("fDACFileOffset" | floatL) ::
      /* ABFLONG */ ("lDACFileEpisodeNum" | int32L) ::
      /* short */ ("nDACFileADCNum" | short16L) ::

      /* short */ ("nConditEnable" | short16L) ::
      /* ABFLONG */ ("lConditNumPulses" | int32L) ::
      /* float */ ("fBaselineDuration" | floatL) ::
      /* float */ ("fBaselineLevel" | floatL) ::
      /* float */ ("fStepDuration" | floatL) ::
      /* float */ ("fStepLevel" | floatL) ::
      /* float */ ("fPostTrainPeriod" | floatL) ::
      /* float */ ("fPostTrainLevel" | floatL) ::
      /* short */ ("nMembTestEnable" | short16L) ::

      /* short */ ("nLeakSubtractType" | short16L) ::
      /* short */ ("nPNPolarity" | short16L) ::
      /* float */ ("fPNHoldingLevel" | floatL) ::
      /* short */ ("nPNNumADCChannels" | short16L) ::
      /* short */ ("nPNPosition" | short16L) ::
      /* short */ ("nPNNumPulses" | short16L) ::
      /* float */ ("fPNSettlingTime" | floatL) ::
      /* float */ ("fPNInterpulse" | floatL) ::

      /* short */ ("nLTPUsageOfDAC" | short16L) ::
      /* short */ ("nLTPPresynapticPulses" | short16L) ::

      /* ABFLONG */ ("lDACFilePathIndex" | int32L) ::

      /* float */ ("fMembTestPreSettlingTimeMS" | floatL) ::
      /* float */ ("fMembTestPostSettlingTimeMS" | floatL) ::

      /* short */ ("nLeakSubtractADCIndex" | short16L) ::

      /* char[124] */ ("sUnused" | vectorOfN(provide(124), byte).unit(Vector.fill(124)(0)))
    ).as[DACInfo]
  }
}
