package org.hnl.hive.csv

import java.io.{ File, FileWriter }

import scala.collection.mutable.ListBuffer
import scala.math.Ordered
import scala.util.{ Failure, Success, Try }

import org.hnl.hive.cfg.{ NamingUtil, TreatmentConfig, Util }
import org.hnl.hive.cfg.matlab.Chem

import grizzled.slf4j.Logging
import resource.managed

// scalastyle:off multiple.string.literals

/**
 * LabelCatalog
 * <p>
 * Created on Mar 10, 2016.
 * <p>
 *
 * @author Jason White
 */
class LabelCatalog(config: TreatmentConfig) extends Logging {

  case class Line(
      datasetId:      Int,
      fileId:         Int,
      concentrations: List[Double],
      onset:          Double,
      offset:         Double,
      exclude:        Boolean,
      notes:          String,
      file:           String,
      probe:          String
  ) extends Ordered[Line] {

    def toCsvLine: String =
      s"""$datasetId,$fileId,${concentrations.mkString(",")},$onset,$offset,$exclude,$notes,$file,$probe\n"""

    import scala.math.Ordered.orderingToOrdered // scalastyle:ignore import.grouping

    def compare(that: Line): Int = (this.datasetId, this.fileId) compare (that.datasetId, that.fileId)
  }

  type Dataset = List[(String, Int)]
  type Catalog = List[List[String]]

  protected val chemicals = Chem.getChemList(config)
  protected val chemCols = chemicals.sorted.map(_.colName)
  protected val chemVars = chemicals.sorted.map(_.prefix)
  protected val chemZeros = chemicals.sorted.map(_.neutral)

  protected val variables =
    "datasetId" :: "fileId" :: chemVars ::: ("onset" :: "offset" :: "exclude" :: "notes" :: "file" :: "probe" :: Nil)

  protected val targetColumns =
    "index" :: chemCols ::: ("onset" :: "offset" :: "exclude" :: "notes" :: Nil)

  protected val headerLine: String =
    variables.mkString("", ",", "\n")

  protected def getColumnIndices(line: String): List[Int] = {
    val targetCols: List[String] = targetColumns.map(_.toLowerCase)

    val csvCols: List[String] = line.split(",").map(_.trim.toLowerCase).toList

    targetCols.map(csvCols.indexOf(_))
  }

  /**
   * processes the CSV files for every entry in the given catalog
   * @param catalog the catalog of directories
   * @param csvGlob the CSV filespec in glob syntax
   * @param rawGlob the raw filespec in glob syntax
   * @param outputFile the output file
   */
  def processCatalog(catalog: Catalog, csvGlob: String, rawGlob: String, outputFile: String): Unit = {
    // first, we need to add an ID to every dataset
    val datasets: List[Dataset] = org.hnl.hive.util.Util.deepZip(catalog, 1)

    // next, we'll find all the CSV files
    val csvFiles: List[Try[(String, Int)]] = findCsvFiles(datasets, csvGlob).flatten

    // now, we'll form a function call for each file, but we won't call it yet
    val writers: List[(FileWriter) => Unit] = csvFiles.map { pair =>
      pair match {
        case Success((csv, ix)) => ((fw: FileWriter) => writeCsvLines(csv, ix, rawGlob, fw))
        case Failure(e)         => warn(e.getMessage); ((_: FileWriter) => ())
      }
    }

    // next, let's create whatever directories are needed to hold the output file
    val outFile = new File(outputFile)

    if (!outFile.getParentFile.isDirectory) {
      outFile.getParentFile.mkdirs
    }

    // next, we'll open up a file for output
    val output = managed(new FileWriter(outFile))

    // ...and perform the rest of the work using the managed resource
    val result = output.map {
      out =>
        debug(s"writing ${outFile.getAbsolutePath}")

        // write out the header
        out.write(headerLine)

        // write each line
        writers.foreach { writer => writer(out) }
    }

    // either.either is kooky -- maybe a bug in scala-arm 2.0?
    result.either.either match {
      case Right(_) => info(s"created ${outFile.getAbsolutePath}")
      case Left(es) => es.foreach(e => error(s"writing ${outFile.getAbsolutePath}", e))
    }
  }

