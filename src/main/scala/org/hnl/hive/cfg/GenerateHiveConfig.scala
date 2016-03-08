package org.hnl.hive.cfg

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.{ Files, Paths }
import org.hnl.hive.cfg.matlab._
import com.typesafe.config.ConfigFactory
import com.typesafe.config.ConfigResolveOptions
import org.hnl.matlab.MExp

object GenerateHiveConfig extends App {

  /*
   * check arguments
   */
  if (args.length != 1) {
    Console.err.println(s"Usage: ${GenerateHiveConfig.getClass.getName} config-file") // scalastyle:ignore token regex
    System.exit(1)
  }

  /*
   * load configuration
   */
  val config = ConfigFactory.load(ConfigFactory.parseFile(new File(args(0))))

  /*
   * process configuration
   */
  val treatmentConfig = TreatmentConfig.fromConfig(config)

  val chemConfig = ChemClass.fromConfig("Chem", treatmentConfig)
  val hiveConfig = TreatementCfgClass("Config", treatmentConfig)
  val testingCat = TestingCatalog("TestingCatalog", treatmentConfig)
  val trainingCat = TrainingCatalog("TrainingCatalog", treatmentConfig)
  val targetCat = TargetCatalog("TargetCatalog", treatmentConfig)

  /*
   * output files
   */
  createMatlabFile(chemConfig)
  createMatlabFile(hiveConfig)
  createMatlabFile(testingCat)
  createMatlabFile(trainingCat)
  createMatlabFile(targetCat)

  protected def createMatlabFile(matClass: MatClassFile): Unit =
    Files.write(Paths.get(matClass.name + ".m"), matClass.toMatlab.getBytes(StandardCharsets.UTF_8))

}
