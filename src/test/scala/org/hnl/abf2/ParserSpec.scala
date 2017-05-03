package org.hnl.abf2

import java.nio.file.Paths

import scala.language.implicitConversions

import org.hnl.abf2.structs._
import org.scalatest._

import scodec.stream.{ StreamDecoder, decode => D }

/**
 * ParserSpec
 * <p>
 * Created on Apr 14, 2017.
 * <p>
 *
 * @author Jason White
 */
class ParserSpec extends WordSpec with Matchers with Inspectors {

  "ABF2 codecs" when {

    "decoding from binary file" should {

      val testFile = Paths.get("dat", "2017_03_09_5HT_run_0000.abf")
      val abfBlockSize = 512;

      "parse header" in {
        val parser: StreamDecoder[Header] = D.once(Header.codec)

        val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, abfBlockSize)

        val headers: Vector[Header] = stream.runLog.unsafeRun()

        headers should not be empty
        headers should have length (1)
        val header = headers(0)

        header.uFileSignature shouldBe Header.signature
        header.uFileInfoSize shouldBe Header.size

        val bits = Header.codec.encode(header).require

        bits.bytes.length shouldBe Header.size

        import net.liftweb.json._
        implicit val formats = DefaultFormats
        println(Serialization.writePretty(header))
      }

      "parse protocol info" in {
        val parser: StreamDecoder[ProtocolInfo] = D.once(Header.codec) flatMap { hdr =>
          D.advance((hdr.ProtocolSection.uBlockIndex - 1) * 8 * abfBlockSize) ++
            D.once(ProtocolInfo.codec)
        }

        val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, abfBlockSize)

        val protocols: Vector[ProtocolInfo] = stream.runLog.unsafeRun()

        protocols should not be empty
        protocols should have length (1)
        val protocol = protocols(0)

        protocol.bEnableFileCompression shouldBe false

        val bits = ProtocolInfo.codec.encode(protocol).require

        bits.bytes.length shouldBe ProtocolInfo.size

        import net.liftweb.json._
        implicit val formats = DefaultFormats
        println(Serialization.writePretty(protocol))
      }
  }
}
