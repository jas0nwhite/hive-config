package org.hnl.hive.cfg

import java.nio.file.FileSystems

import scala.collection.JavaConversions.asScalaBuffer

import com.typesafe.config.{ Config, ConfigList, ConfigValueType }

import grizzled.slf4j.Logging

/**
 * TreatmentConfig
 * <p>
 * Created on Feb 29, 2016.
 * <p>
 *
 * @author Jason White
 */
class TreatmentConfig(config: Config) extends Logging {

  /*
   * treatment settings
   */
  val trainingSetId = getRequiredString("treatment.training-set")
  val modelStyleId = getRequiredString("treatment.model-style")
  val clusterStyleId = getRequiredString("treatment.cluster-style")
  val alphaSelectId = getRequiredString("treatment.alpha-select")
  val muSelectId = getRequiredString("treatment.mu-select")

  /*
   * project settings
   */
  val projectRoot = getAbsolutePath("project.root")
  val trainingPath = getAbsolutePath("project.training-path")
  val modelPath = getAbsolutePath("project.model-path")
  val clusterPath = getAbsolutePath("project.cluster-path")
  val alphaPath = getAbsolutePath("project.alpha-path")
  val muPath = getAbsolutePath("project.mu-path")

  /*
   * training settings (allow multiple paths)
   */
  val trainingSourcePaths = getAbsolutePathList("training.source-path")
  val trainingResultPaths = getAbsolutePathList("training.result-path")

  /*
   * testing settings (allow multiple paths)
   */
  val testingSourcePaths = getAbsolutePathList("testing.source-path")
  val testingResultPaths = getAbsolutePathList("testing.result-path")

  /*
   * target settings (allow multiple paths)
   */
  val targetSourcePaths = getAbsolutePathList("target.source-path")
  val targetResultPaths = getAbsolutePathList("target.result-path")

  /*
   * computed fields
   */
  val hiveId = s"$trainingSetId-$modelStyleId-$clusterStyleId-$alphaSelectId-$muSelectId"

  /*
   * PUBLIC API
   */
  override def toString() = s"$hiveId @ $projectRoot"

  /*
   * INTERNAL API
   */
  protected def getRequiredString(key: String): String =
    try {
      config.getString(key)
    }
    catch {
      case e: Throwable => { error(s"error reading string value at $key", e); "" }
    }

  protected def getAbsolutePath(key: String): String =
    try {
      val dirs: List[String] = config.getStringList(key).toList
      toAbsolutePath(dirs)
    }
    catch {
      case e: Throwable => { error(s"error interpreting path at $key", e); "" }
    }

  protected def getAbsolutePathList(key: String): List[String] =
    try {
      val paths: ConfigList = config.getList(key)
      val kind: ConfigValueType = paths.get(0).valueType

      toAbsolutePathList(paths.unwrapped.toList, kind)
    }
    catch {
      case e: Throwable => { error(s"error interpreting path list at $key", e); Nil }
    }

  protected def toAbsolutePath(dirs: List[String]): String =
    FileSystems
      .getDefault
      .getPath(dirs.head, dirs.tail: _*)
      .toAbsolutePath
      .toString

  protected def toAbsolutePathList(list: List[Object], kind: ConfigValueType): List[String] = kind match {
    case ConfigValueType.LIST   => list.map { a => toAbsolutePath(a.asInstanceOf[java.util.ArrayList[String]].toList) }
    case ConfigValueType.STRING => List(toAbsolutePath(list.toList.asInstanceOf[List[String]]))
    case _                      => List(toAbsolutePath(list.map { _.toString }))
  }

}

object TreatmentConfig {

}
