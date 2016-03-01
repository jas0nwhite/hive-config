import grizzled.slf4j.Logging
import com.typesafe.config._
import org.hnl.hive.cfg.TreatmentConfig

object Hi extends Logging {
  def main(args: Array[String]) = {

    info("reading config...")

    val config = new TreatmentConfig(ConfigFactory.load())

    println("*** CONFIG")
    println(s"  hive-id................${config.hiveId}")
    println(s"  project-root...........${config.projectRoot}")
    println(s"  training-path..........${config.trainingPath}")
    println(s"  model-path.............${config.modelPath}")
    println(s"  cluster-path...........${config.clusterPath}")
    println(s"  alpha-path.............${config.alphaPath}")
    println(s"  mu-path................${config.muPath}")
    println(s"  training.source-path...${config.trainingSourcePaths}")
    println(s"  training.result-path...${config.trainingResultPaths}")
    println(s"  testing.source-path....${config.testingSourcePaths}")
    println(s"  testing.result-path....${config.testingResultPaths}")
    println(s"  target.source-path.....${config.targetSourcePaths}")
    println(s"  target.result-path.....${config.targetResultPaths}")

  }
}
