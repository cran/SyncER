## ----SyncER-load--------------------------------------------------------------
library(SyncER)
has_data <- requireNamespace("SyncERdata", quietly = TRUE)
knitr::opts_chunk$set(eval = has_data) # every chunk below needs SyncERdata; skip them all if it's missing

## ----data-missing-notice, echo = FALSE, eval = !has_data, results = "asis"----
# cat("_SyncERdata is not installed, so the rest of this vignette is not evaluated;",
#     "the explanatory text below still applies to your own data._")

## ----setup--------------------------------------------------------------------
# Choose where this example should run (syncer_wd), and copy the bundled SyncERdata example into it. Default is a temporary directory.
syncer_wd <- file.path(tempdir(), "SyncER_example")

dir.create(file.path(syncer_wd, "record_data_input"), recursive = TRUE, showWarnings = FALSE)
invisible(file.copy(
  list.files(system.file("extdata", "record_data_input", package = "SyncERdata"), full.names = TRUE),
  file.path(syncer_wd, "record_data_input"), overwrite = TRUE
))

# Restore the completed Bacon/Plum output shipped as SyncERdata::bacon_out_files
# (a named list of file lines, keyed by relative output path) back to real files.
for (rel_path in names(SyncERdata::bacon_out_files)) {
  full_path <- file.path(syncer_wd, rel_path)
  dir.create(dirname(full_path), recursive = TRUE, showWarnings = FALSE)
  readr::write_lines(SyncERdata::bacon_out_files[[rel_path]], full_path)
}

# Restore the posterior age-sample tables shipped as SyncERdata list-of-data-frame objects,
# using SyncER's own write_age_output_data() to write one CSV per record.
out_dir <- file.path(syncer_wd, "SyncER_outputs")
write_age_output_data(SyncERdata::out_data_ages, out_dir, verbose = FALSE)
write_age_output_data(SyncERdata::out_data_ages_synced, out_dir, synced = "_synced", verbose = FALSE)

# Run every following chunk from that folder.
knitr::opts_knit$set(root.dir = syncer_wd)

## ----data-structure-----------------------------------------------------------
output_dir <- syncer_setup(wd = syncer_wd)
file_name  <- "record_data_input"

## ----define-events------------------------------------------------------------
horizon_groups <- list(
  "isochron1"       = list(role = "isochron"),
  "isochron2"       = list(role = "isochron"),
  "isochron3"       = list(role = "isochron"),
  "isochron4"       = list(role = "isochron"),
  "isochron5"       = list(role = "isochron"),
  "isochron6"       = list(role = "isochron"),
  "isochron7"       = list(role = "isochron"),
  "isochron8"       = list(role = "isochron"),
  "isochron9"       = list(role = "isochron"),
  "synchronous"     = list(role = "other"),
  "non-synchronous" = list(role = "other"),
  "synchro-test"    = list(role = "test", members = c("synchro-test", "synchro-test-wrong"))
  # Add one entry per event type in your records here. To test a second, independent set of
  # horizons in the same run, just add another "test" entry, e.g.:
  # "synchro-test2" = list(role = "test", members = c("synchro-test2", "synchro-test2-wrong"))
)

event_depths <- list("core1"=c(), "core2"=c(), "core3"=c(), "core4"=c(), "core5"=c()) # List with all event depths that should be considered as instantaneous deposits should you not have worked with event-free depths in the input file
hiatuses <- list("core1"=c(), "core2"=c(), "core3"=c(), "core4"=c(), "core5"=c()) # List with all depths that should be considered as hiatuses per record

radiocarbon_sample_names <- c("sample") # indicate how your radiocarbon samples are labeled
lead_sample_names <- c("") #indicate how your Pb ages are labelled, leave blank if you only consider radiocarbon ages

invisible(list2env(load_horizon_names(horizon_groups), environment())) # derives event_types, isochrons, test_events, isochron_groups, and test_horizon_groups

