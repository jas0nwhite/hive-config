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
    Data4: Vector[Short]) {
  require(Data4.length == 8)
}

object FileGUID extends StructDef[FileGUID] {
  val size = 16

  implicit val codec: Codec[FileGUID] = {
    (
      /* unsigned ABFLONG */ ("Data1" | uint32L) ::
      /* unsigned short */ ("Data2" | uint16L) ::
      /* unsigned short */ ("Data3" | uint16L) ::
      /* unsigned char[8] */ ("Data4" | vectorOfN(provide(8), ushort8))
    ).as[FileGUID]
  }
}
