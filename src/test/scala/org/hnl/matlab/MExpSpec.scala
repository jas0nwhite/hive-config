package org.hnl.matlab

import org.scalatest.WordSpec
import org.scalatest.Matchers
import org.scalatest.Inspectors

import org.hnl.matlab.MExp._

/**
 * MExpSpec
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
class MExpSpec extends WordSpec with Matchers with Inspectors with Helpers {

  /*
   * NUMBERS
   */
  "M.Num" should {
    "represent a number" in {
      test(M.Num(3), "3")
      test(M.Num(3.5), "3.5")
      test(M.Num(-3.5), "-3.5")
    }

    "represent a number from a string" in {
      test(M.Num("3"), "3")
      test(M.Num("3.5"), "3.5")
      test(M.Num("-3.5"), "-3.5")
      test(M.Num("Inf"), "Inf")
      test(M.Num("-Inf"), "-Inf")
      test(M.Num("NaN"), "NaN")
      test(M.Num("true"), "true")
      test(M.Num("false"), "false")
    }

    "represent extremes" in {
      test(M.Num(Double.NegativeInfinity), "-Inf")
      test(M.Num(Double.PositiveInfinity), "Inf")
      test(M.Num(Double.NaN), "NaN")
    }

    "represent booleans" in {
      test(M.Num(true), "true")
      test(M.Num(false), "false")
    }
  }

  /*
   * STRINGS
   */
  "M.Str" should {
    "represent a string in single quotes" in {
      test(M.Str("test"), "'test'")
    }

    "represent an empty string" in {
      test(M.Str(""), "''")
    }

    "represent a string with escaped quotes" in {
      test(M.Str("Jason's Test\\n"), "'Jason''s Test\\n'")
    }
  }

  /*
   * RAW
   */
  "M.Raw" should {

    "echo the contents" in {
      val contents = "for i = 1:10; fprintf('the \"value\" is %d\\n', i); end;"

      test(M.Raw(contents), contents)
    }
  }

  /*
   * IDENTIFIERS
   */
  "M.Var" should {

    "render valid identifier unchanged" in {
      test(M.Var("test"), "test")
    }

    "strip spaces from identifier" in {
      test(M.Var(" strip  "), "strip")
    }

    "append 'x' before non-alpha initial characters" in {
      test(M.Var("2isnotgood"), "x2isnotgood")
      test(M.Var("#3"), "x_3")
    }

    "replace non alpha-numeric-underscore characters with underscores" in {
      test(M.Var("four score and 7 years ago... 'Abe'"), "four_score_and_7_years_ago_____Abe_")
    }
  }

  /*
   * ARRAYS
   */
  "M.CVec" should {

    "render empty array" in {
      test(M.CVec(), "[]")
    }

    "render single-valued array" in {
      test(M.CVec(3), "[3]")
    }

    "render multi-valued column array" in {
      test(M.CVec(1, 2, 3, 4, 5), "[1; 2; 3; 4; 5]")
    }

    "render nested arrays" in {
      test(M.CVec(M.CVec(1, 2), M.CVec(3, 4)), "[[1; 2]; [3; 4]]")
    }
  }

  "M.RVec" should {
    "render empty array" in {
      test(M.RVec(), "[]")
    }

    "render single-valued array" in {
      test(M.RVec(3), "[3]")
    }

    "render multi-valued column array" in {
      test(M.RVec(1, 2, 3, 4, 5), "[1, 2, 3, 4, 5]")
    }

    "render nested arrays" in {
      test(M.RVec(M.RVec(1, 2), M.RVec(3, 4)), "[[1, 2], [3, 4]]")
    }
  }

  "M.CCell" should {

    "render empty array" in {
      test(M.CCell(), "{}")
    }

    "render single-valued array" in {
      test(M.CCell(3), "{3}")
    }

    "render multi-valued column array" in {
      test(M.CCell(1, 2, 3, 4, 5), "{1; 2; 3; 4; 5}")
    }

    "render nested arrays" in {
      test(M.CCell(M.CCell(1, 2), M.CCell(3, 4)), "{{1; 2}; {3; 4}}")
    }
  }

  "M.RCell" should {
    "render empty array" in {
      test(M.RCell(), "{}")
    }

    "render single-valued array" in {
      test(M.RCell(3), "{3}")
    }

    "render multi-valued column array" in {
      test(M.RCell(1, 2, 3, 4, 5), "{1, 2, 3, 4, 5}")
    }

    "render nested arrays" in {
      test(M.RCell(M.RCell(1, 2), M.RCell(3, 4)), "{{1, 2}, {3, 4}}")
    }
  }

  /*
   * EXPRESSIONS
   */
  "M.Exp" should {

    "render assignments" in {
      val mexp = M.Var("testVar") %=% M.Str("testValue")

      test(mexp, "testVar = 'testValue'")
    }

    "append ; at end of commands" in {
      val mexp = M.Var("testVar") %=% M.Str("testValue")
      val expected = "testVar = 'testValue';"

      val actual = mexp.toMatCmd

      actual should not be (null)
      actual should not be empty
      actual shouldBe expected
    }

    "render paren indexing" in {
      test(M.Var("x").paren(3), "x(3)")
    }

    "render curly indexing" in {
      test(M.Var("c").curly(3), "c{3}")
    }

    "render slice ranges" in {
      test(M.Var("v").paren(M.%:%), "v(:)")
      test(M.Var("v").paren(3 %:% 4), "v(3:4)")
      test(M.Var("v").paren(3 %:% 4 %:% 5), "v(3:4:5)")
      test(M.Var("v").paren(3.%:%(4).%:%(5)), "v(3:4:5)")
    }
  }
}

trait Helpers {
  this: WordSpec with Matchers with Inspectors =>

  protected def test(test: MExp, expected: String): Unit = {
    val actual = test.toMatlab

    actual should not be (null)
    actual should not be empty
    actual shouldBe expected
  }
}
