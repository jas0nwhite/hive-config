package org.hnl.abf2.structs

import scodec.Codec

/**
 * StructDef
 * <p>
 * Created on May 1, 2017.
 * <p>
 *
 * @author Jason White
 */
trait StructDef[A] {
  val size: Long
  implicit val codec: Codec[A]
}
