

## ---- fn_melt
#' Takes an S x 1000 matrix (S sweeps of 1000 samples) and returns a melted
#' data.table with columns sweep, sample, current
#'
#' @param x
#' @param sweep.start
#' @param sample.start
#'
#' @return
#' @export
#'
#' @examples
as_melted_data_table <- function(
  x,
  sweep.start = 1,
  sample.start = 1
) {
  assert_matrix(x,
                mode = 'double',
                all.missing = FALSE,
                min.cols = 1000,
                null.ok = FALSE)
  assert_integerish(sweep.start, len = 1, lower = 1)
  assert_integerish(sample.start, len = 1, lower = 1)

  DT <- as.data.table(x)[       # convert to data.table
    ,
    sweep := (1L:.N) +          # add sweep numbers
      sweep.start - 1L          # with appropriate start number
  ] %>%
    melt(                       # tidy up so we have one sample per row...
      id.vars = c('sweep'),     # ...by converting all columns but 'sweep'...
      value.name = 'current',   # ...putting values in 'current' column...
      variable.name = 'dummy'   # ...and we'll ignore the column names
    )

  setkey(DT, sweep)             # set a key on the sweep for fast grouping

  DT[
    ,
    sample := (1L:.N) +         # add sample numbers...
      sample.start - 1L,        # ...with appropriate start number
    by = sweep                  # ...for each sweep
  ]

  DT[
    order(sweep, sample),       # order by sweep and sample...
    .(sweep, sample, current)   # ...and return "correct" column position
  ]
}


## ---- fn_fix
#' Takes a three-column data.table (sweep, sample, current) and corrects
#' clipping overflow induced by the DAQ
#'
#' @param V
#' @param current.cutoff
#' @param dcurrent.cutoff
#'
#' @return
#' @export
#'
#' @examples
fix_overflow <- function(V, current.cutoff=-1999.9, dcurrent.cutoff=-3500) {
  # check arguments
  assert_data_table(V,
                    min.cols = 3)
  assert_number(current.cutoff, upper = 0)
  assert_number(dcurrent.cutoff, upper = 0)

  # set up some by-reference data.table goodness
  D <- setDT(V)

  # first, make some computations...
  # d.current:  time-difference of current response
  # rleid:      groups consecutive identical current values
  D[
    ,
    `:=`(
      d.current = current - shift(current, 1),
      rleid = rleid(current)
    ),
    by = sweep
  ]

  # Now, we can add a column that indicates overflow. We start by looking at
  # groups of consecutive identical current values (via rleid) that are below
  # the cutoff value. For each group, if the first d.current value is below the
  # cutoff, then the whole group is marked as overflow.
  D[
    current < current.cutoff,
    overflow := .SD[1L] < dcurrent.cutoff,
    by = rleid,
    .SDcols = c('d.current')
  ]

  # Finally, we correct the current in overflow areas...
  D[
    overflow == 1,
    current := 2000
  ]

  # # ...and re-compute the time difference
  # D[
  #   ,
  #   d.current := current - shift(current, 1),
  #   by = sweep
  # ]

  # remove columns used internally
  D[
    ,
    `:=`(
      d.current = NULL,
      rleid = NULL
    )
  ]

  # reorder
  D[
    order(sweep, sample)
  ]

  # return invisibly for chaining
  invisible(D)
 }


## ---- fn_read
#' Reads an ABF and returns data accessors
#'
#' @param path
#'
#' @return
#' @export
#'
#' @examples
.open_abf <- function(path) {
  # open the ABF file
  abf <- readABF(path)
  hdr <- abf$header

  # build the "canonical" header
  header <- list(
    abfHeader = hdr,
    path = abf$path,
    formatVersion = paste(rev(hdr$uFileVersionNumber), collapse = '.'),
    recChNames = abf$channelNames,
    recChUnits = abf$channelUnits,
    samplingIntervalInSec = abf$samplingIntervalInSec,
    sweepCount = hdr$lActualEpisodes,
    sweepSampleCount = hdr$sweepLengthInPts,
    sweepFreq = 1 / (abf$samplingIntervalInSec * hdr$sweepLengthInPts),
    sampleFreq = 1 / abf$samplingIntervalInSec,
    recTime = hdr$recTime,
    abfTimestamp = as.integer(
      ymd(toString(hdr$uFileStartDate)) +
        seconds(hdr$recTime[2])
    )
  )

  # define a function to extract the data later
  extract_fn <- function(file, sweep_win, data_ch, sample_win) {

    # extract the requested data subset
    data_raw <- abf$data[sweep_win] %>%
      map(
        function(sweep) {
          return(sweep[sample_win , data_ch])
        })

    # convert to matrix
    data_mat <- do.call(rbind, data_raw)

    # return data
    data_mat
  }

  # return objects
  list(
    file = h5,
    header = header,
    get_data = extract_fn
  )
}


