package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * Strings
 * <p>
 * Created on May 4, 2017.
 * <p>
 *
 * @author Jason White
 */
case class Strings(values: Vector[String])

object Strings {
  implicit def codec(bytes: Long): Codec[Strings] = {
    (
      ("values" | fixedSizeBytes(bytes, vector(cstring)))
    ).as[Strings]
  }
}
