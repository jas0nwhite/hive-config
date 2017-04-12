package org.hnl.hive.cfg

import org.scalatest._
import org.hnl.hive.cfg.NamingUtil._
import org.scalatest.matchers.HavePropertyMatcher
import org.scalatest.matchers.HavePropertyMatchResult

/**
 * NamingUtilSpec
 * <p>
 * Created on Apr 12, 2017.
 * <p>
 *
 * @author Jason White
 */
class NamingUtilSpec extends WordSpec with Matchers with Inspectors with OptionValues with CustomMatchers {

  "NamingUtil" should {

    "parse probe names" in {
      val option1 = NamingUtil.datasetInfoFromName("2015_07_14_dopamine_A_EL_2015_07_07")

      option1 should not be (null)
      option1.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

      val option2 = NamingUtil.datasetInfoFromName("2015_10_27_dopamine_am_KK_2013_07_29")

      option2 should not be (null)
      option2.value should have(
        dsDate("2015_10_27"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("am_KK"),
        probeDate("2013_07_29")
      )

      val option3 = NamingUtil.datasetInfoFromName("2015_11_12_pH_HLH_pm3_KK_2013_07_29")

      option3 should not be (null)
      option3.value should have(
        dsDate("2015_11_12"),
        dsClass("pH"),
        dsProtocol("pH_HLH"),
        probeName("pm3_KK"),
        probeDate("2013_07_29")
      )

      val option4 = NamingUtil.datasetInfoFromName("2017_03_09_5HT_uncorrelated_octaflow_bypass_100k_97Hz_V8")

      option4 should not be (null)
      option4.value should have(
        dsDate("2017_03_09"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_octaflow_bypass_100k_97Hz"),
        probeName("V8"),
        probeDate("")
      )
    }

    "parse uncorrelated dataset names" in {
      val option1 = NamingUtil.datasetInfoFromName("2016_06_15_5HT_uncorrelated_100k_97Hz_A")

      option1 should not be (null)
      option1.value should have(
        dsDate("2016_06_15"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_100k_97Hz"),
        probeName("A"),
        probeDate("")
      )

      val option2 = NamingUtil.datasetInfoFromName("2017_03_09_5HT_uncorrelated_octaflow_bypass_100k_97Hz_V8")

      option2 should not be (null)
      option2.value should have(
        dsDate("2017_03_09"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_octaflow_bypass_100k_97Hz"),
        probeName("V8"),
        probeDate("")
      )

      val option3 = NamingUtil.datasetInfoFromName("2017_03_27_DA_uncorrelated_octaflow_100k_97Hz_S8")

      option3 should not be (null)
      option3.value should have(
        dsDate("2017_03_27"),
        dsClass("dopamine"),
        dsProtocol("DA_uncorrelated_octaflow_100k_97Hz"),
        probeName("S8"),
        probeDate("")
      )

    }

  }

}

trait CustomMatchers {
  def dsClass(expectedValue: String) =
    new HavePropertyMatcher[InvitroDataset, String] {
      def apply(info: InvitroDataset) =
        HavePropertyMatchResult(
          info.dsClass == expectedValue,
          "dsClass",
          expectedValue,
          info.dsClass
        )
    }

  def dsDate(expectedValue: String) =
    new HavePropertyMatcher[InvitroDataset, String] {
      def apply(info: InvitroDataset) =
        HavePropertyMatchResult(
          info.dsDate == expectedValue,
          "dsDate",
          expectedValue,
          info.dsDate
        )
    }

  def dsProtocol(expectedValue: String) =
    new HavePropertyMatcher[InvitroDataset, String] {
      def apply(info: InvitroDataset) =
        HavePropertyMatchResult(
          info.dsProtocol == expectedValue,
          "dsProtocol",
          expectedValue,
          info.dsProtocol
        )
    }

  def probeName(expectedValue: String) =
    new HavePropertyMatcher[InvitroDataset, String] {
      def apply(info: InvitroDataset) =
        HavePropertyMatchResult(
          info.probeName == expectedValue,
          "probeName",
          expectedValue,
          info.probeName
        )
    }

  def probeDate(expectedValue: String) =
    new HavePropertyMatcher[InvitroDataset, String] {
      def apply(info: InvitroDataset) =
        HavePropertyMatchResult(
          info.probeDate == expectedValue,
          "probeDate",
          expectedValue,
          info.probeDate
        )
    }
}