## ---- fn_readhdf5
#' Reads an HDF5 file and returns data accessors
#'
#' @param path
#'
#' @return
#' @export
#'
#' @examples
.open_h5 <- function(path) {
  # open the HDF5 file
  h5 <- h5file(path, mode = 'r')
  hdr <- h5attributes(h5[['header']])

  # build the "canonical" header
  header <- list(
    abfHeader = list(),
    path = h5$get_filename(),
    formatVersion = '?',                          # TODO add to h5 header
    recChNames = hdr$recChNames,
    recChUnits = rep_along(hdr$recChNames, '?'),  # TODO add to h5 header
    samplingIntervalInSec = hdr$si * 1e-6,
    sweepCount = hdr$sweepCount,
    sweepSampleCount = hdr$sweepSampleCount,
    sweepFreq = hdr$sweepFreq,
    sampleFreq = hdr$sampleFreq,
    abfTimestamp = hdr$abfTimestamp,
    recTime = hdr$recTime,
    protocolPath = '?'                            # TODO add to h5 header
  )

  # define a function to extract the data later
  extract_fn <- function(file, sweep_win, data_ch, sample_win) {

    # extract the requested data subset
    data_mat <- file[['data']][
      sweep_win,  # sweeps
      data_ch,    # channel
      sample_win  # samples
    ]

    # close and clean up
    h5$close_all()

    # return data
    data_mat
  }

  # return objects
  list(
    file = h5,
    header = header,
    get_data = extract_fn
  )

}


## ---- fn_read_clampex
#' Title
#'
#' @param path
#' @param chan.pattern
#' @param sweep.window.seconds
#' @param sample.window
#'
#' @return
#' @export
#'
#' @examples
read_clampex <- function(
  path,
  chan.pattern = stringr::fixed('FSCV'),
  sweep.window.seconds = NULL,
  sample.window = NULL
) {
  ##
  ## ARGUMENTS
  ##

  assert_file_exists(path, access = 'r')
  assert_character(chan.pattern)
  assert_numeric(
    sweep.window.seconds,
    lower = 0,
    finite = TRUE,
    len = 2,
    null.ok = TRUE)
  assert_integerish(
    sample.window,
    lower = 1,
    null.ok = TRUE)



  ##
  ## DATA
  ##

  ext <- tolower(tools::file_ext(path))
  data <- switch(
    ext,
    "abf"  = .open_abf(path),
    "h5"   = .open_h5(path),
    "hdf5" = .open_h5(path),
    stop(sprintf(
      'Unknown file format [%s] for clampex file %s',
      ext, path
    ))
  )
  header <- data$header



  ##
  ## PATH-ENCODED METADATA
  ##

  # parse path decorations

  file <- basename(path)

  parts <- tryCatch(
    file %>%
      str_remove(pattern = glue::glue('_[0-9]+[.]{ext}$')) %>%
      str_split(stringr::fixed('__'), simplify = TRUE),
    error = character(0)
  )

  metadata <- list(
    file     = file,
    date     = tryCatch(ymd(parts[1]), error = NA_Date_),
    rig      = tolower(parts[2]),
    schedule = parts[3],
    protocol = parts[4],
    probe    = parts[5],
    notes    = parts[6]
  )



  ##
  ## CHANNEL
  ##

  # find the channel that matches the channel.pattern
  data_ch <- which(
    str_detect(header$recChNames, chan.pattern))

  # if there are multiple FSCV channels, we need to split things up (elsewhere)
  if (length(data_ch) != 1)
    stop(sprintf(
      'Found %d channels matching %s in file %s, expected 1\n[%s]',
      length(data_ch),
      toString(chan.pattern),
      header$path,
      paste(header$channelNames, sep = ', ')))



  ##
  ## SAMPLE WINDOW
  ##

  if (is.null(sample.window)) {
    # if not specified, we'll use the standard 1000-sample window, which depends
    # on the sweep size
    sweep_size <- toString(header$sweepSampleCount)
    sample_win <- switch(
      sweep_size,
      '1032' = 16:1015,
      '10000' = 160:1159,
      stop(sprintf(
        'Found unexpected sweep length %s in H5 %s',
        sweep_size,
        header$path))
    )
  }
  else if (length(sample.window) < 2) {
    # if the sample window only has one value, return all samples
    sample_win <- 1:header$sweepSampleCount
  }
  else if (length(sample.window) == 2) {
    # if there are two values, use them as start and end
    sample_win <- sample.window[1]:sample.window[2]
  }
  else {
    # if there are more than two samples, take it as an index vector
    sample_win <- sample.window
  }



  ##
  ## SWEEP WINDOW
  ##

  if (is.null(sweep.window.seconds)) {
    # if not specified, we'll return all of the sweeps
    sweep_win <- 1:header$sweepCount
  }
  else {
    # otherwise, calculate the sweep window based on the sampling frequency
    sweep_win_sweeps <- 1 + round(sweep.window.seconds * header$sweepFreq)
    sweep_win <- sweep_win_sweeps[1]:sweep_win_sweeps[2]
  }



  ##
  ## VALIDATE
  ##

  # do a nice check before attempting to subset the data
  assert_true(all(between(data_ch, 1, length(header$recChNames))))
  assert_true(all(between(sample_win, 1, header$sweepSampleCount)))
  assert_true(all(between(sweep_win, 1, header$sweepCount)))

  # add the values to the header
  header$extractedChannelIx <- data_ch
  header$extractedSampleIx <- sample_win
  header$extractedSweepIx <- sweep_win



  ##
  ## EXTRACT
  ##

  data_mat <- data$get_data(data$file, sweep_win, data_ch, sample_win)

  # we give each sample column a name
  colnames(data_mat) <- paste0('S', sample_win) # S1, S2, etc.



  ##
  ## RETURN
  ##

  list(
    header   = header,
    data     = data_mat,
    metadata = metadata
  )
}


