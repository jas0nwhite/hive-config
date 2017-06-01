package org.hnl.abf2.values

import enumeratum.values._

/**
 * FileType
 * <p>
 * Created on May 31, 2017.
 * <p>
 *
 * @author Jason White
 */
sealed abstract class FileType(val value: Short, val description: String) extends ShortEnumEntry with EnumDescription

case object FileType extends ShortEnum[FileType] {

  case object ABF_ABFFILE extends FileType(1, "ABF_ABFFILE")
  case object ABF_FETCHEX extends FileType(2, "ABF_FETCHEX")
  case object ABF_CLAMPEX extends FileType(3, " ABF_CLAMPEX")

  val values = findValues

  val codec = Serialization.codec(FileType)

  val format = Serialization.serializer(FileType)
}
