package org.hnl.hive.cfg

import scala.util.matching.Regex

import grizzled.slf4j.Logging

// scalastyle:off multiple.string.literals

/**
 * Utilities to parse naming of various files and directories created by the HNL
 * <p>
 * Created on May 5, 2016.
 * <p>
 *
 * @author Jason White
 */
case class InvitroDataset(dsDate: String, dsClass: String, dsProtocol: String, probeName: String, probeDate: String)

object NamingUtil extends Logging {

  def datasetNameFromPath(fileName: String): Option[String] = {
    val string = "([^/]+)".r
    val subdir = "(.*)/([^/]+)".r
    val file = "([^/]+)[.]?(.*)".r
    val dirFile = "(.*)/([^/]+)/([^/]+)[.]?(.*)".r

    fileName match {
      case dirFile(root, dir, file, ext) => Some(dir)
      case subdir(root, dir)             => Some(dir)
      case file(name, ext)               => Some(name)
      case string(s)                     => Some(s)
      case _ => {
        warn(s"could not determine dataset name of [$fileName]")
        None
      }
    }
  }

  val dateP = """\d{4}_\d{2}_\d{2}"""
  val altq = """(?:_alt)?"""
  val nameP = """(?:[ap]m\d?_)?[A-Za-z_]+"""

  val pH = new Regex(s"""($dateP)_(pH_[LH]{3}$altq)_($nameP)_($dateP)""")
  val dopamine = new Regex(s"""($dateP)_(dopamine)_($nameP)_($dateP)""")
  val serotonin = new Regex(s"""($dateP)_(serotonin)_($nameP)_($dateP)""")
  val random = new Regex(s"""($dateP)_((?:increased_)?random_high_(?:DA|5HT)(?:_[0-9])?)_($nameP)_($dateP)""")

  def datasetInfoFromName(dataset: String): Option[InvitroDataset] = {
    dataset match {
      case pH(dsDate, dsProtocol, probeName, probeDate)        => Some(InvitroDataset(dsDate, "pH", dsProtocol, probeName, probeDate))
      case dopamine(dsDate, dsProtocol, probeName, probeDate)  => Some(InvitroDataset(dsDate, "dopamine", dsProtocol, probeName, probeDate))
      case serotonin(dsDate, dsProtocol, probeName, probeDate) => Some(InvitroDataset(dsDate, "serotonin", dsProtocol, probeName, probeDate))
      case random(dsDate, dsProtocol, probeName, probeDate)    => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, probeDate))
      case _ => {
        warn(s"could not parse dataset name [$dataset]");
        None
      }
    }
  }

}
