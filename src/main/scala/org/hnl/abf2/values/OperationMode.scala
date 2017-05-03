package org.hnl.abf2.values

import scodec._
import scodec.bits._
import scodec.codecs._
import scala.language.implicitConversions
import scala.collection.Seq

/**
 * OperationMode
 * <p>
 * Created on May 1, 2017.
 * <p>
 *
 * @author Jason White
 */
object OperationMode {

  case class Value(val id: Int, val name: String)

  val ABF_VARLENEVENTS = Value(1, "ABF_VARLENEVENTS")
  val ABF_FIXLENEVENTS = Value(2, "ABF_FIXLENEVENTS / ABF_LOSSFREEOSC") // (ABF_FIXLENEVENTS == ABF_LOSSFREEOSC)
  // val ABF_LOSSFREEOSC extends Value(2, "ABF_LOSSFREEOSC")
  val ABF_GAPFREEFILE = Value(3, "ABF_GAPFREEFILE")
  val ABF_HIGHSPEEDOSC = Value(4, "ABF_HIGHSPEEDOSC")
  val ABF_WAVEFORMFILE = Value(5, "ABF_WAVEFORMFILE")

  val values = Seq(
    ABF_VARLENEVENTS,
    ABF_FIXLENEVENTS,
    ABF_GAPFREEFILE,
    ABF_HIGHSPEEDOSC,
    ABF_WAVEFORMFILE
  )

  val x = OperationMode.values.map(v => (v, v.id))

  implicit val codec: Codec[OperationMode.Value] =
    mappedEnum(int16L, OperationMode.values.map(v => (v, v.id)).toMap)
}
