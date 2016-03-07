package org.hnl.hive.cfg

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.{ Files, Paths }
import org.hnl.hive.cfg.matlab.{ ChemClass, TreatementCfgClass }
import com.typesafe.config.ConfigFactory
import com.typesafe.config.ConfigResolveOptions

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

  val chemConfig = ChemClass.fromConfig(treatmentConfig)
  val hiveConfig = TreatementCfgClass(treatmentConfig)

  /*
   * output files
   */
  val chemFile = "Chem.m"
  val hiveFile = "Config.m"

  Files.write(Paths.get(chemFile), chemConfig.toMatlab.getBytes(StandardCharsets.UTF_8))
  Files.write(Paths.get(hiveFile), hiveConfig.toMatlab.getBytes(StandardCharsets.UTF_8))

}
