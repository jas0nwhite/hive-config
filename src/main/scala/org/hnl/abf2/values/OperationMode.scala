package org.hnl.abf2.values

import enumeratum.values._

/**
 * OperationMode
 * <p>
 * Created on May 1, 2017.
 * <p>
 *
 * @author Jason White
 */
sealed abstract class OperationMode(val value: Short, val description: String) extends ShortEnumEntry with EnumDescription

case object OperationMode extends ShortEnum[OperationMode] {

  case object ABF_VARLENEVENTS extends OperationMode(1, "ABF_VARLENEVENTS")
  case object ABF_FIXLENEVENTS extends OperationMode(2, "ABF_FIXLENEVENTS / ABF_LOSSFREEOSC") // (ABF_FIXLENEVENTS == ABF_LOSSFREEOSC)
  // case object ABF_LOSSFREEOSC extends OperationMode(2, "ABF_LOSSFREEOSC")
  case object ABF_GAPFREEFILE extends OperationMode(3, "ABF_GAPFREEFILE")
  case object ABF_HIGHSPEEDOSC extends OperationMode(4, "ABF_HIGHSPEEDOSC")
  case object ABF_WAVEFORMFILE extends OperationMode(5, "ABF_WAVEFORMFILE")

  val values = findValues

  val codec = Serialization.codec(OperationMode)

  val format = Serialization.serializer(OperationMode)
}
