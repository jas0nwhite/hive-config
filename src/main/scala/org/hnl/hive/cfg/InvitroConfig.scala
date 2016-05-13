package org.hnl.hive.cfg

import org.hnl.hive.cfg.ConfigUtil.configToWrappedConfig

import com.typesafe.config.Config

import grizzled.slf4j.Logging

/**
 * InvitroConfig
 * <p>
 * Created on May 12, 2016.
 * <p>
 *
 * @author Jason White
 */
class InvitroConfig protected (config: WrappedConfig) extends Logging {

  //
  // PATHS AND FILESPECS
  //
  val sourceSpecs = config.getAbsolutePathList("source-spec")
  val resultPaths = config.getAbsolutePathList("result-path")
  val rawSpec = config.getString("raw-spec")
  val labelSpec = config.getString("label-spec")

  //
  // OUTPUT FILENAMES
  //
  val labelCatalogFile = config.getString("label-catalog-file")
  val vgramFile = config.getString("vgram-file")
  val metaFile = config.getString("metadata-file")
  val labelFile = config.getString("label-file")
  val characterizationFile = config.getString("characterization-file")

  //
  // PROCESSING SETTINGS
  //
  val vgramWindows = config.getIntVectorList("vgram-window")
  val timeWindows = config.getIntVectorList("time-window")

  //
  // CATALOG CALCULATIONS
  //
  val sourceCatalog = Util.findPaths(sourceSpecs)
  val datasetCatalog = sourceCatalog.map(Util.basenames(_))

}

object InvitroConfig {

  def fromConfig(config: Config): InvitroConfig = new InvitroConfig(config)

}
