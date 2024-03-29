package org.hnl.hive.cfg.matlab

import org.hnl.hive.cfg.{InvitroConfig, InvitroDataset, TreatmentConfig}
import org.hnl.matlab.M._
import org.hnl.matlab.MExp
import org.hnl.matlab.MExp._

/**
  * TrainingCatalog
  * <p>
  * Created on Mar 8, 2016.
  * <p>
  *
  * @author Jason White
  */
case class TrainingCatalog(name: String, treatmentCfg: TreatmentConfig) extends MatClassFile {

  override val pkg = "hive.cfg"

  val cfg: InvitroConfig = treatmentCfg.training

  protected val paths: ClassProps =
    ClassProps().attribs("Constant")
      .%(
        "",
        "training directories",
        ""
      )
      .+(
        'sourceSpecList %=% CCell(cfg.sourceSpecs: _*),
        'importPathList %=% CCell(cfg.importPaths: _*),
        'resultPathList %=% CCell(cfg.resultPaths: _*)
      )

  protected val settings: ClassProps =
    ClassProps().attribs("Constant")
      .%(
        "",
        "settings",
        ""
      )
      .+(
        'vgramFile %=% cfg.vgramFile,
        'otherFile %=% cfg.otherFile,
        'metaFile %=% cfg.metaFile,
        'labelFile %=% cfg.labelFile,
        'summaryFile %=% cfg.summaryFile,
        'characterizationFile %=% cfg.characterizationFile,
        'clusterIndexFile %=% cfg.clusterIndexFile,
        'vgramWindowList %=% CCell(cfg.vgramWindows.map(l => RVec(l: _*)): _*),
        'timeWindowList %=% CCell(cfg.timeWindows.map(l => RVec(l: _*)): _*)
      )

  protected val outputs: ClassProps =
    ClassProps().attribs("Constant")
      .%(
        "",
        "outputs",
        ""
      )
      .+(
        'indexCloudFile %=% treatmentCfg.trainingIndexCloudFile
      )

  protected val catalogs: ClassProps =
    ClassProps().attribs("Constant")
      .%(
        "",
        "catalogs",
        ""
      )
      .+(
        'labelCatalogFile %=% cfg.labelCatalogFile,
        'sourceCatalog %=% makeIndexedCellArray(cfg.sourceCatalog)((s: String) => Str(s)),
        'datasetCatalog %=% makeIndexedCellArray(cfg.datasetCatalog)((s: String) => Str(s)),
        'infoCatalog %=% makeIndexedCellArray(cfg.infoCatalog)((x: Option[InvitroDataset]) => x match {
          case Some(ds) => Fn("hive.cfg.InvitroDataset", ds.dsDate, ds.dsClass, ds.dsProtocol, ds.probeName, ds.probeDate)
          case None     => RVec()
        })
      )

  override val mClass: ClassDef =
    ClassDef(name).from("hive.cfg.InvitroCatalogBase")
      .%(
        s"training catalog for HIVE treatment '${treatmentCfg.name}'",
        "",
        "this code was generated by scala"
      )
      .+(
        paths,
        settings,
        outputs,
        catalogs
      )
}
