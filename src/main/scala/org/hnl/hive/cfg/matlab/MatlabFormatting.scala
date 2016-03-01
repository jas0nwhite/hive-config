package org.hnl.hive.cfg.matlab

/**
 * MatlabFormatting
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MatlabFormatting {

  /**
   * strings get quoted
   * @param value
   * @return
   */
  def lit(value: String): String = s"'${value.replaceAll("'", "''")}'"

  /**
   * numbers are naked
   * @param value
   * @return
   */
  def lit(value: AnyVal): String = s"$value"

  /**
   * lists of strings are cell arrays
   * @param values
   * @return
   */
  def cell(values: Seq[String]): String =
    "{ " + values.map { lit(_) }.mkString(", ") + " }"

  /**
   * lists of numbers are arrays
   * @param values
   * @return
   */
  def array(values: Seq[_ <: AnyVal]): String =
    "[ " + values.map { lit(_) }.mkString(", ") + " ]"

}
