package org.hnl.hive.cfg.matlab

/**
 * ChemClass
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class ChemClass(ix: Int, colName: String, name: String, label: String, units: String, neutral: Double) extends Ordered[ChemClass] {

  def compare(that: ChemClass): Int = this.ix compare that.ix

}