## ----age-setup----------------------------------------------------------------
input_record_data <- read_record_data(file_name = file_name)
record_data <- input_record_data$record_data
max_depths <- input_record_data$max_depths # This extends your age-depth models to the depth of the top of the deepest event mentioned in the input file. If you want to have them extend deeper, set them separately per record as such: max_depths <- c("record1"=100, "record2"=200)
sedrates <- input_record_data$sedrates  

age_model_input(record_data,
                radiocarbon_sample_names = radiocarbon_sample_names,
                lead_sample_names = lead_sample_names)

## ----age-toggle---------------------------------------------------------------
run_age <- FALSE # set to TRUE to actually (re)run rbacon/rplum; requires library(rbacon) or library(rplum)

## ----age-depth modelling------------------------------------------------------
if (run_age) {
for (record in names(record_data)){

  # Adjust this block if you need specific settings for a certain record, and copy it if you need different settings for multiple records. Don't forget to uncomment it to make sure your age-depth models are constructed correctly. Or change to Plum if you defined lead_sample_names.

  # if (record=="record"){ ## Replace "record" by the name of the record for which you require specific settings
  #   Bacon(core = record,
  #       coredir = syncer_wd,
  #       sep = ',',
  #       rotate.axes = TRUE,
  #       thick = 2,
  #       hiatus = hiatuses[[record]],
  #       slump = event_depths[[record]],
  #       ssize = 10000,
  #       d.max = max_depths[record],
  #       acc.mean = round(sedrates[record]),
  #       suggest = FALSE,
  #       accept.suggestions = TRUE
  #       )
  # } else if {

  Bacon(core = record,
        coredir = syncer_wd,
        sep = ',',
        rotate.axes = TRUE,
        thick = 2,
        ssize = 1000,
        slump = event_depths[[record]],
        hiatus = hiatuses[[record]],
        d.max = max_depths[record],
        acc.mean = round(sedrates[record]),
        suggest = FALSE,
        accept.suggestions = TRUE,
        run = FALSE ## set to FALSE in case you already have the age models constructed
        )
  # }
}
}

## ----what -ages---------------------------------------------------------------
reload_existing <- TRUE ## FALSE processes the bundled .out files and creates out_data_ages/; set TRUE to reuse an existing out_data_ages/
event_ages <- load_event_ages(record_data = record_data, event_types = event_types, max_depths = max_depths, isochrons = isochrons, test_horizons = test_events, reload_existing = reload_existing, instantaneous_event_depths=event_depths, thick = 2 ## set to the thick value used in Bacon/Plum, single value or as list (for example: list("core1" = 2, "core3 = 1))
                           )
if (!reload_existing) {
  write_age_output_data(event_ages)}

## ----set-age-offset-----------------------------------------------------------
age_offset <- bp_datum() # value to ensure no negative values in the dataset
confidence_level = 0.95
age_difference = 0.07 

## ----test-synchronicity-isochrons---------------------------------------------
isochron_stats <- process_event_ages(event_ages, isochrons, offset=age_offset)
isochron_synchro <- compute_synchronicity_values(isochron_stats, isochrons, horizon_groups = isochron_groups, confidence_level = confidence_level, age_difference = age_difference)
isochron_results <- verify_synchronicity(isochron_synchro, isochrons, isochron=TRUE, offset=age_offset)

## ----isochron-match-----------------------------------------------------------
matching_method <- c("isochron1" = "mean_fixederror", "isochron2" = "age", "isochron3" = "Bayesian", "isochron4" = "ageofrecord", "isochron5" = "age") # choose from mean, ageofrecord or age
horizons <- c("isochron1", "isochron2", "isochron3", "isochron4", "isochron5", "isochron6", "isochron7")
age_record <- "core2" # choose the age record you want to use as reference when matching_method "ageofrecord" is used
age_value <- c("isochron2" = 1100, "isochron5" = 4100) # give age that needs to be used in case matching_method "age" is used
age_error <- c("isochron1" = 10, "isochron2" = 20, "isochron5" = 25) # give error on age that needs to be used in case matching_method "age" is used
age_cc <- c("isochron2" = 0, "isochron5" = 0, "isochron1" = 0)
excluded_records <- c() # This can exclude a record entirely (excluded_records = c("core3")) or for certain horizons (excluded_records = list("isochron3" = "core3")).

