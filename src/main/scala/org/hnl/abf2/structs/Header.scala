package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions
import shapeless._
import org.hnl.abf2.values._

/**
 * Header
 * <p>
 * Created on Apr 14, 2017.
 * <p>
 *
 * @author Jason White
 */
case class Header(
  uFileSignature: String,
  uFileVersionNumber: VersionNumber,

  // After this point there is no need to be the same as the ABF 1 equivalent.
  uFileInfoSize: Long,

  uActualEpisodes: Long,
  uFileStartDate: Long,
  uFileStartTimeMS: Long,
  uStopwatchTime: Long,
  nFileType: FileType,
  nDataFormat: Short,
  nSimultaneousScan: Short,
  nCRCEnable: Short,
  uFileCRC: Long,
  FileGUID: FileGUID,
  uCreatorVersion: VersionNumber,
  uCreatorNameIndex: Long,
  uModifierVersion: VersionNumber,
  uModifierNameIndex: Long,
  uProtocolPathIndex: Long,

  // New sections in ABF 2 - protocol stuff ...
  ProtocolSection: Section, // the protocol
  ADCSection: Section, // one for each ADC channel
  DACSection: Section, // one for each DAC channel
  EpochSection: Section, // one for each epoch
  ADCPerDACSection: Section, // one for each ADC for each DAC
  EpochPerDACSection: Section, // one for each epoch for each DAC
  UserListSection: Section, // one for each user list
  StatsRegionSection: Section, // one for each stats region
  MathSection: Section,
  StringsSection: Section,

  // ABF 1 sections ...
  DataSection: Section, // Data
  TagSection: Section, // Tags
  ScopeSection: Section, // Scope config
  DeltaSection: Section, // Deltas
  VoiceTagSection: Section, // Voice Tags
  SynchArraySection: Section, // Synch Array
  AnnotationSection: Section, // Annotations
  StatsSection: Section // Stats config
  // sUnused: Vector[Byte]     // size = 512 bytes
  )

object Header extends StructDef[Header] {
  val size = 512;

  val signature = "ABF2";

  implicit val codec: Codec[Header] = {
    (
      /* unsigned int */ ("uFileSignature" | fixedSizeBytes(4, ascii)) ::
      /* unsigned int */ ("uFileVersionNumber" | VersionNumber.codec) ::

      // After this point there is no need to be the same as the ABF 1 equivalent.
      /* unsigned int */ ("uFileInfoSize" | uint32L) ::

      /* unsigned int */ ("uActualEpisodes" | uint32L) ::
      /* unsigned int */ ("uFileStartDate" | uint32L) ::
      /* unsigned int */ ("uFileStartTimeMS" | uint32L) ::
      /* unsigned int */ ("uStopwatchTime" | uint32L) ::
      /* short */ ("nFileType" | FileType.codec) ::
      /* short */ ("nDataFormat" | short16L) ::
      /* short */ ("nSimultaneousScan" | short16L) ::
      /* short */ ("nCRCEnable" | short16L) ::
      /* unsigned int */ ("uFileCRC" | uint32L) ::
      /* MYGUID */ ("FileGUID" | FileGUID.codec) ::
      /* unsigned int */ ("uCreatorVersion" | VersionNumber.codec) ::
      /* unsigned int */ ("uCreatorNameIndex" | uint32L) ::
      /* unsigned int */ ("uModifierVersion" | VersionNumber.codec) ::
      /* unsigned int */ ("uModifierNameIndex" | uint32L) ::
      /* unsigned int */ ("uProtocolPathIndex" | uint32L) ::

      // New sections in ABF 2 - protocol stuff ...
      /* ABF_Section */ ("ProtocolSection" | Section.codec) ::
      /* ABF_Section */ ("ADCSection" | Section.codec) ::
      /* ABF_Section */ ("DACSection" | Section.codec) ::
      /* ABF_Section */ ("EpochSection" | Section.codec) ::
      /* ABF_Section */ ("ADCPerDACSection" | Section.codec) ::
      /* ABF_Section */ ("EpochPerDACSection" | Section.codec) ::
      /* ABF_Section */ ("UserListSection" | Section.codec) ::
      /* ABF_Section */ ("StatsRegionSection" | Section.codec) ::
      /* ABF_Section */ ("MathSection" | Section.codec) ::
      /* ABF_Section */ ("StringsSection" | Section.codec) ::

      // ABF 1 sections ...
      /* ABF_Section */ ("DataSection" | Section.codec) ::
      /* ABF_Section */ ("TagSection" | Section.codec) ::
      /* ABF_Section */ ("ScopeSection" | Section.codec) ::
      /* ABF_Section */ ("DeltaSection" | Section.codec) ::
      /* ABF_Section */ ("VoiceTagSection" | Section.codec) ::
      /* ABF_Section */ ("SynchArraySection" | Section.codec) ::
      /* ABF_Section */ ("AnnotationSection" | Section.codec) ::
      /* ABF_Section */ ("StatsSection" | Section.codec) ::

      /* char[148] */ ("sUnused" | vectorOfN(provide(148), byte).unit(Vector.fill(148)(0)))
    ).as[Header]
  }

}
