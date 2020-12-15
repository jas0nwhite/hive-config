package org.hnl.hive.cfg

import com.typesafe.config.{ConfigException, ConfigFactory}
import grizzled.file.util._
import grizzled.slf4j.Logging
import org.hnl.hive.cfg.matlab._
import org.hnl.hive.csv.LabelCatalog
import org.json4s._
import org.json4s.native.Serialization

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}


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
    sys.exit(3)
  }

  val cfgPath = normalizePath(args(0))
  val cfgHome = dirname(cfgPath)
  val cfgFile = basename(cfgPath)

  if (!Files.isDirectory(Paths.get(cfgHome))) {
    error(s"config directory '$cfgHome' does not exist")
    sys.exit(3)
  }

  if (!Files.isRegularFile(Paths.get(cfgHome, cfgFile))) {
    error(s"config file '$cfgFile' does not exist in '$cfgHome''")
    sys.exit(3)
  }

  try {
    /*
     * load configuration
     */
    val config = ConfigFactory.load(ConfigFactory.parseFile(new File(cfgPath)))

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
    createJsonFile(chemConfig)
    createJsonFile(hiveConfig)
    createJsonFile(testingCat)
    createJsonFile(trainingCat)
    createJsonFile(targetCat)

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
    case e: ConfigException.Parse =>
      error(s"parsing ${e.getMessage}")
      sys.exit(2)

    case e: ConfigException =>
      error(s"processing ${args(0)}: ${e.getMessage}")
      sys.exit(2)

    case e: HiveConfigException =>
      error(e.getMessage)
      sys.exit(2)

    case e: Throwable =>
      error(s"${e.getClass.getName.split("[.]").last} processing ${args(0)}: ${e.getMessage}")
      sys.exit(2)
  }

  protected def createMatlabFile(matClass: MatClassFile): Unit = {
    Files.write(matClass.filePath, matClass.toMatlab.getBytes(StandardCharsets.UTF_8))
    info("created " + matClass.filePath.toString)
  }

  protected def createJsonFile[A](obj: A): Unit = {
    val treatmentName =
      if (cfgFile.indexOf(".") > 0)
        cfgFile.substring(0, cfgFile.lastIndexOf("."))
      else
        cfgFile

    val catalogName = obj.getClass.getSimpleName
    val jsonFile = s"$treatmentName.$catalogName.json"
    val jsonPath = Paths.get(cfgHome, jsonFile)

    implicit val formats: Formats = DefaultFormats +
                                    FieldSerializer[TreatmentConfig]() +
                                    FieldSerializer[TestingCatalog]() +
                                    FieldSerializer[TrainingCatalog]() +
                                    FieldSerializer[TargetCatalog]()

    Files.write(jsonPath, Serialization.writePretty(obj).getBytes(StandardCharsets.UTF_8))
    info("created " + jsonPath.toString)
  }
}
