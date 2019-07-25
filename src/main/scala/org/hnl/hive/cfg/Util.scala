package org.hnl.hive.cfg

import java.nio.file.Paths
import java.util
import java.util.StringTokenizer

import grizzled.file.{util => GF}
import grizzled.slf4j.Logging

import scala.collection.JavaConverters._

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
    *
    * @param spec filespec
    * @return list of matching file paths
    */
  def findPaths(spec: String): List[String] = try {
    val list = GF.eglob(spec)

    debug(s"found ${list.length} matches for '$spec'")

    list
  }
  catch {
    case e: NullPointerException =>
      warn(s"fileSpec $spec refers to nonexistent directory")
      Nil

    case e: Throwable =>
      warn(s"${e.getClass.getName} while evaluating fileSpec $spec:")
      Nil
  }

  /**
    * finds all files matching given filespec list
    *
    * @param specs list of filespecs
    * @return list of lists of macthing file paths
    */
  def findPaths(specs: List[String]): List[List[String]] = specs.map {
    findPaths
  }

  /**
    * returns the basename for the given path
    *
    * @param path the path
    * @return the basename (last element) of the path
    */
  def basename(path: String): String = Paths.get(path).getFileName.toString

  /**
    * returns the name of the parent directory for the given path
    *
    * @param path the bath
    * @return the parent name (path minus last element)
    */
  def dirname(path: String): String = Paths.get(path).getParent.toString

  /**
    * returns list of basenames for the given path list
    *
    * @param paths the list of paths
    * @return the basename (laste element) of the path
    */
  def basenames(paths: List[String]): List[String] = paths.map(basename)


  /**
    * returns a list representing the parts and separators of a filepath
    *
    * @param filePath the path in string value (Java-style)
    * @return a list of parts and separators for the path
    */
  def splitPath(filePath: String): List[String] = new StringTokenizer(
    GF.normalizePath(GF.universalPath(filePath)), "/.", true)
    .asInstanceOf[util.Enumeration[String]]
    .asScala
    .toList
}
