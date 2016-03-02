package org.hnl.matlab

import scala.language.implicitConversions

/**
 * Base trait for Matlab Expression
 * <p>
 * Created on Mar 2, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MExp {

  def toMatlab: String

  override def toString: String =
    "Mexp(" + toMatlab + ")"

  def %=%(right: MExp): MExp = new MExp {
    def toMatlab: String = MExp.this.toMatlab + " = " + right.toMatlab
  }

  def paren(ix: MExp): MExp = new MExp {
    def toMatlab: String = MExp.this.toMatlab + "(" + ix.toMatlab + ")"
  }

  def curly(ix: MExp): MExp = new MExp {
    def toMatlab: String = MExp.this.toMatlab + "{" + ix.toMatlab + "}"
  }

  def %:%(right: MExp): MExp = new MExp {
    def toMatlab: String = MExp.this.toMatlab + ":" + right.toMatlab
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
    def toMatlab: String = s
  }

  /*
   * STRING
   */
  case class Str(s: String) extends MExp {
    def toMatlab: String = "'" + s.replaceAll("'", "''") + "'"
  }

  /*
   * NUMBERS
   */
  trait NumVal extends MExp {

  }

  /* convenient constructors for Num */
  object Num {
    def apply(b: Boolean) = b match {
      case true  => True()
      case false => False()
    }
    def apply(n: Int) = new NumI(n)
    def apply(n: Long) = new NumI(n)
    def apply(n: Float) = new NumD(n)
    def apply(n: Double) = n match {
      case Double.NegativeInfinity => NegInf()
      case Double.PositiveInfinity => Inf()
      case Double.NaN              => NaN()
      case _                       => new NumD(n)
    }
    def apply(s: String) = s match {
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
    def toMatlab: String = num.toString
  }

  case class NumD(num: Double) extends NumVal {
    def toMatlab: String = num.toString
  }

  case class NegInf() extends NumVal {
    def toMatlab: String = "-Inf"
  }

  case class Inf() extends NumVal {
    def toMatlab: String = "Inf"
  }

  case class NaN() extends NumVal {
    def toMatlab: String = "NaN"
  }

  case class True() extends NumVal {
    def toMatlab: String = "true"
  }

  case class False() extends NumVal {
    def toMatlab: String = "false"
  }

  /*
   * IDENTIFIERS
   */
  case class Var(name: String) extends MExp {
    // fixes up names like matlab.lang.makeValidName
    def toMatlab: String =
      name
        .trim
        .replaceAll("^([^A-Za-z])", "x$1")
        .replaceAll("[^0-9A-Za-z_]", "_")
  }

  /*
   * ARRAYS
   */
  case class RVec(vals: MExp*) extends MExp {
    def toMatlab: String =
      "[" + vals.map { _.toMatlab }.mkString(", ") + "]"
  }

  case class CVec(vals: MExp*) extends MExp {
    def toMatlab: String =
      "[" + vals.map { _.toMatlab }.mkString("; ") + "]"
  }

  case class RCell(vals: MExp*) extends MExp {
    def toMatlab: String =
      "{" + vals.map { _.toMatlab }.mkString(", ") + "}"
  }

  case class CCell(vals: MExp*) extends MExp {
    def toMatlab: String =
      "{" + vals.map { _.toMatlab }.mkString("; ") + "}"
  }

  case object %:% extends MExp {
    def toMatlab: String = ":"
  }

}
