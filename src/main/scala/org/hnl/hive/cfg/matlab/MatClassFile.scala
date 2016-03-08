package org.hnl.hive.cfg.matlab

import org.hnl.matlab.MExp
import org.hnl.matlab.M.ClassDef

/**
 * MatFile
 * <p>
 * Created on Mar 8, 2016.
 * <p>
 *
 * @author Jason White
 */
trait MatClassFile extends MExp {
  val name: String
  val mClass: ClassDef
}
