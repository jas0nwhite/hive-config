package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions
import shapeless.HNil

/**
 * VersionNumber
 * <p>
 * Created on Apr 28, 2017.
 * <p>
 *
 * @author Jason White
 */
case class VersionNumber(
  build: Int,
  inc: Int,
  minor: Int,
  major: Int)

object VersionNumber {
  implicit val codec: Codec[VersionNumber] = {
    (
      ("build" | uint8) ::
      ("inc" | uint8) ::
      ("minor" | uint8) ::
      ("major" | uint8)
    ).as[VersionNumber]
  }

}
