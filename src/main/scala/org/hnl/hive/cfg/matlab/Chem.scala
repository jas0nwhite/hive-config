package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.matlab.M._
import org.hnl.matlab.MExp
import org.hnl.matlab.MExp._

/**
  * Chemical
  * <p>
  * Created on Mar 1, 2016.
  * <p>
  *
  * @author Jason White
  */
case class Chemical(ix: Int, colName: String, name: String, label: String, prefix: String, units: String, neutral: Double) extends Ordered[Chemical] {

  def compare(that: Chemical): Int = this.ix compare that.ix

}

/**
  * Chem
  * <p>
  * Created on Mar 1, 2016.
  * <p>
  *
  * @author Jason White
  */
case class Chem(name: String, chems: List[Chemical], treatment: String) extends MatClassFile {

  override val pkg: String = ""

  /*
   * enumeration
   */
  protected val enum: ClassEnum =
    ClassEnum()
      .%(
        "",
        "Valid chemicals for this treatment",
        ""
      )
      .members(chems.sorted.map { c => Fn(c.name, c.ix) })

  /*
   * methods
   */
  protected val methods: ClassMethods = {
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
            'a %=% RCell(
              chems.sorted.map { c => Str(c.colName) }: _*
            ),
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
            'a %=% RCell(
              chems.sorted.map { c => Str(c.label) }: _*
            ),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("prefix", 'this).returns('s)
          .doc("PREFIX returns the prefix of this Chem, suitable for variable or file names")
          .+(
            Persistent('a),
            'a %=% RCell(
              chems.sorted.map { c => Str(c.prefix) }: _*
            ),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("units", 'this).returns('s)
          .doc("UNITS returns the units of this Chem")
          .+(
            Persistent('a),
            'a %=% RCell(
              chems.sorted.map { c => Str(c.units) }: _*
            ),
            's %=% 'a.curly('this ~> 'ix)
          ),
        FnDef("neutral", 'this).returns('n)
          .doc("NEUTRAL returns the neutral concentration of this Chem")
          .+(
            Persistent('a),
            'a %=% RVec(
              chems.sorted.map { c => Num(c.neutral) }: _*
            ),
            'n %=% 'a.paren('this ~> 'ix)
          ),
        FnDef("format", 'this, 'pattern).returns('s)
          .doc("""FORMAT returns the pattern with fieldnames replaced with this chemical's information""")
          .+(
            's %=% 'pattern,
            %---%,
            's %=% Fn("strrep", 's, "{ix}", Fn("int2str", 'this ~> 'ix)),
            %---%,
            's %=% Fn("strrep", 's, "{ColName}", 'this ~> 'colName),
            's %=% Fn("strrep", 's, "{colname}", Fn("lower", 'this ~> 'colName)),
            's %=% Fn("strrep", 's, "{COLNAME}", Fn("upper", 'this ~> 'colName)),
            %---%,
            's %=% Fn("strrep", 's, "{Name}", 'this ~> 'name),
            's %=% Fn("strrep", 's, "{name}", Fn("lower", 'this ~> 'name)),
            's %=% Fn("strrep", 's, "{NAME}", Fn("upper", 'this ~> 'name)),
            %---%,
            's %=% Fn("strrep", 's, "{Label}", 'this ~> 'label),
            's %=% Fn("strrep", 's, "{label}", Fn("lower", 'this ~> 'label)),
            's %=% Fn("strrep", 's, "{LABEL}", Fn("upper", 'this ~> 'label)),
            %---%,
            's %=% Fn("strrep", 's, "{Prefix}", 'this ~> 'prefix),
            's %=% Fn("strrep", 's, "{prefix}", Fn("lower", 'this ~> 'prefix)),
            's %=% Fn("strrep", 's, "{PREFIX}", Fn("upper", 'this ~> 'prefix))
          )
      )
  }

  /*
   * class
   */
  override val mClass: ClassDef =
    ClassDef(name).from("uint32", "hive.cfg.ChemBase")
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
}

/**
  * Methods to extract the ChemClass object from the config object
  * <p>
  * Created on Mar 7, 2016.
  * <p>
  *
  * @author Jason White
  */
object Chem {

  def getChemList(config: TreatmentConfig): List[Chemical] = config.chemicals.map { c =>
    Chemical(
      c.getInt("ix"),
      c.getString("colName"),
      c.getString("name"),
      c.getString("label"),
      c.getString("prefix"),
      c.getString("units"),
      c.getDouble("neutral")
    )
  }

  def fromConfig(name: String, config: TreatmentConfig): Chem =
    Chem(name, getChemList(config), config.name)

}
