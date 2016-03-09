package org.hnl.hive.cfg

import java.nio.file.FileSystems
import scala.collection.JavaConversions.asScalaBuffer
import com.typesafe.config.{ Config, ConfigList, ConfigValueType }
import grizzled.slf4j.Logging
import com.typesafe.config.ConfigValue
import com.typesafe.config.ConfigObject
import java.util.ArrayList

// scalastyle:off multiple.string.literals

/**
 * TreatmentConfig
 * <p>
 * Created on Feb 29, 2016.
 * <p>
 *
 * @author Jason White
 */
class TreatmentConfig protected (config: Config) extends Logging {

  //
  // USER-SPECIFIED PROPERTIES
  //

  /*
   * treatment settings
   */
  val trainingSetId = getString("treatment.training-set")
  val trainingStyleId = getString("treatment.training-style")
  val clusterStyleId = getString("treatment.cluster-style")
  val alphaSelectId = getString("treatment.alpha-select")
  val muSelectId = getString("treatment.mu-select")
  val name = getString("treatment.name", s"$trainingSetId-$trainingStyleId-$clusterStyleId-$alphaSelectId-$muSelectId")

  /*
   * project settings
   */
  val projectHome = getAbsolutePath("project.home")
  val trainingHome = getAbsolutePath("project.training-home")
  val modelHome = getAbsolutePath("project.model-home")
  val clusterHome = getAbsolutePath("project.cluster-home")
  val alphaHome = getAbsolutePath("project.alpha-home")
  val muHome = getAbsolutePath("project.mu-home")

  /*
   * training settings (allow multiple paths)
   */
  val trainingSourceSpecs = getAbsolutePathList("training.source-spec")
  val trainingResultPaths = getAbsolutePathList("training.result-path")

  /*
   * testing settings (allow multiple paths)
   */
  val testingSourceSpecs = getAbsolutePathList("testing.source-spec")
  val testingResultPaths = getAbsolutePathList("testing.result-path")

  /*
   * target settings (allow multiple paths)
   */
  val targetSourceSpecs = getAbsolutePathList("target.source-spec")
  val targetResultPaths = getAbsolutePathList("target.result-path")

  /*
   * chemicals
   */
  val chemicals = config.getObjectList("chemicals").toList

  //
  // CALCULATED PROPERTIES
  //

  /*
   * training catalog
   */
  val trainingSourceCatalog = Util.findPaths(trainingSourceSpecs)
  val trainingDatasetCatalog = trainingSourceCatalog.map(Util.basenames(_))

  /*
   * testing catalog
   */
  val testingSourceCatalog = Util.findPaths(testingSourceSpecs)
  val testingDatasetCatalog = testingSourceCatalog.map(Util.basenames(_))

  /*
   * target catalog
   */
  val targetSourceCatalog = Util.findPaths(targetSourceSpecs)
  val targetDatasetCatalog = targetSourceCatalog.map(Util.basenames(_))

  //
  // PUBLIC API
  //

  override def toString: String = s"$name @ $projectHome"

  //
  // INTERNAL API
  //

  protected def getString(key: String): String =
    config.getString(key)

  protected def getString(key: String, fallback: String): String =
    if (config.hasPath(key)) {
      config.getString(key)
    }
    else {
      info(s"no value found for '${key}', using '${fallback}'")
      fallback
    }

  protected def getAbsolutePath(key: String): String =
    toAbsolutePath(config.getString(key))

  protected def getAbsolutePathList(key: String): List[String] = {
    val value: ConfigValue = config.getValue(key)
    val kind: ConfigValueType = value.valueType

    kind match {
      case ConfigValueType.LIST => value.unwrapped().asInstanceOf[ArrayList[_]].toList.map { v => toAbsolutePath(v.toString) }
      case ConfigValueType.NULL => Nil
      case _                    => List(toAbsolutePath(value.unwrapped().toString))
    }
  }

  protected def toAbsolutePath(dir: String): String =
    FileSystems
      .getDefault
      .getPath(dir)
      .toAbsolutePath
      .toString
}

object TreatmentConfig {

  def fromConfig(config: Config): TreatmentConfig = new TreatmentConfig(config)

}
