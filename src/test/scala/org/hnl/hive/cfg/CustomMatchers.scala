package org.hnl.hive.cfg

import org.scalatest.matchers.{HavePropertyMatchResult, HavePropertyMatcher}

/**
  * CustomMatchers
  * <p>
  * Created on 2019-07-24
  * <p>
  *
  * @author Jason White
  */
trait CustomMatchers {
  def dsClass(expectedValue: String): HavePropertyMatcher[InvitroDataset, String] =
    (info: InvitroDataset) => HavePropertyMatchResult(
      info.dsClass == expectedValue,
      "dsClass",
      expectedValue,
      info.dsClass
    )

  def dsDate(expectedValue: String): HavePropertyMatcher[InvitroDataset, String] =
    (info: InvitroDataset) => HavePropertyMatchResult(
      info.dsDate == expectedValue,
      "dsDate",
      expectedValue,
      info.dsDate
    )

  def dsProtocol(expectedValue: String): HavePropertyMatcher[InvitroDataset, String] =
    (info: InvitroDataset) => HavePropertyMatchResult(
      info.dsProtocol == expectedValue,
      "dsProtocol",
      expectedValue,
      info.dsProtocol
    )

  def probeName(expectedValue: String): HavePropertyMatcher[InvitroDataset, String] =
    (info: InvitroDataset) => HavePropertyMatchResult(
      info.probeName == expectedValue,
      "probeName",
      expectedValue,
      info.probeName
    )

  def probeDate(expectedValue: String): HavePropertyMatcher[InvitroDataset, String] =
    (info: InvitroDataset) => HavePropertyMatchResult(
      info.probeDate == expectedValue,
      "probeDate",
      expectedValue,
      info.probeDate
    )
}
