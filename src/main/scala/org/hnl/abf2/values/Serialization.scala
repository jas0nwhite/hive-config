package org.hnl.abf2.values

import enumeratum.values._

import org.json4s.CustomSerializer
import org.json4s.JsonAST._
import org.json4s.JsonDSL._

import scodec._
import scodec.bits._
import scodec.codecs._

/**
 * Serialization
 * <p>
 * Created on May 31, 2017.
 * <p>
 *
 * @author Jason White
 */
object Serialization {

  def serializer[A <: ShortEnumEntry with EnumDescription: Manifest](enum: ShortEnum[A]): CustomSerializer[A] =
    new CustomSerializer[A](
      implicit format => (
        {
          case jsonObj: JObject =>
            val value = (jsonObj \ "value").extract[Short]

            enum.withValue(value)
        }, {
          case mode: A =>
            ("value" -> mode.value) ~ ("description" -> mode.description)
        }
      ))

  def codec[A <: ShortEnumEntry: Manifest](enum: ShortEnum[A]): Codec[A] =
    mappedEnum(short16L, enum.values.map(v => (v, v.value)).toMap)

}
