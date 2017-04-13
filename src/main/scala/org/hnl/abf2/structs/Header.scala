package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * Header
 * <p>
 * Created on Apr 14, 2017.
 * <p>
 *
 * @author Jason White
 */
case class Header(
  uFileSignature: Long,
  uFileVersionNumber: Long,

  // After this point there is no need to be the same as the ABF 1 equivalent.
  uFileInfoSize: Long,

  uActualEpisodes: Long,
  uFileStartDate: Long,
  uFileStartTimeMS: Long,
  uStopwatchTime: Long,
  nFileType: Int,
  nDataFormat: Int,
  nSimultaneousScan: Int,
  nCRCEnable: Int,
  uFileCRC: Long,
  FileGUID: FileGUID,
  uCreatorVersion: Long,
  uCreatorNameIndex: Long,
  uModifierVersion: Long,
  uModifierNameIndex: Long,
  uProtocolPathIndex: Long //,
  //
  //  // New sections in ABF 2 - protocol stuff ...
  //  ProtocolSection: Section,           // the protocol
  //  ADCSection: Section,                // one for each ADC channel
  //  DACSection: Section,                // one for each DAC channel
  //  EpochSection: Section,              // one for each epoch
  //  ADCPerDACSection: Section,          // one for each ADC for each DAC
  //  EpochPerDACSection: Section,        // one for each epoch for each DAC
  //  UserListSection: Section,           // one for each user list
  //  StatsRegionSection: Section,        // one for each stats region
  //  MathSection: Section,
  //  StringsSection: Section,
  //
  //  // ABF 1 sections ...
  //  DataSection: Section,            // Data
  //  TagSection: Section,             // Tags
  //  ScopeSection: Section,           // Scope config
  //  DeltaSection: Section,           // Deltas
  //  VoiceTagSection: Section,        // Voice Tags
  //  SynchArraySection: Section,      // Synch Array
  //  AnnotationSection: Section,      // Annotations
  //  StatsSection: Section,           // Stats config
  //
  //  char  sUnused[148]     // size = 512 bytes
  )
object Header {
  implicit val codec: Codec[Header] = {
    (
      ("uFileSignature" | uint32L) ::
      ("uFileVersionNumber" | uint32L) ::

      // After this point there is no need to be the same as the ABF 1 equivalent.
      ("uFileInfoSize" | uint32L) ::

      ("uActualEpisodes" | uint32L) ::
      ("uFileStartDate" | uint32L) ::
      ("uFileStartTimeMS" | uint32L) ::
      ("uStopwatchTime" | uint32L) ::
      ("nFileType" | uint16L) ::
      ("nDataFormat" | uint16L) ::
      ("nSimultaneousScan" | uint16L) ::
      ("nCRCEnable" | uint16L) ::
      ("uFileCRC" | uint32L) ::
      ("FileGUID" | FileGUID.codec) ::
      ("uCreatorVersion" | uint32L) ::
      ("uCreatorNameIndex" | uint32L) ::
      ("uModifierVersion" | uint32L) ::
      ("uModifierNameIndex" | uint32L) ::
      ("uProtocolPathIndex" | uint32L)
    ).as[Header]
  }

}
