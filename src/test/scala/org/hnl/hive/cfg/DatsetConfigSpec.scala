package org.hnl.hive.cfg

import org.scalatest._

/**
  * DatsetConfigSpec
  * <p>
  * Created on Apr 12, 2017.
  * <p>
  *
  * @author Jason White
  */
class DatsetConfigSpec extends WordSpec with Matchers with Inspectors with OptionValues with CustomMatchers {

  "DatasetConfig" should {

    "parse probe names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2015_07_14_dopamine_A_EL_2015_07_07")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2015_10_27_dopamine_am_KK_2013_07_29")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2015_10_27"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("am_KK"),
        probeDate("2013_07_29")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2015_11_12_pH_HLH_pm3_KK_2013_07_29")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2015_11_12"),
        dsClass("pH"),
        dsProtocol("pH_HLH"),
        probeName("pm3_KK"),
        probeDate("2013_07_29")
      )

      val option4 = DatasetConfig.datasetInfoFromPath("2017_03_09_5HT_uncorrelated_octaflow_bypass_100k_97Hz_V8")

      option4 should not be null
      option4 shouldBe defined
      option4.value should have(
        dsDate("2017_03_09"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_octaflow_bypass_100k_97Hz"),
        probeName("V8"),
        probeDate("")
      )

    }

    "parse uncorrelated dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2016_06_15_5HT_uncorrelated_100k_97Hz_A")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2016_06_15"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_100k_97Hz"),
        probeName("A"),
        probeDate("")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2017_03_09_5HT_uncorrelated_octaflow_bypass_100k_97Hz_V8")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2017_03_09"),
        dsClass("serotonin"),
        dsProtocol("5HT_uncorrelated_octaflow_bypass_100k_97Hz"),
        probeName("V8"),
        probeDate("")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2017_03_27_DA_uncorrelated_octaflow_100k_97Hz_S8")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2017_03_27"),
        dsClass("dopamine"),
        dsProtocol("DA_uncorrelated_octaflow_100k_97Hz"),
        probeName("S8"),
        probeDate("")
      )

      val option4 = DatasetConfig.datasetInfoFromPath("2016_06_15_DA_RBV1_100k_97Hz_J_EL_2016_06_10")

      option4 should not be null
      option4 shouldBe defined
      option4.value should have(
        dsDate("2016_06_15"),
        dsClass("dopamine"),
        dsProtocol("DA_RBV1_100k_97Hz"),
        probeName("J_EL"),
        probeDate("2016_06_10")
      )

      val option5 = DatasetConfig.datasetInfoFromPath("2019_04_18_KYNA_uncorrelated_100k_97Hz_CF048")

      option5 should not be null
      option5 shouldBe defined
      option5.value should have(
        dsDate("2019_04_18"),
        dsClass("kynurenic acid"),
        dsProtocol("KYNA_uncorrelated_100k_97Hz"),
        probeName("CF048"),
        probeDate("")
      )

      val option6 = DatasetConfig.datasetInfoFromPath("2019_05_15_pH_uncorrelated_100k_97Hz_CFR001")

      option6 should not be null
      option6 shouldBe defined
      option6.value should have(
        dsDate("2019_05_15"),
        dsClass("pH"),
        dsProtocol("pH_uncorrelated_100k_97Hz"),
        probeName("CFR001"),
        probeDate("")
      )

    }

    "parse three-transmitter dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2017_06_22_DA_5HT_NE_octaflow_400Vs_10Hz_X1_2017_01_01")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2017_06_22"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_octaflow_400Vs_10Hz"),
        probeName("X1"),
        probeDate("2017_01_01")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2017_06_22_DA_5HT_NE_octaflow_400Vs_10Hz_X1")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2017_06_22"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_octaflow_400Vs_10Hz"),
        probeName("X1"),
        probeDate("")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2017_06_22_DA_5HT_NE_octaflow_400Vs_10Hz")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2017_06_22"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_octaflow_400Vs_10Hz"),
        probeName(""),
        probeDate("")
      )

    }

    "parse four-transmitter dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_pH_uncorrelated_100k_97Hz_CF003_2018_03_24")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("2018_03_24")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_pH_uncorrelated_100k_97Hz_CF003")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_pH_uncorrelated_100k_97Hz")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_pH_uncorrelated_100k_97Hz"),
        probeName(""),
        probeDate("")
      )

    }

    "parse five-transmitter dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz_CF003_2018_03_24")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("2018_03_24")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz_CF003")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_pH_uncorrelated_100k_97Hz"),
        probeName(""),
        probeDate("")
      )

    }

    "parse six-transmitter dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz_CF003_2018_03_24")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("2018_03_24")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz_CF003")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("")
      )

      val option3 = DatasetConfig.datasetInfoFromPath("2018_03_27_DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz")

      option3 should not be null
      option3 shouldBe defined
      option3.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_KYNA_pH_uncorrelated_100k_97Hz"),
        probeName(""),
        probeDate("")
      )

    }

    "parse same-day repeated probe dataset names" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2019_01_07_DA_5HT_NE_5HIAA_uncorrelated_100k_97Hz_MM001W10R13_2")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2019_01_07"),
        dsClass("mixture"),
        dsProtocol("DA_5HT_NE_5HIAA_uncorrelated_100k_97Hz"),
        probeName("MM001W10R13"),
        probeDate("")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("2018_03_27_5HT_5HIAA_pH_uncorrelated_100k_97Hz_CF003_2018_03_24_2")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2018_03_27"),
        dsClass("mixture"),
        dsProtocol("5HT_5HIAA_pH_uncorrelated_100k_97Hz"),
        probeName("CF003"),
        probeDate("2018_03_24")
      )

    }

    "parse dataset names from full path" in {
      val option1 = DatasetConfig.datasetInfoFromPath("path/to/data/2015_07_14_dopamine_A_EL_2015_07_07")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("path/to/data/2015_07_14_dopamine_A_EL_2015_07_07/")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

    }

    "parse dataset names from filename" in {
      val option1 = DatasetConfig.datasetInfoFromPath("2015_07_14_dopamine_A_EL_2015_07_07.abf")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

    }

    "parse dataset names from directory+filename" in {
      val option1 = DatasetConfig.datasetInfoFromPath("data/2015_07_14_dopamine_A_EL_2015_07_07.abf")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

      val option2 = DatasetConfig.datasetInfoFromPath("/2015_07_14_dopamine_A_EL_2015_07_07.abf")

      option2 should not be null
      option2 shouldBe defined
      option2.value should have(
        dsDate("2015_07_14"),
        dsClass("dopamine"),
        dsProtocol("dopamine"),
        probeName("A_EL"),
        probeDate("2015_07_07")
      )

    }

    "parse dataset names using dataset.conf as override" in {
      val option1 = DatasetConfig.datasetInfoFromPath("src/test/data/full/2018_07_22_NE_400Vs_97Hz_CF007_2018_01_01")

      option1 should not be null
      option1 shouldBe defined
      option1.value should have(
        dsDate("2019-07-22"),
        dsClass("DA"),
        dsProtocol("rbv_100k_97Hz"),
        probeName("CFR008"),
        probeDate("2019-01-01")
      )

    }

  }

}


