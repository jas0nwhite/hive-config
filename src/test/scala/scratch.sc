import com.typesafe.config.ConfigFactory
import org.hnl.hive.cfg._
import org.hnl.hive.cfg.matlab._
import org.json4s._
import org.json4s.native.Serialization

import java.io.File

val cfgPath = "/data/hnl/iterate/src/treatment-011-008.conf"

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


/*
 * get up off of that thing
 */
implicit val formats: Formats = DefaultFormats +
                                FieldSerializer[TreatmentConfig]() +
                                FieldSerializer[InvitroDataset]() +
                                FieldSerializer[Chemical]()

println(Serialization.writePretty(treatmentConfig))