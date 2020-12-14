package org.hnl.matlab

import org.hnl.hive.cfg.matlab.MatClassFile
import org.hnl.matlab.M.{ClassDef, ClassObj}
import org.scalatest._
import org.scalatest.matchers.should._
import org.scalatest.wordspec._

// scalastyle:off null

/**
  * MatClassFileSpec
  * <p>
  * Created on Mar 9, 2016.
  * <p>
  *
  * @author Jason White
  */
//noinspection ScalaUnnecessaryParentheses
class MatClassFileSpec extends AnyWordSpec
  with Matchers with Inspectors with Helpers {

  "MatClassFile" should {

    "yield proper file path" in {

      val mClass = new MatClassFile() {
        override val name = "Test"
        override val pkg = "org.hnl"
        override val mClass: ClassDef = ClassDef(name)

        override def toMatlab: String = mClass.toMatlab
      }

      val expected = "+org/+hnl/Test.m"
      val actual = mClass.filePath.toString

      actual should not be (null)
      actual should not be (empty)
      actual shouldBe (expected)
    }

  }

  "yield proper class identifier" in {
    val mClass = new MatClassFile() {
      override val name = "Test"
      override val pkg = "org.hnl"
      override val mClass: ClassDef = ClassDef(name)

      override def toMatlab: String = mClass.toMatlab
    }

    val expected = ClassObj(mClass.pkg, mClass.name)
    val actual = mClass.classObj

    actual should not be (null)
    actual shouldBe (expected)
  }

}
