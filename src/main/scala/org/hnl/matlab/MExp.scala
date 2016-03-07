package org.hnl.matlab // scalastyle:ignore number.of.types

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
  protected def tab(indent: Int): String =
    List.fill(indent * 4)(' ').mkString

  protected[matlab] def mkString(s: String): String =
    "'" + s.replaceAll("'", "''") + "'"

  def toMatlab: String
  def toCommand: String = toMatlab + ";"

  protected[matlab] def toIndentedMatlab(indent: Int): List[String] = toMatlab.split("\n").map { tab(indent) + _ }.toList
  protected[matlab] def toIndentedCommand(indent: Int): List[String] = toCommand.split("\n").map { tab(indent) + _ }.toList
}

object MatRender {
  protected[matlab] def mkIdent(n: String): String =
    n.trim
      .replaceAll("^([^A-Za-z])", "x$1")
      .replaceAll("[^0-9A-Za-z_]", "_")
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

  def assign(right: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + " = " + right.toMatlab
  }

  def paren(ix: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + "(" + ix.toMatlab + ")"
  }

  def curly(ix: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + "{" + ix.toMatlab + "}"
  }

  def colon(right: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + ":" + right.toMatlab
  }

  def dot(right: MExp): MExp = new MExp {
    override def toMatlab: String = MExp.this.toMatlab + "." + right.toMatlab
  }

  // scalastyle:off method.name

  // DSL infix operators
  def %=%(right: MExp): MExp = assign(right)
  def %:%(right: MExp): MExp = colon(right)
  def ~>(right: MExp): MExp = dot(right)

  // scalastyle:on method.name
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
  implicit def strToMExp(v: String): M.Str = M.Str(v)

  implicit def intToMExp(v: Int): MExp = M.Num(v)

  implicit def longToMExp(v: Long): MExp = M.Num(v)

  implicit def floatToMExp(v: Float): MExp = M.Num(v)

  implicit def doubleToMExp(v: Double): MExp = M.Num(v)

  implicit def booleanToMExp(v: Boolean): MExp = M.Num(v)

  implicit def symbolToMExp(v: Symbol): M.Var = M.Var(v.name)

