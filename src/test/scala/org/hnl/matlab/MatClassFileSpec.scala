package org.hnl.matlab

import org.scalatest._
import org.hnl.hive.cfg.matlab.MatClassFile
import org.hnl.matlab.M.ClassDef
import org.hnl.matlab.M.ClassObj

// scalastyle:off null

/**
 * MatClassFileSpec
 * <p>
 * Created on Mar 9, 2016.
 * <p>
 *
 * @author Jason White
 */
class MatClassFileSpec extends WordSpec with Matchers with Inspectors with Helpers {

  "MatClassFile" should {

    "yield proper file path" in {

      val mClass = new MatClassFile() {
        override val name = "Test"
        override val pkg = "org.hnl"
        override val mClass = ClassDef(name)
        override def toMatlab: String = mClass.toMatlab
      }

      val expected = "+org/+hnl/Test.m"
      val actual = mClass.filePath.toString

      actual should not be (null)
      actual should not be empty
      actual shouldBe expected
    }

  }

  "yield proper class identifier" in {
    val mClass = new MatClassFile() {
      override val name = "Test"
      override val pkg = "org.hnl"
      override val mClass = ClassDef(name)
      override def toMatlab: String = mClass.toMatlab
    }

    val expected = ClassObj(mClass.pkg, mClass.name)
    val actual = mClass.classObj

    actual should not be (null)
    actual shouldBe expected
  }

}
