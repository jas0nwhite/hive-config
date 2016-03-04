package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.matlab._
import org.hnl.matlab.M._

/**
 * TreatementCfgClass
 * <p>
 * Created on Mar 1, 2016.
 * <p>
 *
 * @author Jason White
 */
case class TreatementCfgClass(cfg: TreatmentConfig) extends MatlabChunk with MatlabFormatting {

  protected val treatmentDef =
    ClassProps().attribs("Constant")
      .%(
        "",
        "treatment definition",
        ""
      )
      .+(
        Var("name") %=% cfg.name,
        Var("trainingSetId") %=% cfg.trainingSetId.toInt,
        Var("trainingStyleId") %=% cfg.trainingStyleId.toInt,
        Var("clusterStyleId") %=% cfg.clusterStyleId.toInt,
        Var("alphaSelectId") %=% cfg.alphaSelectId.toInt,
        Var("muSelectId") %=% cfg.muSelectId.toInt
      )

  protected val treatmentDirs =
    ClassProps().attribs("Constant")
      .%(
        "",
        "treatment directories",
        ""
      )
      .+(
        Var("projectRoot") %=% cfg.projectRoot,
        Var("trainingPath") %=% cfg.trainingPath,
        Var("modelPath") %=% cfg.modelPath,
        Var("clusterPath") %=% cfg.clusterPath,
        Var("alphaPath") %=% cfg.alphaPath,
        Var("muPath") %=% cfg.muPath
      )

  protected val mClass =
    ClassDef("Config").from("handle")
      .%(
        s"configruation information for HIVE treatment '${cfg.name}'",
        "",
        "this code was generated by scala"
      )
      .+(
        treatmentDef,
        treatmentDirs
      )

  def toMatlab: String = mClass.toMatlab

}