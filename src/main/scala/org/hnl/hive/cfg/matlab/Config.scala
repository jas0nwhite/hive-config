package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.matlab.M._
import org.hnl.matlab.MExp
import org.hnl.matlab.MExp._

/**
 * Config
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class Config(
  name: String,
  cfg: TreatmentConfig,
  training: TrainingCatalog,
  testing: TestingCatalog,
  target: TargetCatalog)
    extends MatClassFile {

  override val pkg: String = ""

  protected val treatmentDef =
    ClassProps().attribs("Constant") // scalastyle:ignore multiple.string.literals
      .%(
        "",
        "treatment definition",
        ""
      )
      .+(
        'name %=% cfg.name,
        'trainingSetId %=% cfg.trainingSetId.toInt,
        'trainingStyleId %=% cfg.trainingStyleId.toInt,
        'clusterStyleId %=% cfg.clusterStyleId.toInt,
        'alphaSelectId %=% cfg.alphaSelectId.toInt,
        'muSelectId %=% cfg.muSelectId.toInt
      )

  protected val treatmentDirs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "treatment directories",
        ""
      )
      .+(
        'projectHome %=% cfg.projectHome,
        'trainingHome %=% cfg.trainingHome,
        'testingHome %=% cfg.testingHome,
        'modelHome %=% cfg.modelHome,
        'clusterHome %=% cfg.clusterHome,
        'alphaHome %=% cfg.alphaHome,
        'muHome %=% cfg.muHome,
        'codePath %=% CCell(cfg.codePath: _*)
      )

  protected val catalogs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "catalogs",
        ""
      )
      .+(
        'training %=% training.classObj,
        'testing %=% testing.classObj,
        'target %=% target.classObj
      )

  protected val methods =
    ClassMethods().attribs("Static")
      .%(
        "",
        "methods",
        ""
      )
      .+(
        FnDef("init").returns('self)
          .doc("INIT initializes the path and returns this config object")
          .+(
            'self %=% Fn(name),
            Fn("addpath", 'self ~> 'codePath.curly(%::%), "-begin"),
            Fn("fprintf", raw"initialized configuration for %s\n", 'self ~> 'name)
          )
      )

  override val mClass =
    ClassDef(name).from("hive.cfg.ConfigBase")
      .%(
        s"configruation information for HIVE treatment '${cfg.name}'",
        "",
        "this code was generated by scala"
      )
      .+(
        treatmentDef,
        treatmentDirs,
        catalogs,
        methods
      )

}
