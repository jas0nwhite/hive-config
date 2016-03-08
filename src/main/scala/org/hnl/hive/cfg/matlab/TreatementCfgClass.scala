package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.matlab.M._
import org.hnl.matlab.MExp
import org.hnl.matlab.MExp._

/**
 * TreatementCfgClass
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class TreatementCfgClass(name: String, cfg: TreatmentConfig) extends MatClassFile {

  protected val treatmentDef =
    ClassProps().attribs("Constant")
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
        'projectRoot %=% cfg.projectRoot,
        'trainingPath %=% cfg.trainingPath,
        'modelPath %=% cfg.modelPath,
        'clusterPath %=% cfg.clusterPath,
        'alphaPath %=% cfg.alphaPath,
        'muPath %=% cfg.muPath
      )

  protected val trainingDirs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "training directories",
        ""
      )
      .+(
        'trainingSourcePathList %=% CCell(cfg.trainingSourcePaths: _*),
        'trainingResultPathList %=% CCell(cfg.trainingResultPaths: _*)
      )

  protected val testingDirs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "testing directories",
        ""
      )
      .+(
        'testingSourcePathList %=% CCell(cfg.testingSourcePaths: _*),
        'testingResultPathList %=% CCell(cfg.testingResultPaths: _*)
      )

  protected val targetDirs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "target directories",
        ""
      )
      .+(
        'targetSourcePathList %=% CCell(cfg.targetSourcePaths: _*),
        'targetResultPathList %=% CCell(cfg.targetResultPaths: _*)
      )

  protected val catalogs =
    ClassProps().attribs("Constant")
      .%(
        "",
        " catalogs",
        ""
      )
      .+(
        'training %=% Fn("TrainingCatalog"),
        'testing %=% Fn("TestingCatalog"),
        'target %=% Fn("TargetCatalog")
      )

  override val mClass =
    ClassDef(name)
      .%(
        s"configruation information for HIVE treatment '${cfg.name}'",
        "",
        "this code was generated by scala"
      )
      .+(
        treatmentDef,
        treatmentDirs,
        trainingDirs,
        testingDirs,
        targetDirs,
        catalogs
      )

  override def toMatlab: String = mClass.toMatlab

}
