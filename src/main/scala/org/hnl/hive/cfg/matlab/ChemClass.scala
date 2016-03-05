package org.hnl.hive.cfg.matlab

import org.hnl.matlab._
import org.hnl.matlab.MExp._
import org.hnl.matlab.M._

/**
 * Chem
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class Chem(ix: Int, colName: String, name: String, label: String, units: String, neutral: Double) extends Ordered[Chem] {

  def compare(that: Chem): Int = this.ix compare that.ix

}

// scalastyle:off multiple.string.literals

/**
 * ChemClass
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class ChemClass(chems: List[Chem], treatment: String) extends MatlabChunk with MatlabFormatting {

  /*
   * enumeration
   */
  protected val enum =
    M.ClassEnum()
      .%(
        "",
        "Valid chemicals for this treatment",
        ""
      )
      .members(chems.sorted.map { c => Fn(c.name, c.ix) })

  /*
   * methods
   */
  protected val methods = {
    ClassMethods()
      .+(
        FnDef("ix", 'this).returns('n)
          .doc("IX returns the index of this Chem")
          .+(
            'n %=% Fn("uint32", 'this)
          ),
        FnDef("colName", 'this).returns('s)
          .doc("COLNAME returns the column name of this Chem")
          .+(
            Persistent('a),
            'a %=% RCell(chems.sorted.map { c => Str(c.colName) }: _*),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("name", 'this).returns('s)
          .doc("NAME returns the name of this Chem")
          .+(
            's %=% Fn("char", 'this)
          ),
        FnDef("label", 'this).returns('s)
          .doc("LABEL returns the label of this Chem")
          .+(
            Persistent('a),
            'a %=% RCell(chems.sorted.map { c => Str(c.label) }: _*),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("units", 'this).returns('s)
          .doc("UNITS returns the units of this Chem")
          .+(
            Persistent('a),
            'a %=% RCell(chems.sorted.map { c => Str(c.units) }: _*),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("neutral", 'this).returns('n)
          .doc("NEUTRAL returns the neutral concentration of this Chem")
          .+(
            //Persistent('a),
            'a %=% RVec(chems.sorted.map { c => Num(c.neutral) }: _*),
            'n %=% 'a.paren('this ~> 'ix)
          )
      )
  }

  /*
   * class
   */
  protected val mClass =
    ClassDef("Chem").from("uint32", "ChemBase")
      .%(
        s"Chemicals for use in HIVE treatment '$treatment'",
        "",
        "It is convenient to subclass uint32 so that the chemical literals can be",
        "used as an index into a matrix, but we can't add properties to uint32.",
        "",
        "Therefore, we will add methods that perform lookups into persistent arrays",
        "which hold the properties for each chemical literal.",
        "",
        "This code was generated by scala."
      )
      .+(
        enum,
        methods
      )

  def toMatlab: String = mClass.toMatlab
}