## ----synced-ages--------------------------------------------------------------
adjusted_ages <- synchronize_ages(isochron_stats, method = matching_method, horizons = horizons, age_record = age_record, age_value = age_value, age_error = age_error, offset = age_offset, excluded_records = excluded_records, horizon_groups = isochron_groups)

## ----create-synced-csvs-------------------------------------------------------
record_data_synced <- age_model_input(record_data, adjusted_ages,
                                       radiocarbon_sample_names = radiocarbon_sample_names, lead_sample_names = lead_sample_names, original_ages = TRUE) #Set original_ages = FALSE if you don't want the age-depth models to also use the original (radiocarbon) ages; you can adjust this per record (e.g. if one record has bad accuracy) by passing c("core1" = FALSE). Records not listed fall back to TRUE.

## ----create-synced-age-models-------------------------------------------------
if (run_age) {
for (record_synced in names(record_data_synced)){
  # Adjust this block if you need specific settings for a certain record, and copy it if you need different settings for multiple records. Don't forget to uncomment it to make sure your age-depth models are constructed correctly. Or change to Plum() if you defined lead_sample_names

  # if (record_synced=="record_synced"){ ## Replace "record" by the name of the record for which you require specific settings
  #   Bacon(core = record_adjusted,
  #       coredir = syncer_wd,
  #       sep = ',',
  #       rotate.axes = TRUE,
  #       thick = 1,
  #       hiatus = hiatuses[[record]],
  #       slump = event_depths[[record]],
  #       ssize = 10000,
  #       d.max = max_depths[record],
  #       acc.mean = round(sedrates[record]),
  #       suggest = FALSE,
  #       accept.suggestions = TRUE
  #       )
  # } else {

  Bacon(core = record_synced,
        coredir = syncer_wd,
        sep = ',',
        rotate.axes = TRUE,
        thick = 2,
        ssize = 1000,
        d.max = max_depths[record],
        hiatus = hiatuses[[record]],
        acc.mean = round(sedrates[record]),
        suggest = FALSE,
        accept.suggestions = TRUE,
        run = FALSE #set to FALSE in case you already have the age models constructed
        )
  # }
}
}

## ----extract-synced-ages------------------------------------------------------
reload_existing <- TRUE ## FALSE processes the bundled _synced .out files and creates out_data_ages_synced/; TRUE to reuse an existing folder
event_ages_synced <- load_event_ages(record_data = record_data, event_types = event_types, max_depths = max_depths, isochrons = isochrons, test_horizons = test_events, synced = "_synced", reload_existing = reload_existing, thick = 2)
if (!reload_existing) {
  write_age_output_data(event_ages_synced, synced="_synced")}

## ----calculate-thresholds-from-synchronized-data------------------------------
thresholds <- compute_isochron_thresholds(adjusted_ages, age_offset=age_offset, sigma_multiplier=2)
print_validation_summary(thresholds)

## ----test-isochrons-synced----------------------------------------------------
isochron_stats_synced <- process_event_ages(event_ages_synced #change to event_ages in case you did not create new synchronized age models
                                                 , isochrons, offset=age_offset)
isochron_synchro_synced <- compute_synchronicity_values(isochron_stats_synced, isochrons,confidence_level=thresholds$confidence_levels,  age_difference=thresholds$validation_thresholds, 
                                                 horizon_groups = isochron_groups)
isochron_results <- verify_synchronicity(isochron_synchro_synced, isochrons, isochron=TRUE, synced="_synced" # set this to the suffix of the run you are referring to
                                              , offset=age_offset)

