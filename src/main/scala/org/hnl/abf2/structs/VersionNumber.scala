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
  build: Short,
  inc: Short,
  minor: Short,
  major: Short)

object VersionNumber extends StructDef[VersionNumber] {
  val size = 4

  implicit val codec: Codec[VersionNumber] = {
    (
      ("build" | ushort8) ::
      ("inc" | ushort8) ::
      ("minor" | ushort8) ::
      ("major" | ushort8)
    ).as[VersionNumber]
  }

}
