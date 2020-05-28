package org.hnl.hive.cfg

import org.hnl.hive.cfg.ConfigUtil.configToWrappedConfig

import com.typesafe.config.Config

import grizzled.slf4j.Logging

// scalastyle:off multiple.string.literals

/**
  * TreatmentConfig
  * <p>
  * Created on Feb 29, 2016.
  * <p>
  *
  * @author Jason White
  */
class TreatmentConfig protected(config: WrappedConfig) extends Logging {

  //
  // USER-SPECIFIED PROPERTIES
  //

  /*
   * treatment settings
   */
  val trainingSetId: String = config.getString("treatment.training-set")
  val trainingStyleId: String = config.getString("treatment.training-style")
  val clusterStyleId: String = config.getString("treatment.cluster-style")
  val alphaSelectId: String = config.getString("treatment.alpha-select")
  val muSelectId: String = config.getString("treatment.mu-select")
  val name: String = config.getString(
    "treatment.name",
    s"$trainingSetId-$trainingStyleId-$clusterStyleId-$alphaSelectId-$muSelectId")

  /*
   * project settings
   */
  val projectHome: String = config.getAbsolutePath("project.home")
  val trainingHome: String = config.getAbsolutePath("project.training-home")
  val testingHome: String = config.getAbsolutePath("project.testing-home")
  val modelHome: String = config.getAbsolutePath("project.model-home")
  val clusterHome: String = config.getAbsolutePath("project.cluster-home")
  val alphaHome: String = config.getAbsolutePath("project.alpha-home")
  val muHome: String = config.getAbsolutePath("project.mu-home")
  val codePath: List[String] = config.getAbsolutePathList("project.code-path")

  /*
   * training settings (allow multiple paths)
   */
  val training: InvitroConfig = InvitroConfig.fromConfig(config.getConfigObject("training"))
  val trainingIndexCloudFile: String = config.getAbsolutePath("training.index-cloud-file")

  /*
   * testing settings (allow multiple paths)
   */
  val testing: InvitroConfig = InvitroConfig.fromConfig(config.getConfigObject("testing"))
  val testingTrainingDataFile: String = config.getString("testing.training-data-file")
  val testingPredicitonFile: String = config.getString("testing.prediction-file")

  /*
   * target settings (allow multiple paths)
   */
  val targetSourceSpecs: List[String] = config.getAbsolutePathList("target.source-spec")
  val targetResultPaths: List[String] = config.getAbsolutePathList("target.result-path")
  val targetTrainingDataFile: String = config.getString("target.training-data-file")
  val targetPredicitonSpec: String = config.getString("target.prediction-spec")
  val targetVgramWindows: List[List[Int]] = config.getIntVectorList("target.vgram-window")

  /*
   * chemicals
   */
  val chemicals: List[WrappedConfig] = config.getObjectList("chemicals")

  //
  // CALCULATED PROPERTIES
  //

  /*
   * target catalog
   */
  val targetSourceCatalog: List[List[String]] = Util.findPaths(targetSourceSpecs)
  val targetDatasetCatalog: List[List[String]] = targetSourceCatalog.map(Util.basenames)

  //
  // PUBLIC API
  //

  override def toString: String = s"$name @ $projectHome"

  //
  // INTERNAL API
  //

}

object TreatmentConfig {

  def fromConfig(config: Config): TreatmentConfig = new TreatmentConfig(config)

}
