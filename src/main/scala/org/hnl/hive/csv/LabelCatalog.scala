package org.hnl.hive.csv

import scala.collection.mutable.ListBuffer
import org.hnl.hive.cfg.TreatmentConfig
import org.hnl.hive.cfg.matlab.Chem
import grizzled.slf4j.Logging
import resource.managed
import java.nio.file.Path
import org.hnl.hive.cfg.Util
import java.io.PrintWriter
import java.io.File
import scala.util.Try
import scala.util.Success
import scala.util.Failure
import java.io.FileWriter

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
      datasetId: Int,
      fileId: Int,
      concentrations: List[Double],
      onset: Double,
      offset: Double,
      exclude: Boolean,
      notes: String,
      file: String) extends Ordered[Line] {

    def toCsvLine: String =
      s"""$datasetId,$fileId,${concentrations.mkString(",")},$onset,$offset,$exclude,$notes,$file\n"""

    import scala.math.Ordered.orderingToOrdered // scalastyle:ignore import.grouping

    def compare(that: Line): Int = (this.datasetId, this.fileId) compare (that.datasetId, that.fileId)
  }

  type Dataset = List[(String, Int)]
  type Catalog = List[List[String]]

  protected val chemicals = Chem.getChemList(config)
  protected val chemLabels = chemicals.sorted.map(_.colName)

  protected val columns =
    "datasetId" :: "fileId" :: chemLabels ::: ("onset" :: "offset" :: "exclude" :: "notes" :: "file" :: Nil)

  protected val targetColumns =
    "index" :: chemLabels ::: ("onset" :: "offset" :: "exclude" :: "notes" :: Nil)

  protected val headerLine: String =
    columns.mkString("", ",", "\n")

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

    // next, we'll open up a file for output
    val outFile = new File(outputFile)
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

    result.either match {
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
  protected def writeCsvLines(file: String, datasetId: Int, rawGlob: String, out: FileWriter): Unit = {
    val source = managed(io.Source.fromFile(file))

    val result = source.map {
      csv =>
        val csvLines = csv.getLines
        val csvHdr = csvLines.take(1).toList(0)
        val rawFiles = Util.findPaths(Util.dirname(file) + "/" + rawGlob).sorted

        val colIx = getColumnIndices(csvHdr)

        debug(s"file  : ${file}")
        debug(s"target: ${targetColumns.mkString(",")}")
        debug(s"CSV   : ${csvHdr}")
        debug(s"index : ${colIx.mkString(",")}")

        val lines = for {
          line <- csvLines

          if (line.trim.length > 0)

          ix = ListBuffer(colIx: _*)
          vals = line.split(",", -1).map(_.trim) // retain empty strings
          fileId = vals(ix.remove(0)).toInt
          concentrations = chemicals.map(_ => vals(ix.remove(0)).toDouble)
          onset = vals(ix.remove(0)).toDouble
          offset = vals(ix.remove(0)).toDouble
          exclude = vals(ix.remove(0)).toBoolean
          notes = vals(ix.remove(0))
            .replaceAllLiterally(""""""", "")
            .replaceAllLiterally("''", "")
            .replaceAllLiterally(",", ";")
          rawfile = rawFiles(fileId)
        } yield Line(datasetId, fileId, concentrations, onset, offset, exclude, notes, rawfile)

        lines.foreach { line => out.write(line.toCsvLine) }
    }

    result.either match {
      case Right(lines) => debug(s"status: COMPLETE")
      case Left(es)     => es.foreach { e => error(s"processing '${file}'", e) }
    }
  }

}
