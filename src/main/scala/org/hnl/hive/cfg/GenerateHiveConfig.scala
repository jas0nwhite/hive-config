package org.hnl.hive.cfg

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import org.hnl.hive.cfg.matlab._
import com.typesafe.config.ConfigFactory
import grizzled.slf4j.Logging
import com.typesafe.config.ConfigException

object GenerateHiveConfig extends App with Logging {

  info("begin processing")

  /*
   * check arguments
   */
  if (args.length != 1) {
    error("no config file specified")
    System.exit(1)
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

    /*
     * output files
     */
    createMatlabFile(chemConfig)
    createMatlabFile(hiveConfig)
    createMatlabFile(testingCat)
    createMatlabFile(trainingCat)
    createMatlabFile(targetCat)
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
