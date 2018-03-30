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

  val altq      = """(?:_alt)?"""
  val fastq     = """(?:_[0-9]+Vs_[0-9]+Hz(?:_corrected)?)?"""
  val octaflowq = """(?:_octaflow)?"""
  val bypassq   = """(?:_bypass)?"""
  val uncorrq   = s"""(?:_(?:uncorrelated|RBV[^_]*)${octaflowq}${bypassq}_[0-9]+k_[0-9]+Hz)?"""

  val dateP = """\d{4}_\d{2}_\d{2}"""
  val nameP = """(?:[ap]m\d?_)?(?:[A-Za-z]+|[A-Za-z]+_[A-Za-z]+|[A-Za-z0-9]+)"""

  val dopamineP = s"""(?:dopamine|DA)${fastq}${uncorrq}"""
  val serotoninP = s"""(?:serotonin|5HT)${fastq}${uncorrq}"""
  val norepiP = s"""(?:norepinephrine|NE)${fastq}${uncorrq}"""
  val hiaaP = s"""(?:5HIAA)${fastq}${uncorrq}"""
  val phP = s"""pH_[LH]{3}${fastq}${altq}${uncorrq}"""
  val randomP = """(?:increased_|decreased_)?random_high_(?:DA|5HT)(?:_[0-9])?"""
  val mixtureP = s"""(?:(?:DA|5HT|NE|5HIAA|pH)_?){2,5}${octaflowq}${fastq}${uncorrq}"""
  // val threeXP = s"""DA_5HT_NE${octaflowq}${fastq}${uncorrq}"""
  // val fourXP = s"""DA_5HT_NE_pH${octaflowq}${fastq}${uncorrq}"""

  val pH = new Regex(s"""(${dateP})_(${phP})_(${nameP})_?(${dateP})?""")
  val dopamine = new Regex(s"""(${dateP})_(${dopamineP})_(${nameP})_?(${dateP})?""")
  val serotonin = new Regex(s"""(${dateP})_(${serotoninP})_(${nameP})_?(${dateP})?""")
  val norepi = new Regex(s"""(${dateP})_(${norepiP})_(${nameP})_?(${dateP})?""")
  val hiaa = new Regex(s"""(${dateP})_(${hiaaP})_(${nameP})_?(${dateP})?""")
  val random = new Regex(s"""(${dateP})_(${randomP})_(${nameP})_?(${dateP})?""")
  val mixture = new Regex(s"""(${dateP})_(${mixtureP})_?(${nameP})?_?(${dateP})?""")
  // val threeX = new Regex(s"""(${dateP})_(${threeXP})_?(${nameP})?_?(${dateP})?""")
  // val fourX = new Regex(s"""(${dateP})_(${fourXP})_?(${nameP})?_?(${dateP})?""")

  def datasetInfoFromName(dataset: String): Option[InvitroDataset] = {
    dataset match {
      // scalastyle:off null
      case pH(dsDate, dsProtocol, probeName, null)             => Some(InvitroDataset(dsDate, "pH", dsProtocol, probeName, ""))
      case dopamine(dsDate, dsProtocol, probeName, null)       => Some(InvitroDataset(dsDate, "dopamine", dsProtocol, probeName, ""))
      case serotonin(dsDate, dsProtocol, probeName, null)      => Some(InvitroDataset(dsDate, "serotonin", dsProtocol, probeName, ""))
      case norepi(dsDate, dsProtocol, probeName, null)         => Some(InvitroDataset(dsDate, "norepinephrine", dsProtocol, probeName, ""))
      case hiaa(dsDate, dsProtocol, probeName, null)           => Some(InvitroDataset(dsDate, "5-hydroxyindoleacetic acid", dsProtocol, probeName, ""))
      case random(dsDate, dsProtocol, probeName, null)         => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, ""))
      case mixture(dsDate, dsProtocol, null, null)             => Some(InvitroDataset(dsDate, "mixture", dsProtocol, "", ""))
      case mixture(dsDate, dsProtocol, probeName, null)        => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, ""))
      // scalastyle:on null

      case pH(dsDate, dsProtocol, probeName, probeDate)        => Some(InvitroDataset(dsDate, "pH", dsProtocol, probeName, probeDate))
      case dopamine(dsDate, dsProtocol, probeName, probeDate)  => Some(InvitroDataset(dsDate, "dopamine", dsProtocol, probeName, probeDate))
      case serotonin(dsDate, dsProtocol, probeName, probeDate) => Some(InvitroDataset(dsDate, "serotonin", dsProtocol, probeName, probeDate))
      case norepi(dsDate, dsProtocol, probeName, probeDate)         => Some(InvitroDataset(dsDate, "norepinephrine", dsProtocol, probeName, probeDate))
      case hiaa(dsDate, dsProtocol, probeName, probeDate)           => Some(InvitroDataset(dsDate, "5-hydroxyindoleacetic acid", dsProtocol, probeName, probeDate))
      case random(dsDate, dsProtocol, probeName, probeDate)    => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, probeDate))
      case mixture(dsDate, dsProtocol, probeName, probeDate)   => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, probeDate))

      case _ => {
        warn(s"could not parse dataset name [$dataset]");
        None
      }
    }
  }

}
