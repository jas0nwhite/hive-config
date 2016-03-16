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
class TreatmentConfig protected (config: WrappedConfig) extends Logging {

  //
  // USER-SPECIFIED PROPERTIES
  //

  /*
   * treatment settings
   */
  val trainingSetId = config.getString("treatment.training-set")
  val trainingStyleId = config.getString("treatment.training-style")
  val clusterStyleId = config.getString("treatment.cluster-style")
  val alphaSelectId = config.getString("treatment.alpha-select")
  val muSelectId = config.getString("treatment.mu-select")
  val name = config.getString("treatment.name", s"$trainingSetId-$trainingStyleId-$clusterStyleId-$alphaSelectId-$muSelectId")

  /*
   * project settings
   */
  val projectHome = config.getAbsolutePath("project.home")
  val trainingHome = config.getAbsolutePath("project.training-home")
  val testingHome = config.getAbsolutePath("project.testing-home")
  val modelHome = config.getAbsolutePath("project.model-home")
  val clusterHome = config.getAbsolutePath("project.cluster-home")
  val alphaHome = config.getAbsolutePath("project.alpha-home")
  val muHome = config.getAbsolutePath("project.mu-home")
  val codePath = config.getAbsolutePathList("project.code-path")

  /*
   * training settings (allow multiple paths)
   */
  val trainingSourceSpecs = config.getAbsolutePathList("training.source-spec")
  val trainingResultPaths = config.getAbsolutePathList("training.result-path")
  val trainingLabelCatalogFile = config.getString("training.label-catalog-file")
  val trainingRawSpec = config.getString("training.raw-spec")
  val trainingLabelSpec = config.getString("training.label-spec")
  val trainingVgramFile = config.getString("training.vgram-file")
  val trainingLabelFile = config.getString("training.label-file")
  val trainingVgramWindows = config.getIntVectorList("training.vgram-window")
  val trainingTimeWindows = config.getIntVectorList("training.time-window")

  /*
   * testing settings (allow multiple paths)
   */
  val testingSourceSpecs = config.getAbsolutePathList("testing.source-spec")
  val testingResultPaths = config.getAbsolutePathList("testing.result-path")
  val testingLabelCatalogFile = config.getString("testing.label-catalog-file")
  val testingRawSpec = config.getString("testing.raw-spec")
  val testingLabelSpec = config.getString("testing.label-spec")
  val testingVgramFile = config.getString("testing.vgram-file")
  val testingLabelFile = config.getString("testing.label-file")
  val testingPredicitonFile = config.getString("testing.prediction-file")
  val testingVgramWindows = config.getIntVectorList("testing.vgram-window")
  val testingTimeWindows = config.getIntVectorList("testing.time-window")

  /*
   * target settings (allow multiple paths)
   */
  val targetSourceSpecs = config.getAbsolutePathList("target.source-spec")
  val targetResultPaths = config.getAbsolutePathList("target.result-path")
  val targetPredicitonSpec = config.getString("target.prediction-spec")
  val targetVgramWindows = config.getIntVectorList("target.vgram-window")

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

}

object TreatmentConfig {

  def fromConfig(config: Config): TreatmentConfig = new TreatmentConfig(config)

}
