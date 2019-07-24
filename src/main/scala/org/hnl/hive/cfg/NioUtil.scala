package org.hnl.hive.cfg

import java.nio.file.{FileSystems, Files, Path, Paths}
import java.nio.file.attribute.BasicFileAttributes

import scala.language.implicitConversions

/**
  * Utilities for finding files using java.nio
  * <p>
  * Created on Mar 10, 2016.
  * <p>
  *
  * @author Jason White
  */
object NioUtil {

  /**
    * convenience function to find folders (and links to folders) that match the pathSpec
    *
    * @param pathSpec the root directory and optional filespec (in "glob" syntax)
    * @param depth    optional max depth
    * @return list of paths that match
    */
  def findFolders(pathSpec: String, depth: Int = Int.MaxValue): List[String] =
    find(pathSpec, depth)((p: Path, a: BasicFileAttributes) => Files.isDirectory(p) /* follows links */)

  /**
    * convenience function to find files (and links to files) that match the pathSpec
    *
    * @param pathSpec the root directory and optional filespec (in "glob" syntax)
    * @param depth    optional max depth
    * @return list of paths that match
    */
  def findFiles(pathSpec: String, depth: Int = Int.MaxValue): List[String] =
    find(pathSpec, depth)((p: Path, a: BasicFileAttributes) => Files.isRegularFile(p) /* follows links */)

  /**
    * finds all directory entries that match the pathSpec and pass the check
    *
    * @param pathSpec the root directory and optional filespec (in "glob" syntax)
    * @param depth    optional max depth
    * @param check    optional attribute check
    * @return list of paths that match
    */
  def find(pathSpec: String, depth: Int = Int.MaxValue)(check: (Path, BasicFileAttributes) => Boolean = (_, _) => true): List[String] = {
    val path = Paths.get(pathSpec)
    val root = path.getParent

    find(root, pathSpec, depth)(check).map { p: Path => p.toString }
  }

  /**
    * uses java.nio to find directory entries starting at root, matching given spec, at given depth
    *
    * @param root  the root Path to start the search
    * @param spec  the spec to match (in "glob" syntax)
    * @param depth the maximum depth
    * @param check function to use for additional matching based on file attributes
    * @return list of Paths
    */
  protected def find(root: Path, spec: String, depth: Int)(check: (Path, BasicFileAttributes) => Boolean): List[Path] = {
    val matcher = FileSystems.getDefault.getPathMatcher("glob:" + spec)

    val test = new java.util.function.BiPredicate[Path, BasicFileAttributes] {
      def test(path: Path, attrs: BasicFileAttributes): Boolean =
        check(path, attrs) && matcher.matches(path)
    }

    Files.find(root, depth, test).toArray().map { o: Object => o.asInstanceOf[Path] }.toList
  }

}
