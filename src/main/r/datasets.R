
load_dataset_dir <- function(
  directory,
  data.pattern = '*.h5',
  label.pattern = '*.csv',
  sweep.window.seconds = NULL,
  dataset.id = NA
) {
  ##
  ## ARGUMENTS
  ##
  assert_directory_exists(directory, access = 'r')
  assert_character(
    data.pattern,
    min.chars = 1,
    any.missing = FALSE,
    len = 1)
  assert_character(
    label.pattern,
    min.chars = 1,
    any.missing = FALSE,
    len = 1)
  assert_int(
    dataset.id,
    na.ok = TRUE)


  ##
  ## LABELS
  ##
  label.files <- dir(
    directory,
    pattern = label.pattern,
    full.names = TRUE
  )

  # read label file
  labels <- read_csv(
    label.files,
    col_types = cols(
      .default = col_double(),
      index = col_double(),
      onset = col_skip(),
      offset = col_skip(),
      exclude = col_logical(),
      notes = col_character()
    )) %>%
    as.data.table()

  setnames(labels, function(n) paste0('y.', n))

  setkey(labels, y.index)



  ##
  ## DATA
  ##
  data.files <- dir(
    directory,
    pattern = data.pattern,
    full.names = TRUE
  )

  # read the data from the data files
  data <- rbindlist(
    future_imap(
      data.files,
      function(f, i) {
        data_file <- read_clampex(
          path = f,
          sweep.window.seconds = sweep.window.seconds
        )

        M   <- data_file$data
        hdr <- data_file$header
        md  <- data_file$metadata

        as_melted_data_table(
          M,
          sweep.start = min(hdr$extractedSweepIx),
          sample.start = min(hdr$extractedSampleIx)
        )[
          ,
          `:=`(
            'dataset' = dataset.id,
            'index' = i - 1L,
            'file' = md$file,
            'date' = md$date,
            'rig' = md$rig,
            'probe' = md$probe,
            'schedule' = md$schedule,
            'protocol' = md$protocol,
            'notes' = md$notes
          )
        ]
      }
    )
  )

  setkey(data, index, dataset)



  ##
  ## JOIN
  ##
  j <- data[labels]

  setkey(j, probe, dataset, index, sweep, sample)
}