package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * ProtocolInfo
 * <p>
 * Created on Apr 28, 2017.
 * <p>
 *
 * @author Jason White
 */
case class ProtocolInfo(
  nOperationMode: Short,
  fADCSequenceInterval: Float,
  bEnableFileCompression: Boolean,
  // sUnused1: Vector[Byte],
  uFileCompressionRatio: Long,

  fSynchTimeUnit: Float,
  fSecondsPerRun: Float,
  lNumSamplesPerEpisode: Int,
  lPreTriggerSamples: Int,
  lEpisodesPerRun: Int,
  lRunsPerTrial: Int,
  lNumberOfTrials: Int,
  nAveragingMode: Short,
  nUndoRunCount: Short,
  nFirstEpisodeInRun: Short,
  fTriggerThreshold: Float,
  nTriggerSource: Short,
  nTriggerAction: Short,
  nTriggerPolarity: Short,
  fScopeOutputInterval: Float,
  fEpisodeStartToStart: Float,
  fRunStartToStart: Float,
  lAverageCount: Int,
  fTrialStartToStart: Float,
  nAutoTriggerStrategy: Short,
  fFirstRunDelayS: Float,

  nChannelStatsStrategy: Short,
  lSamplesPerTrace: Int,
  lStartDisplayNum: Int,
  lFinishDisplayNum: Int,
  nShowPNRawData: Short,
  fStatisticsPeriod: Float,
  lStatisticsMeasurements: Int,
  nStatisticsSaveStrategy: Short,

  fADCRange: Float,
  fDACRange: Float,
  lADCResolution: Int,
  lDACResolution: Int,

  nExperimentType: Short,
  nManualInfoStrategy: Short,
  nCommentsEnable: Short,
  lFileCommentIndex: Int,
  nAutoAnalyseEnable: Short,
  nSignalType: Short,

  nDigitalEnable: Short,
  nActiveDACChannel: Short,
  nDigitalHolding: Short,
  nDigitalInterEpisode: Short,
  nDigitalDACChannel: Short,
  nDigitalTrainActiveLogic: Short,

  nStatsEnable: Short,
  nStatisticsClearStrategy: Short,

  nLevelHysteresis: Short,
  lTimeHysteresis: Int,
  nAllowExternalTags: Short,
  nAverageAlgorithm: Short,
  fAverageWeighting: Float,
  nUndoPromptStrategy: Short,
  nTrialTriggerSource: Short,
  nStatisticsDisplayStrategy: Short,
  nExternalTagType: Short,
  nScopeTriggerOut: Short,

  nLTPType: Short,
  nAlternateDACOutputState: Short,
  nAlternateDigitalOutputState: Short,

  fCellID: Vector[Float],

  nDigitizerADCs: Short,
  nDigitizerDACs: Short,
  nDigitizerTotalDigitalOuts: Short,
  nDigitizerSynchDigitalOuts: Short,
  nDigitizerType: Short //,
  // sUnused: Vector[Byte]     // size = 512 bytes
  )

object ProtocolInfo extends StructDef[ProtocolInfo] {
  val size = 512

