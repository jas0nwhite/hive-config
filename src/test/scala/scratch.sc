import org.hnl.hive.cfg.TreatmentConfig

object scratch {
  import com.typesafe.config._
  import collection.JavaConversions._

  object quiet {
    val config = ConfigFactory.load()
    val tc = new TreatmentConfig(config)
  }
  
  val paths = quiet.config.getList("training.source-path")
                                                  //> paths  : com.typesafe.config.ConfigList = SimpleConfigList([["hive-data","re
                                                  //| sults_00A","training"]])
  val kind = paths.get(0).valueType               //> kind  : com.typesafe.config.ConfigValueType = LIST
  val list = paths.unwrapped().toList             //> list  : List[Object] = List([hive-data, results_00A, training])
  
  val list0 = list(0)                             //> list0  : Object = [hive-data, results_00A, training]
  val arr = list0.asInstanceOf[java.util.ArrayList[String]]
                                                  //> arr  : java.util.ArrayList[String] = [hive-data, results_00A, training]
  val lst = arr.toList                            //> lst  : List[String] = List(hive-data, results_00A, training)
  
  val x = paths.unwrapped().toList.map{_.asInstanceOf[java.util.ArrayList[String]].toList}
                                                  //> x  : List[List[String]] = List(List(hive-data, results_00A, training))

	quiet.tc                                  //> res0: org.hnl.hive.cfg.TreatmentConfig = 00A-00B-00C-00D-00E @ /Applications
                                                  //| /Eclipse.app/Contents/MacOS/hive-data
	quiet.tc.trainingSourcePaths              //> res1: List[String] = List(/Applications/Eclipse.app/Contents/MacOS/hive-data
                                                  //| /results_00A/training)
                                                  
}