  implicit def stringListToMExp(l: List[String]): List[M.Str] = l.map { v => M.Str(v) }.toList

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
    override def toCommand: String = s
  }

  case object %---% extends MExp { // scalastyle:ignore object.name
    override def toMatlab: String = ""
    override def toCommand: String = ""
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
   * VARIABLES
   */
  case class Var(name: String) extends MExp {
    override def toMatlab: String = MatRender.mkIdent(name)
  }

  case class Global(v: Var) extends MExp {
    override def toMatlab: String = "global " + v.toMatlab
  }

  case class Persistent(v: Var) extends MExp {
    override def toMatlab: String = "persistent " + v.toMatlab
  }

  /*
   * ARRAYS
   */
  case class Row(vals: MExp*) extends MExp {
    override def toMatlab: String =
      vals.map { _.toMatlab }.mkString(", ")
  }

  case class RVec(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "[" + vals.map { _.toMatlab }.mkString(", ") + "]"
  }

  case class CVec(vals: MExp*) extends MExp {
    override def toMatlab: String =
      if (vals.length < 2) {
        vals.map { _.toMatlab }.mkString("[", ";", "]")
      }
      else {
        vals.map { _.toIndentedMatlab(1).mkString("\n") }.mkString("[\n", ";\n", "\n]")
      }
  }

  case class RCell(vals: MExp*) extends MExp {
    override def toMatlab: String =
      "{" + vals.map { _.toMatlab }.mkString(", ") + "}"
  }

  case class CCell(vals: MExp*) extends MExp {
    override def toMatlab: String =
      if (vals.length < 2) {
        vals.map { _.toMatlab }.mkString("{", ";", "}")
      }
      else {
        vals.map { _.toIndentedMatlab(1).mkString("\n") }.mkString("{\n", ";\n", "\n}")
      }
  }

  case object %:% extends MExp { // scalastyle:ignore object.name
    override def toMatlab: String = ":"
  }

  /*
   * FUNCTION CALL
   */
  case class Fn(fn: String, args: MExp*) extends MExp {
    override def toMatlab: String =
      fn + "(" + args.map { _.toMatlab }.mkString(",") + ")"
  }

  /**
   * Trait for common code blocks
   * <p>
   * Created on Mar 2, 2016.
   * <p>
   *
   * @author Jason White
   */
  trait Block[+T, M] extends MExp {
    self: T =>

    protected val commentBuffer = ListBuffer.empty[String]
    protected val attributeBuffer = ListBuffer.empty[String]
    protected val memberBuffer = ListBuffer.empty[M]

    def attribs(av: String*): T = {
      av.foreach { attributeBuffer += _ }
      self
    }

    def attribs(as: List[String]): T = attribs(as: _*)

    def comments(sv: String*): T = {
      sv.foreach { commentBuffer += "% " + _ }
      self
    }

    def comments(ss: List[String]): T = comments(ss: _*)

    def members(mv: M*): T = {
      mv.foreach { memberBuffer += _ }
      self
    }

    def members(ms: List[M]): T = members(ms: _*)

    // scalastyle:off method.name
    def %(sv: String*): T = comments(sv: _*)
    def +(mv: M*): T = members(mv: _*)
    // scalastyle:on method.name
  }

  /*
   * FUNCTION DEF
   */
  case class FnDef(name: String, args: MExp*) extends Block[FnDef, MExp] {
    protected val returnBuffer = ListBuffer.empty[String]
    protected val docBuffer = ListBuffer.empty[String]

    //    def returns(vars: String*): FnDef = {
    //      vars.foreach { returnBuffer += MatRender.mkIdent(_) }
    //      this
    //    }
    //    def returns(vars: List[String]): FnDef = returns(vars: _*)
    //    def returns(first: Var, others: Var*): FnDef = returns({ first :: others.toList }.map { _.toMatlab })

    def returns(first: Var, others: Var*): FnDef = {
      (first :: others.toList).foreach { v => returnBuffer += v.toMatlab }
      this
    }

    def doc(ss: String*): FnDef = {
      ss.foreach { docBuffer += "% " + _ }
      this
    }

    override def toMatlab: String = toIndentedMatlab(0).mkString("\n")

    override protected[matlab] def toIndentedMatlab(indent: Int): List[String] = {
      val rtnVars = returnBuffer.length match {
        case 0 => ""
        case 1 => returnBuffer.mkString(" ", "", " = ")
        case _ => returnBuffer.mkString(" [", ",", "] = ")
      }

      val argVars = args.map { _.toMatlab }.mkString("(", ", ", ")")

      if (!docBuffer.isEmpty) {
        docBuffer += ""
      }

      // build code
      val code = ListBuffer.empty[String]

      // comments
      commentBuffer.foreach { code += _ }

      // function def
      code += "function" + rtnVars + name + argVars

      // function doc
      docBuffer.foreach { code += tab(1) + _ }

      // members
      memberBuffer.foreach { code ++= _.toIndentedCommand(1) }

      // end
      code += "end"
      code += ""

      code.map { tab(indent) + _ }.toList
    }
  }

  /*
   * CLASS DEF
   */
  case class ClassDef(name: String) extends Block[ClassDef, MExp] {
    protected val superclasses = ListBuffer.empty[String]

    def from(parents: String*): ClassDef = {
      parents.foreach(superclasses += _)
      this
    }

    def from(parents: List[String]): ClassDef = from(parents: _*)

    override def toMatlab: String = toIndentedMatlab(0).mkString("\n")

    override protected[matlab] def toIndentedMatlab(indent: Int): List[String] = {
      val supc = if (superclasses.isEmpty) "" else superclasses.mkString(" < ", " & ", "")
      val attr = if (attributeBuffer.isEmpty) "" else attributeBuffer.mkString("(", ", ", ") ")

      // build code
      val code = ListBuffer.empty[String]

      // classdef
      code += "classdef " + attr + MatRender.mkIdent(name) + supc

      // optional comments
      commentBuffer.foreach { code += tab(indent + 1) + _ }
      code += tab(indent + 1)

      // optional members
      memberBuffer.foreach { (code ++= _.toIndentedMatlab(1)) }

      // end
      code += "end"
      code += ""

      // output
      code.map { tab(indent) + _ }.toList
    }
  }

  /*
   * CLASS ENUMERATION
   */
  case class ClassEnum() extends Block[ClassEnum, MExp] {

    override def toMatlab: String = toIndentedMatlab(0).mkString("\n")

    override protected[matlab] def toIndentedMatlab(indent: Int): List[String] = {
      // build code
      val code = ListBuffer.empty[String]

      // comments
      commentBuffer.foreach { code += _ }

      // enum def
      code += "enumeration"

      // members
      memberBuffer.foreach { code ++= _.toIndentedMatlab(1) }

      // end
      code += "end"
      code += ""

      code.map { tab(indent) + _ }.toList
    }
  }

  /*
   * CLASS PROPERTIES
   */
  case class ClassProps() extends Block[ClassProps, MExp] {
    override def toMatlab: String = toIndentedMatlab(0).mkString("\n")

    override protected[matlab] def toIndentedMatlab(indent: Int): List[String] = {
      val attr = if (attributeBuffer.isEmpty) "" else attributeBuffer.mkString(" (", ", ", ")")

      // build code
      val code = ListBuffer.empty[String]

      // comments
      commentBuffer.foreach { code += _ }

      // properties def
      code += "properties" + attr

      // members
      memberBuffer.foreach { code ++= _.toIndentedMatlab(1) }

      // end
      code += "end"
      code += ""

      code.map { tab(indent) + _ }.toList
    }
  }

  /*
   * CLASS METHODS
   */
  case class ClassMethods() extends Block[ClassMethods, MExp] {
    override def toMatlab: String = toIndentedMatlab(0).mkString("\n")

    override protected[matlab] def toIndentedMatlab(indent: Int): List[String] = {
      val attr = if (attributeBuffer.isEmpty) "" else attributeBuffer.mkString(" (", ", ", ")")

      // build code
      val code = ListBuffer.empty[String]

      // comments
      commentBuffer.foreach { code += _ }

      // properties def
      code += "methods" + attr

      // members
      memberBuffer.foreach { code ++= _.toIndentedMatlab(1) }

      // end
      code += "end"
      code += ""

      code.map { tab(indent) + _ }.toList
    }
  }

}
