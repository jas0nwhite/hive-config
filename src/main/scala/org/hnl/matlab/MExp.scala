package org.hnl.matlab

import scala.collection.mutable.ListBuffer
import scala.language.implicitConversions

// scalastyle:off multiple.string.literals

/**
 * Base trait for objects that can be rendered as Matlab code
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MatRender {
  def toMatlab: String

  protected[matlab] def mkString(s: String): String =
    "'" + s.replaceAll("'", "''") + "'"

  protected[matlab] def mkIdent(n: String): String =
    n.trim
      .replaceAll("^([^A-Za-z])", "x$1")
      .replaceAll("[^0-9A-Za-z_]", "_")
}

/**
 * Base trait for objects MatRender objects that need to
 * keep track of indentation during rendering
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MatRenderIndent extends MatRender {
  protected def tab(indent: Int): String =
    List.fill(indent * 4)(' ').mkString

  override def toMatlab: String = toMatlab(0)

  protected[matlab] def toMatlab(indent: Int): String
}

/**
 * Base trait for Matlab Expression
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MExp extends MatRender {

  override def toString: String =
    "Mexp(" + toMatlab + ")"

  def %=%(right: MExp): MExp = new MExp { // scalastyle:ignore method.name
    override def toMatlab: String = MExp.this.toMatlab + " = " + right.toMatlab
  }

  def paren(ix: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + "(" + ix.toMatlab + ")"
  }

  def curly(ix: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + "{" + ix.toMatlab + "}"
  }

  def %:%(right: MExp): MExp = new MExp { // scalastyle:ignore method.name
    override def toMatlab: String = MExp.this.toMatlab + ":" + right.toMatlab
  }

  def toMatCmd: String =
    toMatlab + ";"
}

/**
 * Companion object for implicits, etc
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
object MExp {
  implicit def strToMExp(v: String): MExp = M.Str(v)

  implicit def intToMExp(v: Int): MExp = M.Num(v)

  implicit def longToMExp(v: Long): MExp = M.Num(v)

  implicit def floatToMExp(v: Float): MExp = M.Num(v)

  implicit def doubleToMExp(v: Double): MExp = M.Num(v)

  implicit def booleanToMExp(v: Boolean): MExp = M.Num(v)
}

/**
 * Matlab DSL
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
object M {
  /*
   * RAW
   */
  case class Raw(s: String) extends MExp {
    override def toMatlab: String = s
  }

  /*
   * STRING
   */
  case class Str(s: String) extends MExp {
    override def toMatlab: String = mkString(s)
  }

  /*
   * NUMBERS
   */
  trait NumVal extends MExp

  /* convenient constructors for Num */
  object Num {
    def apply(b: Boolean): NumVal = b match {
      case true  => True()
      case false => False()
    }
    def apply(n: Int): NumI = new NumI(n)
    def apply(n: Long): NumI = new NumI(n)
    def apply(n: Float): NumD = new NumD(n)
    def apply(n: Double): NumVal = n match {
      case Double.NegativeInfinity => NegInf()
      case Double.PositiveInfinity => Inf()
      case Double.NaN              => NaN()
      case _                       => new NumD(n)
    }
    def apply(s: String): NumVal = s match {
      case "true"                                 => True()
      case "false"                                => False()
      case "-Inf"                                 => NegInf()
      case "Inf"                                  => Inf()
      case "NaN"                                  => NaN()
      case _ if s.forall { Character.isDigit(_) } => new NumI(s.toLong)
      case _                                      => new NumD(s.toDouble)
    }
  }

  case class NumI(num: Long) extends NumVal {
    override def toMatlab: String = num.toString
  }

  case class NumD(num: Double) extends NumVal {
    override def toMatlab: String = num.toString
  }

  case class NegInf() extends NumVal {
    override def toMatlab: String = "-Inf"
  }

  case class Inf() extends NumVal {
    override def toMatlab: String = "Inf"
  }

  case class NaN() extends NumVal {
    override def toMatlab: String = "NaN"
  }

  case class True() extends NumVal {
    override def toMatlab: String = "true"
  }

  case class False() extends NumVal {
    override def toMatlab: String = "false"
  }

  /*
   * IDENTIFIERS
   */
  case class Var(name: String) extends MExp {
    override def toMatlab: String = mkIdent(name)
  }

  /*
   * ARRAYS
   */
  case class RVec(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "[" + vals.map { _.toMatlab }.mkString(", ") + "]"
  }

  case class CVec(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "[" + vals.map { _.toMatlab }.mkString("; ") + "]"
  }

  case class RCell(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "{" + vals.map { _.toMatlab }.mkString(", ") + "}"
  }

  case class CCell(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "{" + vals.map { _.toMatlab }.mkString("; ") + "}"
  }

  case object %:% extends MExp { // scalastyle:ignore object.name
    override def toMatlab: String = ":"
  }

  /**
   * Trait for common code blocks
   * <p>
   * Created on Mar 2, 2016.
   * <p>
   *
   * @author Jason White
   */
  trait Block[+T, M] extends MatRenderIndent {
    self: T =>

    protected val comments = ListBuffer.empty[String]
    protected val attributes = ListBuffer.empty[String]
    protected val members = ListBuffer.empty[M]

    def attrib(attrString: String): T = {
      attributes.clear
      attributes += attrString
      self
    }

    def comment(commentString: String): T = {
      comments += "% " + commentString
      self
    }

    def member(m: M): T = {
      members += m
      self
    }

    // scalastyle:off method.name

    def +?(attrString: String): T = attrib(attrString)
    def +%(commentString: String): T = comment(commentString)
    def +#(m: M): T = member(m)

    // scalastyle:on method.name
  }

  /*
   * CLASS DEF
   */
  case class ClassDef(name: String) extends Block[ClassDef, MatRenderIndent] {
    protected val superclass = ListBuffer.empty[String]

    def from(parent: String): ClassDef = {
      superclass.clear
      superclass += parent
      this
    }

    def +<(parent: String): ClassDef = from(parent) // scalastyle:ignore method.name

    protected[matlab] def toMatlab(indent: Int): String = {
      val supc = superclass.map { " < " + _ }.mkString
      val attr = if (attributes.isEmpty) "" else attributes.mkString(" (", ", ", ")")

      // build code
      val code = ListBuffer.empty[String]

      // classdef
      code += "classdef " + mkIdent(name) + supc + attr

      // optional comments
      comments.foreach { code += tab(indent + 1) + _ }
      code += tab(indent + 1)

      // optional members
      members.foreach { code += _.toMatlab(indent + 1) }

      // end
      code += "end"
      code += ""

      // output
      code.map { tab(indent) + _ }.mkString("\n")
    }
  }

  /*
   * CLASS PROPERTIES
   */
  case class ClassProps() extends Block[ClassProps, MExp] {
    protected[matlab] def toMatlab(indent: Int): String = {
      val attr = attributes.map { " (" + _ + ")" }.mkString

      // build code
      val code = ListBuffer.empty[String]

      // comments
      comments.foreach { code += _ }

      // properties def
      code += "properties" + attr

      // members
      members.foreach { code += tab(indent + 1) + _.toMatlab(indent + 1) }

      // end
      code += "end"
      code += ""

      code.map { tab(indent) + _ }.mkString("\n")
    }
  }

}
