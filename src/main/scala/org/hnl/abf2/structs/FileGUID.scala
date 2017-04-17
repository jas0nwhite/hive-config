package org.hnl.abf2.structs

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scala.language.implicitConversions

/**
 * FileGUID
 * <p>
 * Created on Apr 14, 2017.
 * <p>
 *
 * @author Jason White
 */
case class FileGUID(
    Data1: Long,
    Data2: Int,
    Data3: Int,
    Data4: Vector[Int]) {
  require(Data4.length == 8)
}

object FileGUID {
  implicit val codec: Codec[FileGUID] = {
    (
      ("Data1" | uint32L) ::
      ("Data2" | uint16L) ::
      ("Data3" | uint16L) ::
      ("Data4" | vectorOfN(provide(8), uint8))
    ).as[FileGUID]
  }
}