  implicit val codec: Codec[ProtocolInfo] = {
    (
      /* short */ ("nOperationMode" | short16L) ::
      /* float */ ("fADCSequenceInterval" | floatL) ::
      /* bool */ ("bEnableFileCompression" | bool(8)) ::
      /* char[3] */ ("sUnused1" | vectorOfN(provide(3), byte).unit(Vector.fill(3)(0))) ::
      /* unsigned int */ ("uFileCompressionRatio" | uint32L) ::

      /* float */ ("fSynchTimeUnit" | floatL) ::
      /* float */ ("fSecondsPerRun" | floatL) ::
      /* ABFLONG */ ("lNumSamplesPerEpisode" | int32L) ::
      /* ABFLONG */ ("lPreTriggerSamples" | int32L) ::
      /* ABFLONG */ ("lEpisodesPerRun" | int32L) ::
      /* ABFLONG */ ("lRunsPerTrial" | int32L) ::
      /* ABFLONG */ ("lNumberOfTrials" | int32L) ::
      /* short */ ("nAveragingMode" | short16L) ::
      /* short */ ("nUndoRunCount" | short16L) ::
      /* short */ ("nFirstEpisodeInRun" | short16L) ::
      /* float */ ("fTriggerThreshold" | floatL) ::
      /* short */ ("nTriggerSource" | short16L) ::
      /* short */ ("nTriggerAction" | short16L) ::
      /* short */ ("nTriggerPolarity" | short16L) ::
      /* float */ ("fScopeOutputInterval" | floatL) ::
      /* float */ ("fEpisodeStartToStart" | floatL) ::
      /* float */ ("fRunStartToStart" | floatL) ::
      /* ABFLONG */ ("lAverageCount" | int32L) ::
      /* float */ ("fTrialStartToStart" | floatL) ::
      /* short */ ("nAutoTriggerStrategy" | short16L) ::
      /* float */ ("fFirstRunDelayS" | floatL) ::

      /* short */ ("nChannelStatsStrategy" | short16L) ::
      /* ABFLONG */ ("lSamplesPerTrace" | int32L) ::
      /* ABFLONG */ ("lStartDisplayNum" | int32L) ::
      /* ABFLONG */ ("lFinishDisplayNum" | int32L) ::
      /* short */ ("nShowPNRawData" | short16L) ::
      /* float */ ("fStatisticsPeriod" | floatL) ::
      /* ABFLONG */ ("lStatisticsMeasurements" | int32L) ::
      /* short */ ("nStatisticsSaveStrategy" | short16L) ::

      /* float */ ("fADCRange" | floatL) ::
      /* float */ ("fDACRange" | floatL) ::
      /* ABFLONG */ ("lADCResolution" | int32L) ::
      /* ABFLONG */ ("lDACResolution" | int32L) ::

      /* short */ ("nExperimentType" | short16L) ::
      /* short */ ("nManualInfoStrategy" | short16L) ::
      /* short */ ("nCommentsEnable" | short16L) ::
      /* ABFLONG */ ("lFileCommentIndex" | int32L) ::
      /* short */ ("nAutoAnalyseEnable" | short16L) ::
      /* short */ ("nSignalType" | short16L) ::

      /* short */ ("nDigitalEnable" | short16L) ::
      /* short */ ("nActiveDACChannel" | short16L) ::
      /* short */ ("nDigitalHolding" | short16L) ::
      /* short */ ("nDigitalInterEpisode" | short16L) ::
      /* short */ ("nDigitalDACChannel" | short16L) ::
      /* short */ ("nDigitalTrainActiveLogic" | short16L) ::

      /* short */ ("nStatsEnable" | short16L) ::
      /* short */ ("nStatisticsClearStrategy" | short16L) ::

      /* short */ ("nLevelHysteresis" | short16L) ::
      /* ABFLONG */ ("lTimeHysteresis" | int32L) ::
      /* short */ ("nAllowExternalTags" | short16L) ::
      /* short */ ("nAverageAlgorithm" | short16L) ::
      /* float */ ("fAverageWeighting" | floatL) ::
      /* short */ ("nUndoPromptStrategy" | short16L) ::
      /* short */ ("nTrialTriggerSource" | short16L) ::
      /* short */ ("nStatisticsDisplayStrategy" | short16L) ::
      /* short */ ("nExternalTagType" | short16L) ::
      /* short */ ("nScopeTriggerOut" | short16L) ::

      /* short */ ("nLTPType" | short16L) ::
      /* short */ ("nAlternateDACOutputState" | short16L) ::
      /* short */ ("nAlternateDigitalOutputState" | short16L) ::

      /* float[3] */ ("fCellID" | vectorOfN(provide(3), floatL)) ::

      /* short */ ("nDigitizerADCs" | short16L) ::
      /* short */ ("nDigitizerDACs" | short16L) ::
      /* short */ ("nDigitizerTotalDigitalOuts" | short16L) ::
      /* short */ ("nDigitizerSynchDigitalOuts" | short16L) ::
      /* short */ ("nDigitizerType" | short16L) ::

      /* char[304] */ ("sUnused" | vectorOfN(provide(304), byte).unit(Vector.fill(304)(0)))
    ).as[ProtocolInfo]
  }
}
