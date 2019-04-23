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

  val altq = """(?:_alt)?"""
  val fastq = """(?:_[0-9]+Vs_[0-9]+Hz(?:_corrected)?)?"""
  val octaflowq = """(?:_octaflow)?"""
  val bypassq = """(?:_bypass)?"""
  val uncorrq = s"""(?:_(?:uncorrelated|RBV[^_]*)${octaflowq}${bypassq}_[0-9]+k_[0-9]+Hz)?"""
  val ordinalq = """(?:_\d{1})?"""

  val dateP = """\d{4}_\d{2}_\d{2}"""
  val nameP = """(?:[ap]m\d?_)?(?:[A-Za-z]+|[A-Za-z]+_[A-Za-z]+|[A-Za-z0-9]+)"""

  val dopamineP = s"""(?:dopamine|DA)${fastq}${uncorrq}"""
  val serotoninP = s"""(?:serotonin|5HT)${fastq}${uncorrq}"""
  val norepiP = s"""(?:norepinephrine|NE)${fastq}${uncorrq}"""
  val hiaaP = s"""(?:5HIAA)${fastq}${uncorrq}"""
  val kynaP = s"""(?:KYNA)${fastq}${uncorrq}"""
  val phP = s"""pH_[LH]{3}${fastq}${altq}${uncorrq}"""
  val randomP = """(?:increased_|decreased_)?random_high_(?:DA|5HT)(?:_[0-9])?"""
  val mixtureP = s"""(?:(?:DA|5HT|NE|5HIAA|KYNA|pH)_?){2,6}${octaflowq}${fastq}${uncorrq}"""

  val pH = new Regex(s"""(${dateP})_(${phP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val dopamine = new Regex(s"""(${dateP})_(${dopamineP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val serotonin = new Regex(s"""(${dateP})_(${serotoninP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val norepi = new Regex(s"""(${dateP})_(${norepiP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val hiaa = new Regex(s"""(${dateP})_(${hiaaP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val kyna = new Regex(s"""(${dateP})_(${kynaP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val random = new Regex(s"""(${dateP})_(${randomP})_(${nameP})_?(${dateP})?${ordinalq}?""")
  val mixture = new Regex(s"""(${dateP})_(${mixtureP})_?(${nameP})?_?(${dateP})?${ordinalq}?""")

  def datasetInfoFromName(dataset: String): Option[InvitroDataset] = {
    dataset match {
      // scalastyle:off null
      case pH(dsDate, dsProtocol, probeName, null)             => Some(InvitroDataset(dsDate, "pH", dsProtocol, probeName, ""))
      case dopamine(dsDate, dsProtocol, probeName, null)       => Some(InvitroDataset(dsDate, "dopamine", dsProtocol, probeName, ""))
      case serotonin(dsDate, dsProtocol, probeName, null)      => Some(InvitroDataset(dsDate, "serotonin", dsProtocol, probeName, ""))
      case norepi(dsDate, dsProtocol, probeName, null)         => Some(InvitroDataset(dsDate, "norepinephrine", dsProtocol, probeName, ""))
      case hiaa(dsDate, dsProtocol, probeName, null)           => Some(InvitroDataset(dsDate, "5-hydroxyindoleacetic acid", dsProtocol, probeName, ""))
      case kyna(dsDate, dsProtocol, probeName, null)           => Some(InvitroDataset(dsDate, "kynurenic acid", dsProtocol, probeName, ""))
      case random(dsDate, dsProtocol, probeName, null)         => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, ""))
      case mixture(dsDate, dsProtocol, null, null)             => Some(InvitroDataset(dsDate, "mixture", dsProtocol, "", ""))
      case mixture(dsDate, dsProtocol, probeName, null)        => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, ""))
      // scalastyle:on null

      case pH(dsDate, dsProtocol, probeName, probeDate)        => Some(InvitroDataset(dsDate, "pH", dsProtocol, probeName, probeDate))
      case dopamine(dsDate, dsProtocol, probeName, probeDate)  => Some(InvitroDataset(dsDate, "dopamine", dsProtocol, probeName, probeDate))
      case serotonin(dsDate, dsProtocol, probeName, probeDate) => Some(InvitroDataset(dsDate, "serotonin", dsProtocol, probeName, probeDate))
      case norepi(dsDate, dsProtocol, probeName, probeDate)    => Some(InvitroDataset(dsDate, "norepinephrine", dsProtocol, probeName, probeDate))
      case hiaa(dsDate, dsProtocol, probeName, probeDate)      => Some(InvitroDataset(dsDate, "5-hydroxyindoleacetic acid", dsProtocol, probeName, probeDate))
      case kyna(dsDate, dsProtocol, probeName, probeDate)      => Some(InvitroDataset(dsDate, "kynurenic acid", dsProtocol, probeName, probeDate))
      case random(dsDate, dsProtocol, probeName, probeDate)    => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, probeDate))
      case mixture(dsDate, dsProtocol, probeName, probeDate)   => Some(InvitroDataset(dsDate, "mixture", dsProtocol, probeName, probeDate))

      case _ => {
        warn(s"could not parse dataset name [$dataset]");
        None
      }
    }
  }

}
