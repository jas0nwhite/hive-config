package org.hnl.hive.cfg

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Files

import org.hnl.hive.cfg.matlab._
import org.hnl.hive.csv.LabelCatalog

import com.typesafe.config.{ ConfigException, ConfigFactory }

import grizzled.slf4j.Logging

// scalastyle:off multiple.string.literals

/**
 * GenerateHiveConfig$
 * <p>
 * Created on Mar 6, 2016.
 * <p>
 *
 * @author Jason White
 */
object GenerateHiveConfig extends App with Logging {

  info("begin processing")

  /*
   * check arguments
   */
  if (args.length != 1 || args(0).isEmpty) {
    error("no config file specified")
    System.exit(3)
  }

  try {
    /*
     * load configuration
     */
    val config = ConfigFactory.load(ConfigFactory.parseFile(new File(args(0))))

    /*
     * process configuration
     */
    val treatmentConfig = TreatmentConfig.fromConfig(config)

    val chemConfig = Chem.fromConfig("Chem", treatmentConfig)
    val testingCat = TestingCatalog("TestingCatalog", treatmentConfig)
    val trainingCat = TrainingCatalog("TrainingCatalog", treatmentConfig)
    val targetCat = TargetCatalog("TargetCatalog", treatmentConfig)
    val hiveConfig = Config("Config", treatmentConfig, trainingCat, testingCat, targetCat)
    val labelCatalog = new LabelCatalog(treatmentConfig)

    /*
     * output files
     */
    createMatlabFile(chemConfig)
    createMatlabFile(hiveConfig)
    createMatlabFile(testingCat)
    createMatlabFile(trainingCat)
    createMatlabFile(targetCat)

    labelCatalog.processCatalog(
      treatmentConfig.testing.sourceCatalog,
      treatmentConfig.testing.labelSpec,
      treatmentConfig.testing.rawSpec,
      treatmentConfig.testing.labelCatalogFile)

    labelCatalog.processCatalog(
      treatmentConfig.training.sourceCatalog,
      treatmentConfig.training.labelSpec,
      treatmentConfig.training.rawSpec,
      treatmentConfig.training.labelCatalogFile)

  }
  catch {
    case e: ConfigException.Parse => {
      error(s"parsing ${e.getMessage}")
      System.exit(2)
    }
    case e: ConfigException => {
      error(s"processing ${args(0)}: ${e.getMessage}")
      System.exit(2)
    }
    case e: HiveConfigException => {
      error(e.getMessage)
      System.exit(2)
    }
    case e: Throwable => {
      error(s"${e.getClass.getName.split("[.]").last} processing ${args(0)}: ${e.getMessage}")
      System.exit(2)
    }
  }

  protected def createMatlabFile(matClass: MatClassFile): Unit = {
    Files.write(matClass.filePath, matClass.toMatlab.getBytes(StandardCharsets.UTF_8))
    info("created " + matClass.filePath.toString)
  }

}