  /**
   * finds the (single) CSV file for each entry in the dataset list
   * @param datasets the dataset list
   * @param csvGlob the CSV filespec in glob syntax
   * @return nest list of Try() objects: Failures if the number of CSV files != 1
   */
  protected def findCsvFiles(datasets: List[Dataset], csvGlob: String): List[List[Try[(String, Int)]]] =
    datasets.map { dataset =>
      dataset.map { pair =>
        pair match {
          case (dir, ix) => Try({
            val csvSpec = dir + "/" + csvGlob
            val csvList = org.hnl.hive.cfg.Util.findPaths(csvSpec)

            if (csvList.length == 1) {
              (csvList(0), ix)
            }
            else {
              throw new IndexOutOfBoundsException(s"${csvList.length} files found for ${csvSpec} (expected 1)")
            }
          })
        }
      }
    }

  /**
   * reads the given CSV file and writes the corresponding lines to the given output file
   * @param file the CSV file
   * @param datasetId the dataset ID for the file
   * @param rawGlob the raw filespec in glob syntax
   * @param out the output file
   */
  protected def writeCsvLines(file: String, datasetId: Int, rawGlob: String, out: FileWriter): Unit = { // scalastyle:ignore method.length
    val source = managed(io.Source.fromFile(file))

    val result = source.map {
      csv =>
        val csvLines = csv.getLines
        val csvHdr = csvLines.take(1).toList(0)
        val rawFiles = Util.findPaths(Util.dirname(file) + "/" + rawGlob).sorted

        val probeName = for {
          dataset <- NamingUtil.datasetNameFromPath(file)
          dsInfo <- NamingUtil.datasetInfoFromName(dataset)
        } yield if (dsInfo.probeDate.isEmpty) dsInfo.probeName else dsInfo.probeDate + "_" + dsInfo.probeName

        val colIx = getColumnIndices(csvHdr)

        debug(s"file    : ${file}")
        debug(s"target  : ${targetColumns.mkString(",")}")
        debug(s"CSV     : ${csvHdr}")
        debug(s"index   : ${colIx.mkString(",")}")
        debug(s"rawspec : ${rawGlob}")

        // get the position (index) of each column
        val ixs = ListBuffer(colIx: _*)
        val fileIdIx = ixs.remove(0)
        val concentrationIxs = chemicals.map(_ => ixs.remove(0))
        val onsetIx = ixs.remove(0)
        val offsetIx = ixs.remove(0)
        val excludeIx = ixs.remove(0)
        val notesIx = ixs.remove(0)

        debug(s"coIx  : ${concentrationIxs.mkString(",")}")

        // gather the lines
        val lines = for {
          line <- csvLines

          if (line.replace(",", "").trim.length > 0) // only process non-empty lines

          // get column values, retaining empty strings (with "-1" argument)
          vals = line.split(",", -1).map(_.trim)

          // extract fields
          fileId = vals(fileIdIx).toInt
          concentrations = concentrationIxs.zipWithIndex.map({
            case (i, ix) => if (i >= 0) vals(i).toDouble else chemicals.sorted.apply(ix).neutral
          })
          onset = vals(onsetIx).toDouble
          offset = vals(offsetIx).toDouble
          exclude = vals(excludeIx).toBoolean
          notes = vals(notesIx)
            .replaceAllLiterally("\"", "")
            .replaceAllLiterally("''", "")
            .replaceAllLiterally(",", ";")
          suffix = f".*${fileId}%04d${rawGlob.replace("*.", "[.]")}$$"
          _ = debug(s"${line} -> ${suffix}")
          rawfile = rawFiles.filter(s => s matches suffix).head

        } yield Line(datasetId, fileId, concentrations, onset, offset, exclude, notes, rawfile, probeName.getOrElse("<error>"))

        // write the lines to the output stream
        lines.foreach { line => out.write(line.toCsvLine) }
    }

    // either.either is kooky -- maybe a bug in scala-arm 2.0?
    result.either.either match {
      case Right(lines) => debug(s"status: COMPLETE")
      case Left(es)     => es.foreach { e => error(s"processing '${file}'", e) }
    }
  }

}
