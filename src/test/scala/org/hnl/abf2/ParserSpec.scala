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

        import org.json4s._
        import org.json4s.native.Serialization
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

        import org.hnl.abf2.values.OperationMode
        protocol.OperationMode shouldBe OperationMode.ABF_WAVEFORMFILE

        val bits = ProtocolInfo.codec.encode(protocol).require

        bits.bytes.length shouldBe ProtocolInfo.size

        import org.json4s._
        import org.json4s.native.Serialization
        implicit val formats = DefaultFormats + OperationMode.format
        println(Serialization.writePretty(protocol))
      }

      "parse strings" in {
        val parser: StreamDecoder[Strings] = D.once(Header.codec) flatMap { hdr =>
          D.advance((hdr.StringsSection.uBlockIndex - 1) * 8 * abfBlockSize) ++
            D.once(Strings.codec(hdr.StringsSection.uBytes))
        }

        val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, abfBlockSize)

        val stringsList: Vector[Strings] = stream.runLog.unsafeRun()

        stringsList should not be empty
        stringsList should have length (1)

        val strings = stringsList(0)

        strings.values should not be empty
        strings.values should contain("Clampex")

        println(strings.values)
      }

      "parse ADC info" in {
        import scodec.codecs._

        val parser: StreamDecoder[Vector[ADCInfo]] = D.once(Header.codec) flatMap { hdr =>
          D.advance((hdr.ADCSection.uBlockIndex - 1) * 8 * abfBlockSize) ++
            D.once(vectorOfN(provide(hdr.ADCSection.llNumEntries.toInt), ADCInfo.codec))
        }

        val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, abfBlockSize)

        val adcList: Vector[Vector[ADCInfo]] = stream.runLog.unsafeRun()

        adcList should not be empty
        adcList should have length (1)
        val adcs = adcList(0)

        adcs should not be empty
        adcs should have length (2)
        val adc0 = adcs(0)

        adc0.nADCNum shouldBe 0
        adc0.nTelegraphEnable shouldBe 1

        import org.json4s._
        import org.json4s.native.Serialization
        implicit val formats = DefaultFormats
        println(Serialization.writePretty(adcs))
      }

      "parse DAC info" in {
        import scodec.codecs._

        val parser: StreamDecoder[Vector[DACInfo]] = D.once(Header.codec) flatMap { hdr =>
          D.advance((hdr.DACSection.uBlockIndex - 1) * 8 * abfBlockSize) ++
            D.once(vectorOfN(provide(hdr.DACSection.llNumEntries.toInt), DACInfo.codec))
        }

        val stream = parser.decodeMmap(new java.io.FileInputStream(testFile.toFile).getChannel, abfBlockSize)

        val dacList: Vector[Vector[DACInfo]] = stream.runLog.unsafeRun()

        dacList should not be empty
        dacList should have length (1)
        val dacs = dacList(0)

        dacs should not be empty
        dacs should have length (8)
        val dac0 = dacs(0)

        dac0.nDACNum shouldBe 0
        dac0.nTelegraphDACScaleFactorEnable shouldBe 1

        import org.json4s._
        import org.json4s.native.Serialization
        implicit val formats = DefaultFormats
        println(Serialization.writePretty(dacs))
      }
    }
  }
}
