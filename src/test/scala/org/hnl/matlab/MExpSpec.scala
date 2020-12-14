package org.hnl.matlab

import org.hnl.matlab.M._
import org.hnl.matlab.MExp._
import org.scalatest._
import wordspec._
import matchers.should._

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
class MExpSpec extends AnyWordSpec with Matchers with Inspectors with Helpers {

  /*
   * NUMBERS
   */
  "Num" should {
    "represent a number" in {
      test(Num(3), "3")
      test(Num(3.5), "3.5")
      test(Num(-3.5), "-3.5")
    }

    "represent a number from a string" in {
      test(Num("3"), "3")
      test(Num("3.5"), "3.5")
      test(Num("-3.5"), "-3.5")
      test(Num("Inf"), "Inf")
      test(Num("-Inf"), "-Inf")
      test(Num("NaN"), "NaN")
      test(Num("true"), "true")
      test(Num("false"), "false")
    }

    "represent extremes" in {
      test(Num(Double.NegativeInfinity), "-Inf")
      test(Num(Double.PositiveInfinity), "Inf")
      test(Num(Double.NaN), "NaN")
    }

    "represent booleans" in {
      test(Num(true), "true")
      test(Num(false), "false")
    }
  }

  /*
   * STRINGS
   */
  "Str" should {
    "represent a string in single quotes" in {
      test(Str("test"), "'test'")
    }

    "represent an empty string" in {
      test(Str(""), "''")
    }

    "represent a string with escaped quotes" in {
      test(Str("Jason's Test\\n"), "'Jason''s Test\\n'")
    }
  }

  /*
   * RAW
   */
  "Raw" should {

    "echo the contents" in {
      val contents = "for i = 1:10; fprintf('the \"value\" is %d\\n', i); end;"

      test(Raw(contents), contents)
    }
  }

  /*
   * IDENTIFIERS
   */
  "Var" should {

    "render valid identifier unchanged" in {
      test('test, "test")
    }

    "strip spaces from identifier" in {
      test(Var(" strip  "), "strip")
    }

    "append 'x' before non-alpha initial characters" in {
      test(Var("2isnotgood"), "x2isnotgood")
      test(Var("#3"), "x_3")
    }

    "replace non alpha-numeric-underscore characters with underscores" in {
      test(Var("four score and 7 years ago... 'Abe'"), "four_score_and_7_years_ago_____Abe_")
    }
  }

  /*
   * ARRAYS
   */
  "CVec" should {

    "render empty array" in {
      test(CVec(), "[]")
    }

    "render single-valued array" in {
      test(CVec(3), "[3]")
    }

    "render multi-valued column array" in {
      test(
        CVec(1, 2, 3, 4, 5),
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
        CVec(CVec(1, 2), CVec(3, 4)),
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
        CVec(
          Row(1, 2, 3),
          Row(4, 5, 6),
          Row(7, 8, 9)
        ),
        """|[
           |    1, 2, 3;
           |    4, 5, 6;
           |    7, 8, 9
           |]""".stripMargin
      )
    }
  }

  "RVec" should {
    "render empty array" in {
      test(RVec(), "[]")
    }

    "render single-valued array" in {
      test(RVec(3), "[3]")
    }

    "render multi-valued column array" in {
      test(RVec(1, 2, 3, 4, 5), "[1, 2, 3, 4, 5]")
    }

    "render nested arrays" in {
      test(RVec(RVec(1, 2), RVec(3, 4)), "[[1, 2], [3, 4]]")
    }
  }

  "CCell" should {

    "render empty array" in {
      test(CCell(), "{}")
    }

    "render single-valued array" in {
      test(CCell(3), "{3}")
    }

    "render multi-valued column array" in {
      test(CCell(1, 2, 3, 4, 5),
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
        CCell(CCell(1, 2), CCell(3, 4)),
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
      CCell(
        Row("test", 1.2, 1.3),
        Row("val", 3, 17),
        Row("mike", 21, 8.8)
      ),
      """|{
         |    'test', 1.2, 1.3;
         |    'val', 3, 17;
         |    'mike', 21, 8.8
         |}""".stripMargin
    )
  }

  "RCell" should {
    "render empty array" in {
      test(RCell(), "{}")
    }

    "render single-valued array" in {
      test(RCell(3), "{3}")
    }

    "render multi-valued column array" in {
      test(RCell(1, 2, 3, 4, 5), "{1, 2, 3, 4, 5}")
    }

    "render nested arrays" in {
      test(RCell(RCell(1, 2), RCell(3, 4)), "{{1, 2}, {3, 4}}")
    }
  }

  /*
   * CLASSES
   */
  "Class" should {

    "render empty class" in {
      val mclass = ClassDef("Test")

      val expected = List(
        "classdef Test",
        "    ",
        "end",
        "")

      test(mclass, expected)
    }

    "render class attributes" in {
      val mclass = ClassDef("Test").attribs("Abstract")

      val expected = List(
        "classdef (Abstract) Test",
        "    ",
        "end",
        ""
      )

      test(mclass, expected)
    }

    "render class inheritance" in {
      val mclass = ClassDef("Test") from "handle"

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
        ClassDef("Test")
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
        ClassDef("Test")
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
        ClassDef("Test").from("uint32", "TestSuper").attribs("Abstract", "Sealed")
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
        ClassDef("Test")
          .+(
            ClassProps()
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

  "ClassProps" should {

    "render empty properties" in {
      val mprops = ClassProps()

      val expected = List(
        "properties",
        "end",
        ""
      )

      test(mprops, expected)
    }

    "render property comments" in {
      val mprops =
        ClassProps()
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
        ClassProps()
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

  "Fn" should {

    "render zero-arg call" in {
      test(
        Fn("test"),
        "test()"
      )
    }

    "render one-arg call" in {
      test(
        Fn("test1", 'x),
        "test1(x)"
      )
    }

    "render multi-arg call" in {
      test(
        Fn("test3", 'x, 'y, 'z),
        "test3(x, y, z)"
      )
    }
  }

  /*
   * EXPRESSIONS
   */
  "Exp" should {

    "render assignments" in {
      test(
        'testVar %=% "testValue",
        "testVar = 'testValue'"
      )
    }

    "render global variables" in {
      test(
        Global('test),
        "global test"
      )
    }

    "render persistent variables" in {
      test(
        Persistent('test),
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
        'v.paren(%::%),
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
  this: AnyWordSpec with Matchers with Inspectors =>

  protected def test(obj: MatRender, expected: String): Unit = {
    val actual = obj.toMatlab

    actual should not be (null)
    actual should not be (empty)
    actual shouldBe (expected)
  }

  protected def test(obj: MatRender, expected: List[String]): Unit = test(obj, expected.mkString("\n"))
}
