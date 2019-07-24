package org.hnl.hive.cfg

import java.io.File
import java.nio.file.Paths

import com.typesafe.config.ConfigFactory
import grizzled.slf4j.Logging
import org.hnl.hive.cfg.ConfigUtil.configToWrappedConfig

import scala.util.{Failure, Success, Try}


/**
  * DatasetConfig
  * <p>
  * Created on 2019-07-23
  * <p>
  *
  * @author Jason White
  */
object DatasetConfig extends Logging {

  val configFileName: String = "dataset.conf"

  /**
    * Returns an InvitroDataset option by first trying to parse
    * the dataset.conf file, or else by parsing the directory name
    *
    * @param path the path to the dataset
    * @return Some(InvitroDataset) from dataset.conf, or
    *         Some(InvitroDataset) parsed from the filename, or
    *         None if neither operation succeeds
    */
  def datasetInfoFromPath(path: String): Option[InvitroDataset] =
    this.getFromConfig(path) orElse this.getFromName(path)


  /**
    * Attempts to parse the name of the dataset using the provided path
    *
    * @param path the path to the dataset
    * @return Some(InvitroDataset) from the directory name, or
    *         None if the directory name could not be parsed
    */
  protected def getFromName(path: String): Option[InvitroDataset] =
    for {
      name <- NamingUtil.datasetNameFromPath(path)
      dataset <- NamingUtil.datasetInfoFromName(name)
    } yield dataset


  /**
    * Attempts to load the default dataset configuration file and parse its contents
    *
    * @param path the path to the dataset
    * @return Some(InvitroDataset) from the configuration file, or
    *         None if the file could not be found or parsed
    */
  protected def getFromConfig(path: String): Option[InvitroDataset] =
    for {
      file <- findConfigFile(path)
      dataset <- parseConfigFile(file)
    } yield dataset


  /**
    * Parses the config file
    *
    * @param configFile the File pointing to the configuration
    * @return Some(InvitroDataset) from the configuration, or
    *         None if the configuration is invalid
    */
  protected def parseConfigFile(configFile: File): Option[InvitroDataset] = {
    Try {
      val config: WrappedConfig = ConfigFactory.load(ConfigFactory.parseFile(configFile))

      InvitroDataset(
        config.getString("date"),
        config.getString("dataset-class"),
        config.getString("protocol"),
        config.getString("probe-name", ""),
        config.getString("probe-date", "")
      )
    } match {
      case Success(dataset) => Some(dataset)
      case Failure(err)     =>
        warn(s"could not parse dataset config file [$configFile]: ${err.getMessage}")
        None
    }
  }

  /**
    * Finds the default configuration file (dataset.conf)
    *
    * @param path the path in which to find the configuration file
    * @return Some(file) if the file is found, or
    *         None if the file is not found
    */
  protected def findConfigFile(path: String): Option[File] = {
    val configFile = Paths.get(path, configFileName).toFile

    if (configFile.exists())
      Some(configFile)
    else {
      debug(s"dataset config file [$configFile] not found")
      None
    }
  }
}
