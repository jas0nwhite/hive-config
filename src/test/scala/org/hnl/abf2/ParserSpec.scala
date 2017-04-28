package org.hnl.abf2

import org.hnl.abf2.structs._

import org.scalatest._
import java.nio.file.Paths

import scodec._
import scodec.bits._
import scodec.codecs._
import scodec.codecs.implicits._
import scodec.stream.{ decode => D, StreamDecoder }
import scala.language.implicitConversions
import scodec.stream.encode.StreamEncoder

/**
 * ParserSpec
 * <p>
 * Created on Apr 14, 2017.
 * <p>
 *
 * @author Jason White
 */
class ParserSpec extends WordSpec with Matchers with Inspectors {

  "ABF2 Parser" should {

    val testFile = Paths.get("dat", "2017_03_09_5HT_run_0000.abf")

    "parse header" in {
      val parser: StreamDecoder[Header] = D.once(Header.codec)

      val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, 512)

      val headers = stream.runLog.unsafeRun()

      headers should not be empty
      headers should have length (1)
      val header = headers(0)

      header.uFileSignature shouldBe Header.signature
      header.uFileInfoSize shouldBe Header.size

      val bits = Header.codec.encode(header).require

      bits.bytes.length shouldBe Header.size;

      import net.liftweb.json._
      implicit val formats = DefaultFormats
      println(Serialization.writePretty(header))
    }
  }
}