## ----determine-test-thresholds------------------------------------------------
positioning_test <- list("synchro-test" = c("isochron2","isochron3"))

thresholds_tests <- sapply(positioning_test, function(horizons) { max(thresholds$validation_thresholds[horizons], na.rm = TRUE) })

## ----test-synchronicity-synced------------------------------------------------
test_event_stats <- process_event_ages(event_ages_synced, #change to event_ages in case you did not create new synchronized age models
                                       test_events, offset=age_offset)
test_synchro <- compute_synchronicity_values(test_event_stats, test_events, confidence_level = confidence_level, age_difference = thresholds_tests, horizon_groups = test_horizon_groups)
synchronicity_test <- verify_synchronicity(test_synchro, test_events, synced="_synced", offset=age_offset)

## ----add-synchronous-horizons-------------------------------------------------
matching_method <- c("Bayesian")
non_synchro_horizons <- list("core2_synced" = "synchro-test-wrong", "core5_synced" = "synchro-test-wrong") # Horizons for which you tested synchronicity, but they are likely not and so should not be age-matched across records. Tested horizon sets that should be excluded entirely can be listed as "global" = "tested horizon".

adjusted_ages <- synchronize_ages(test_event_stats, method = matching_method, horizons = "synchro-test", nonsynchro_horizons = non_synchro_horizons, offset = age_offset, horizon_groups = test_horizon_groups)
record_data_synced_1 <- age_model_input(record_data_synced, adjusted_ages,
                                        radiocarbon_sample_names = radiocarbon_sample_names, lead_sample_names = lead_sample_names)

## ----add-non-synchronous-horizons---------------------------------------------
non_synchro_ages <- assign_nonsynchro_age(adjusted_ages, non_synchro_horizons, test_event_stats, horizon_groups = test_horizon_groups)
record_data_synced_1 <- age_model_input(record_data_synced_1, non_synchro_ages, update_records = TRUE, radiocarbon_sample_names = radiocarbon_sample_names, lead_sample_names = lead_sample_names)

## ----iterative-age------------------------------------------------------------
if (run_age) {
for (record_synced_1 in names(record_data_synced_1)){
  
  # Adjust this block if you need specific settings for a certain record, and copy it if you need different settings for multiple records. Don't forget to uncomment it to make sure your age-depth models are constructed correctly.

  if (record=="core2_synced_1"){ ## Replace "record" by the name of the record for which you require specific settings
   Bacon(core = record_synced_1,
        coredir = syncer_wd,
        sep = ',',
        rotate.axes = TRUE,
        thick = 2,
        ssize = 1000,
        d.max = max_depths[record],
        slump = event_depths[[record]],
        hiatus = hiatuses[[record]],
        acc.mean = round(sedrates[record]),
        suggest = FALSE,
        accept.suggestions = TRUE,
        #younger.than = c(5),
        run = TRUE #set to FALSE in case you already have the age models constructed
       )
  } else if (record=="core5_synced_1"){ ## Replace "record" by the name of the record for which you require specific settings
   Bacon(core = record_synced_1,
        coredir = syncer_wd,
        sep = ',',
        rotate.axes = TRUE,
        thick = 2,
        ssize = 1000,
        d.max = max_depths[record],
        slump = event_depths[[record]],
        hiatus = hiatuses[[record]],
        acc.mean = round(sedrates[record]),
        suggest = FALSE,
        accept.suggestions = TRUE,
        #older.than = c(9),
        run = TRUE #set to FALSE in case you already have the age models constructed
       )
  } else {

    Bacon(core = record_synced_1,
        coredir = syncer_wd,
        sep = ',',
        rotate.axes = TRUE,
        thick = 2,
        ssize = 1000,
        d.max = max_depths[record],
        slump = event_depths[[record]],
        hiatus = hiatuses[[record]],
        acc.mean = round(sedrates[record]),
        suggest = FALSE,
        accept.suggestions = TRUE,
        run = TRUE #set to FALSE in case you already have the age models constructed
        )
   }
}
}

