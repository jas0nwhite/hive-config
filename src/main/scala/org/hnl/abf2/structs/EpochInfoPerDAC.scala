package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
  * EpochInfoPerDAC
  * <p>
  * Created on 2019-07-22
  * <p>
  *
  * @author Jason White
  */
case class EpochInfoPerDAC(
  // The Epoch / DAC this struct is describing.
  nEpochNum: Short,
  nDACNum: Short,

  // One full set of epochs (ABF_EPOCHCOUNT) for each DAC channel ...
  nEpochType: Short,
  fEpochInitLevel: Float,
  fEpochLevelInc: Float,
  lEpochInitDuration: Int,
  lEpochDurationInc: Int,
  lEpochPulsePeriod: Int,
  lEpochPulseWidth: Int,

  // sUnused: Vector[Byte],      // size = 48 bytes
)

object EpochInfoPerDAC extends StructDef[EpochInfoPerDAC] {
  val size = 48

  implicit val codec: Codec[EpochInfoPerDAC] = {
    (
      // The Epoch / DAC this struct is describing.
      ("nEpochNum" | short16L) ::
      ("nDACNum" | short16L) ::

      // One full set of epochs (ABF_EPOCHCOUNT) for each DAC channel ...
      ("nEpochType" | short16L) ::
      ("fEpochInitLevel" | floatL) ::
      ("fEpochLevelInc" | floatL) ::
      ("lEpochInitDuration" | int32L) ::
      ("lEpochDurationInc" | int32L) ::
      ("lEpochPulsePeriod" | int32L) ::
      ("lEpochPulseWidth" | int32L) ::

      ("sUnused" | vectorOfN(provide(18), byte).unit(Vector.fill(18)(0)))
      ).as[EpochInfoPerDAC]
  }
}