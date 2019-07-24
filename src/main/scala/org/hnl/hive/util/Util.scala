package org.hnl.hive.util

/**
  * Util
  * <p>
  * Created on Mar 10, 2016.
  * <p>
  *
  * @author Jason White
  */
object Util {
  /**
    * zips a nested list structure with an index
    *
    * @param ls The nested list structure
    * @param i  The initial index value
    * @return a nested list of tuples
    */
  def deepZip[A](ls: List[List[A]], i: Int = 0): List[List[(A, Int)]] = ls match {
    case Nil     => Nil
    case x :: xs => x.zip(Stream.from(i)) :: deepZip(xs, i + x.size)
  }
}
