package org.hnl.hive.cfg

import com.typesafe.config.Config
import grizzled.slf4j.Logging
import org.hnl.hive.cfg.ConfigUtil.configToWrappedConfig

/**
  * InvitroConfig
  * <p>
  * Created on May 12, 2016.
  * <p>
  *
  * @author Jason White
  */
class InvitroConfig protected(config: WrappedConfig) extends Logging {

  //
  // PATHS AND FILESPECS
  //
  val sourceSpecs: List[String] = config.getAbsolutePathList("source-spec")
  val importPaths: List[String] = config.getAbsolutePathList("import-path")
  val resultPaths: List[String] = config.getAbsolutePathList("result-path")
  val rawSpec: String = config.getString("raw-spec")
  val labelSpec: String = config.getString("label-spec")

  //
  // OUTPUT FILENAMES
  //
  val labelCatalogFile: String = config.getString("label-catalog-file")
  val vgramFile: String = config.getString("vgram-file")
  val otherFile: String = config.getString("other-file")
  val metaFile: String = config.getString("metadata-file")
  val labelFile: String = config.getString("label-file")
  val summaryFile: String = config.getString("summary-file")
  val characterizationFile: String = config.getString("characterization-file")
  val clusterIndexFile: String = config.getString("cluster-index-file")

  //
  // PROCESSING SETTINGS
  //
  val vgramWindows: List[List[Int]] = config.getIntVectorList("vgram-window")
  val timeWindows: List[List[Int]] = config.getIntVectorList("time-window")

  //
  // CATALOG CALCULATIONS
  //
  val sourceCatalog: List[List[String]] = Util.findPaths(sourceSpecs)
  val datasetCatalog: List[List[String]] = sourceCatalog.map(Util.basenames)
  val infoCatalog: List[List[Option[InvitroDataset]]] = sourceCatalog.map(_.map(DatasetConfig.datasetInfoFromPath))

}

object InvitroConfig {

  def fromConfig(config: Config): InvitroConfig = new InvitroConfig(config)

}
