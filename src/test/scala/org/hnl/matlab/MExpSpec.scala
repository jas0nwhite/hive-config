package org.hnl.matlab

import org.scalatest.WordSpec
import org.scalatest.Matchers
import org.scalatest.Inspectors

import org.hnl.matlab.MExp._

// scalastyle:off magic.number
// scalastyle:off null
// scalastyle:off multiple.string.literals

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
      test('test, "test")
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
      test(
        M.CVec(1, 2, 3, 4, 5),
        """|[
           |    1;
           |    2;
           |    3;
           |    4;
           |    5
           |]""".stripMargin)
    }

    "render nested arrays" in {
      test(
        M.CVec(M.CVec(1, 2), M.CVec(3, 4)),
        """|[
           |    [
           |        1;
           |        2
           |    ];
           |    [
           |        3;
           |        4
           |    ]
           |]""".stripMargin)
    }

    "render 2-D arrays" in {
      test(
        M.CVec(
          M.Row(1, 2, 3),
          M.Row(4, 5, 6),
          M.Row(7, 8, 9)
        ),
        """|[
           |    1, 2, 3;
           |    4, 5, 6;
           |    7, 8, 9
           |]""".stripMargin
      )
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
      test(M.CCell(1, 2, 3, 4, 5),
        """|{
           |    1;
           |    2;
           |    3;
           |    4;
           |    5
           |}""".stripMargin)

    }

    "render nested arrays" in {
      test(
        M.CCell(M.CCell(1, 2), M.CCell(3, 4)),
        """|{
           |    {
           |        1;
           |        2
           |    };
           |    {
           |        3;
           |        4
           |    }
           |}""".stripMargin)
    }
  }

  "render multidimensional arrays" in {
    test(
      M.CCell(
        M.Row("test", 1.2, 1.3),
        M.Row("val", 3, 17),
        M.Row("mike", 21, 8.8)
      ),
      """|{
         |    'test', 1.2, 1.3;
         |    'val', 3, 17;
         |    'mike', 21, 8.8
         |}""".stripMargin
    )
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
   * CLASSES
   */
  "M.Class" should {

    "render empty class" in {
      val mclass = M.ClassDef("Test")

      val expected = List(
        "classdef Test",
        "    ",
        "end",
        "")

      test(mclass, expected)
    }

    "render class attributes" in {
      val mclass = M.ClassDef("Test").attribs("Abstract")

      val expected = List(
        "classdef (Abstract) Test",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render class inheritance" in {
      val mclass = M.ClassDef("Test") from "handle"

      val expected = List(
        "classdef Test < handle",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render class comments" in {
      val mclass =
        M.ClassDef("Test")
          .%(
            "Test is a testing class",
            "which we are trying to test"
          )

      val expected = List(
        "classdef Test",
        "    % Test is a testing class",
        "    % which we are trying to test",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render class comments from list" in {
      val clist = List(
        "Test is a testing class",
        "which we are trying to test"
      )

      val mclass =
        M.ClassDef("Test")
          .comments(clist)

      val expected = List(
        "classdef Test",
        "    % Test is a testing class",
        "    % which we are trying to test",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render fully-decorated class" in {
      val mclass =
        M.ClassDef("Test").from("uint32", "TestSuper").attribs("Abstract", "Sealed")
          .%(
            "Test is a testing class",
            "which we are trying to test"
          )

      val expected = List(
        "classdef (Abstract, Sealed) Test < uint32 & TestSuper",
        "    % Test is a testing class",
        "    % which we are trying to test",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render class properties" in {
      val mclass =
        M.ClassDef("Test")
          .+(
            M.ClassProps()
              .%(
                "",
                "A very nice set of properties",
                ""
              )
          )

      val expected = List(
        "classdef Test",
        "    ",
        "    % ",
        "    % A very nice set of properties",
        "    % ",
        "    properties",
        "    end",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }
  }

  "M.ClassProps" should {

    "render empty properties" in {
      val mprops = M.ClassProps()

      val expected = List(
        "properties",
        "end",
        ""
      )

      test(mprops, expected)
    }

    "render property comments" in {
      val mprops =
        M.ClassProps()
          .%(
            "some lovely comments",
            "to test with"
          )

      val expected = List(
        "% some lovely comments",
        "% to test with",
        "properties",
        "end",
        "")

      test(mprops, expected)
    }

    "render properties" in {
      val mprops =
        M.ClassProps()
          .%("comment")
          .+(
            'prop1 %=% 3.14,
            'prop2 %=% "Test",
            'prop3 %=% 32,
            'prop4
          )

      val expected = List(
        "% comment",
        "properties",
        "    prop1 = 3.14",
        "    prop2 = 'Test'",
        "    prop3 = 32",
        "    prop4",
        "end",
        "")

      test(mprops, expected)
    }
  }

  /*
   * EXPRESSIONS
   */
  "M.Exp" should {

    "render assignments" in {
      test(
        'testVar %=% "testValue",
        "testVar = 'testValue'"
      )
    }

    "render global variables" in {
      test(
        M.Global('test),
        "global test"
      )
    }

    "render persistent variables" in {
      test(
        M.Persistent('test),
        "persistent test"
      )
    }

    "append ; at end of commands" in {
      val mexp = 'testVar %=% "testValue"
      val expected = "testVar = 'testValue';"

      val actual = mexp.toCommand

      actual should not be (null)
      actual should not be empty
      actual shouldBe expected
    }

    "render paren indexing" in {
      test(
        'x.paren(3),
        "x(3)"
      )
    }

    "render curly indexing" in {
      test(
        'c.curly(3),
        "c{3}"
      )
    }

    "render slice ranges" in {
      test(
        'v.paren(M.%:%),
        "v(:)"
      )

      test(
        'v.paren(3 %:% 4),
        "v(3:4)"
      )

      test(
        'v.paren(3 %:% 4 %:% 5),
        "v(3:4:5)"
      )

      test(
        'v.paren(3.%:%(4).%:%(5)),
        "v(3:4:5)"
      )
    }
  }
}

trait Helpers {
  this: WordSpec with Matchers with Inspectors =>

  protected def test(obj: MatRender, expected: String): Unit = {
    val actual = obj.toMatlab

    actual should not be (null)
    actual should not be empty
    actual shouldBe expected
  }

  protected def test(obj: MatRender, expected: List[String]): Unit = test(obj, expected.mkString("\n"))
}
