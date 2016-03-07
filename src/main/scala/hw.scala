import grizzled.slf4j.Logging
import com.typesafe.config._
import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.hive.cfg.matlab._

// scalastyle:off

object Hi extends Logging {
  def main(args: Array[String]) = {

    //    info("reading config...")

    val config = TreatmentConfig.fromConfig(ConfigFactory.load())

    //    println("*** CONFIG")
    //    println(s"  hive-id................${config.hiveId}")
    //    println(s"  project-root...........${config.projectRoot}")
    //    println(s"  training-path..........${config.trainingPath}")
    //    println(s"  model-path.............${config.modelPath}")
    //    println(s"  cluster-path...........${config.clusterPath}")
    //    println(s"  alpha-path.............${config.alphaPath}")
    //    println(s"  mu-path................${config.muPath}")
    //    println(s"  training.source-path...${config.trainingSourcePaths}")
    //    println(s"  training.result-path...${config.trainingResultPaths}")
    //    println(s"  testing.source-path....${config.testingSourcePaths}")
    //    println(s"  testing.result-path....${config.testingResultPaths}")
    //    println(s"  target.source-path.....${config.targetSourcePaths}")
    //    println(s"  target.result-path.....${config.targetResultPaths}")

    //    println
    //    println

    //    val da = Chem(1, "DA", "Dopamine", "DA", "nM", 0.0)
    //    val se = Chem(2, "5HT", "Serotonin", "5-HT", "nM", 0.0)
    //    val ph = Chem(3, "pH", "pH", "pH", "", 7.4)
    val chems = ChemClass.fromConfig(config)

    println(chems.toMatlab)

    // println(TreatementCfgClass(config).toMatlab)

  }
}
