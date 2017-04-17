package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * Section
 * <p>
 * Created on Apr 17, 2017.
 * <p>
 *
 * @author Jason White
 */
case class Section(
  uBlockIndex: Long, // ABF block number of the first entry
  uBytes: Long, // size in bytes of of each entry
  llNumEntries: Long // number of entries in this section
  )

object Section {
  implicit val codec: Codec[Section] = {
    (
      ("uBlockIndex" | uint32L) ::
      ("uBytes" | uint32L) ::
      ("llNumEntries" | longL(64))
    ).as[Section]
  }
}
