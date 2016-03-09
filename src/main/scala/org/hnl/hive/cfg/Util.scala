package org.hnl.hive.cfg

import grizzled.slf4j.Logging

/**
 * Util
 * <p>
 * Created on Mar 9, 2016.
 * <p>
 *
 * @author Jason White
 */
object Util extends Logging {

  /**
   * finds all files matching given filespec
   * @param spec filespec
   * @return list of matching file paths
   */
  def findPaths(spec: String): List[String] = try {
    val list = grizzled.file.util.eglob(spec)

    info(s"found ${list.length} matches for '${spec}'")

    list
  }
  catch {
    case e: NullPointerException => {
      warn(s"fileSpec $spec refers to nonexistent directory")
      Nil
    }
    case e: Throwable => {
      warn(s"${e.getClass.getName} while evaluating fileSpec $spec:")
      Nil
    }
  }

  /**
   * finds all files matching given filespec list
   * @param specs list of filespecs
   * @return list of lists of macthing file paths
   */
  def findPaths(specs: List[String]): List[List[String]] = specs.map { findPaths(_) }

  /**
   * returns the basename for the given path
   * @param path the path
   * @return the basename (last element) of the path
   */
  def basename(path: String): String = grizzled.file.util.basename(path, grizzled.file.util.fileSeparator)

  /**
   * returns list of basenames for the given path list
   * @param paths the list of paths
   * @return the basename (laste element) of the path
   */
  def basenames(paths: List[String]): List[String] = paths.map(basename(_))
}
