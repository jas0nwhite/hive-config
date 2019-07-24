package org.hnl.hive.cfg.matlab

import java.nio.file.{Path, Paths}
import org.hnl.matlab.M.ClassDef
import org.hnl.matlab.MExp
import org.hnl.matlab.M.ClassObj

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
  val pkg: String = "foo"

  def filePath: Path = {
    val file: List[String] = name + ".m" :: Nil
    val path: List[String] = if (pkg.isEmpty) file else pkg.split("[.]").map("+" + _).toList ::: file

    Paths.get(path.head, path.tail: _*)
  }

  def classObj: ClassObj = ClassObj(pkg, name)

  override def toMatlab: String = mClass.toMatlab
}
