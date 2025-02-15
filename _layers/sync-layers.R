##
## sync-layers.R
## Dan Villarreal (d.vill@pitt.edu)
##
## Download layer definitions from APLS to create/update Markdown files for use
## in APLS documentation, and inject JavaScript code that allows for layer
## descriptions in tooltips
##

##Parameters
##Directory for Markdown files
md_dir <- "."
##Whether or not to write/update Markdown files
write_new_md_files <- TRUE
update_existing_md_files <- TRUE
##Path to JavaScript file
js_path <- "../assets/js/keyterm-layer-links.js"
##Whether or not to write/update JavaScript file
update_existing_js_file <- TRUE


# Preliminaries -----------------------------------------------------------

##Ensure correct working directory
if (basename(getwd()) != "_layers") {
  stop("Please change working directory.")
}

##Packages
suppressPackageStartupMessages(library(tidyverse))
library(nzilbb.labbcat)
library(yaml)

##Authenticate
lc <- "https://apls.pitt.edu/labbcat"
username <- "APLS_USERNAME"
pw <- "APLS_PASSWORD"
if (nchar(Sys.getenv(username))==0 || nchar(Sys.getenv(pw))==0) {
  stop("Please add APLS_USERNAME and APLS_PASSWORD variables to ~/.Renviron or PATH")
}
invisible(labbcatCredentials(lc, Sys.getenv(username), Sys.getenv(pw)))


# Download & categorize layer data -------------------------------------------

##Get data on all "layers" (which include transcript/participant attributes)
all_layers <- getLayers(lc)

##Wrangle all-layer data
all_layers <- all_layers |>
  ##Make into a tibble
  as_tibble() |>
  ##NAs for blanks
  mutate(across(where(is.character), ~ na_if(.x, ""))) |>
  ##Nicer column names
  rename(short_description = description, project = category, parent = parentId, 
         data_type = type, vertical_peers = peersOverlap,
         layer_manager = layer_manager_id) |>
  ##Nicer column order
  relocate(id, short_description, layer_id, .before=1) |>
  relocate(extra, .after=last_col())

##Separate layers, transcript attributes, and participant attributes
##main_participant is hard to categorize for user-facing purposes
all_layers <- all_layers |>
  filter(id != "main_participant")
transcript_attr <-
  all_layers |>
  filter(str_detect(id, "^(transcript_|corpus$|episode$|transcript$)"))
participant_attr <-
  all_layers |>
  filter(str_detect(id, "^(participant_|participant$)"))
layers <-
  all_layers |>
  ##Remove participant/transcript attributes
  anti_join(transcript_attr, "id") |>
  anti_join(participant_attr, "id")


# Wrangle transcript layers -----------------------------------------------

##Remove columns
layers <- layers |>
  select(-c(
    ##Relevant only to participant/transcript attributes
    style, class_id, attribute, hint, display_order, 
    searchable, access, label, notes,
    ##List-columns
    validLabels, validLabelsDefinition,
    ##Graph-algebraic columns (see https://doi.org/10.1016/j.csl.2017.01.004 )
    parentIncludes, saturated,
    ##enabled is often subject to change
    enabled,
    ##I can't figure out what subtype does
    subtype))


##Translate columns to more readable format
layers <- layers |>
  ##For now, only keep the first line of description as short_description
  mutate(across(short_description, ~ str_remove(.x, regex("\n.+", dotall=TRUE))),
         across(c(project, layer_manager, extra), ~ replace_na(.x, "(none)")),
         across(scope, ~ case_match(.x, 
                                    "W" ~ "word",
                                    "S" ~ "segment",
                                    "M" ~ "phrase",
                                    "F" ~ "span")),
         across(data_type, ~ case_when(
           id %in% c("turn","utterance") ~ "timing-only",
           data_type=="ipa" ~ "phonological",
           data_type=="number" ~ "numeric",
           data_type=="string" ~ "text")),
         across(alignment, ~ case_when(
           ##turn/word/segment *technically* have alignment=2 because that's
           ##  relative to their parents (participant/turn/word), but
           ##  *conceptually* they correspond to a "full" phrase/word/segment
           ##However, LaBB-CAT uses the underlying alignment to style layer
           ##  icons, so for now, keep this as-is.
           # id %in% c("turn","word","segment") ~ "complete interval",
           
           ##Same story for phrase layers---LaBB-CAT uses the sub-intervals
           ##  icon; for exporting matches to CSV, it treats phrase layers as
           ##  though they can't have horizontal peers (and actually, ditto for
           ##  the hidden scopes 'C' for corpus, 'E' for episode, 'G' for
           ##  participant/main_participant/transcript, though they never show
           ##  up with layer icons)
           # scope=="span" ~ "complete interval",
           
           ##Straightforward translations
           .x==0 ~ "complete interval",
           .x==1 ~ "timepoint",
           .x==2 ~ "sub-interval")),
         ##Recode shorter layer_manager values
         across(layer_manager, ~ case_match(.x,
                                            "CELEX-EN" ~ "CELEX-English",
                                            "py" ~ "Python",
                                            .default=.x)))

##Add attributes pertaining to how users can interact with layers
layers <- layers |>
  ##All layers can be exported from https://apls.pitt.edu/labbcat/transcripts
  ##  (though some appear in weird ways--or not at all--depending on the format)
  mutate(transcripts_exportable = TRUE,
         
         ##turn and utterance can't be exported from
         ##  https://apls.pitt.edu/labbcat/matches
         matches_exportable = !(id %in% c("turn", "utterance")),
         
         ##How layer can be used in https://apls.pitt.edu/labbcat/search
         searchable = case_match(data_type,
                                 ##In search matrix, but only for anchoring matches
                                 "timing-only" ~ "anchor-only",
                                 ##In search matrix with a minimum & maximum
                                 "numeric" ~ "min_max",
                                 ##In search matrix with a regex
                                 c("phonological", "text") ~ "regex"),
         
         ##Whether layer can the target of a search (https://github.com/nzilbb/labbcat-server/blob/b70d69/user-interface/src/main/angular/projects/labbcat-view/src/app/search-matrix/search-matrix.component.ts#L187-L194)
         search_targetable = case_when(
           id=="orthography" ~ "word",
           scope=="segment" ~ "segment",
           id %in% c("turn","utterance") ~ "no",
           alignment != "complete interval" ~ scope,
           .default="no"),
         
         ##Whether layer can be selected/deselected in 
         ##  https://apls.pitt.edu/labbcat/transcript (FALSE means that it's
         ##  displayed through other means)
         transcript_selectable = !(id %in% c("comment", "noise")),
         
         ##Do count boxes show up in matches > CSV Export?
         ##  https://github.com/nzilbb/labbcat-server/blob/9ee4cb3/user-interface/src/main/angular/projects/labbcat-common/src/lib/layer-checkboxes/layer-checkboxes.component.html#L187-L190
         export_includeCounts = case_when(
           !matches_exportable ~ NA, ##Not shown in matches > CSV Export
           id=="word" ~ FALSE,
           peers ~ TRUE,
           .default=FALSE),
         
         ##Do "anchor" symbols show up in matches > CSV Export?
         ##  https://github.com/nzilbb/labbcat-server/blob/9ee4cb3/user-interface/src/main/angular/projects/labbcat-common/src/lib/layer-checkboxes/layer-checkboxes.component.ts#L162-L169
         export_includeAnchorSharing = case_when(
           !matches_exportable ~ NA, ##Not shown in matches > CSV Export
           id=="word" ~ FALSE,
           scope=="span" ~ FALSE,
           alignment != "sub-interval" ~ FALSE,
           peers ~ TRUE,
           .default=FALSE),
         .before=extra)


# Identify files to create/update -----------------------------------------

##Get existing Markdown files
md <- 
  dir(md_dir, "\\.md$", full.names=TRUE) |>
  str_subset("README\\.md", negate=TRUE) |>
  set_names(~ str_remove(basename(.x), "\\.md$")) |>
  map(read_lines)

##Separate YAML header (lines between 1st & 2nd "---") & Markdown body
yaml_bounds <- map(md, ~ str_which(.x, "^---$"))
##YAML as list
yaml <- map2(md, yaml_bounds, 
             ~ .x[(.y[1]+1):(.y[2]-1)] |>
               yaml.load())
##Extract Markdown body
body_md <- map2(md, yaml_bounds,
                ~ .x[-c(1:.y[2])])

##Get "synced" attributes as a single dataframe
old_synced <-
  yaml |>
  map_dfr(~ .x |>
            pluck("synced") |>
            ##Make sure NULL attributes don't get removed
            map(~ replace(.x, is.null(.x), NA)),
          .id="id")

##If needed, add blank columns to old_synced to match layers
new_cols <- setdiff(colnames(layers), colnames(old_synced))
old_synced <- old_synced |>
  add_column(!!!set_names(rep(NA, length(new_cols)), new_cols))

##Identify layers that need new files & layers that need updated files
to_create <- anti_join(layers, old_synced, "id")
to_update <- 
  layers |>
  mutate(across(scope, ~ replace_na(.x, ""))) |>
  anti_join(old_synced, colnames(layers)[-1])

##Get last_sync_modified_date
last_sync_modified_date <- 
  Sys.time() |>
  format("%Y-%m-%dT%H:%M:%S%z")

# Create files for new layers ---------------------------------------------

##Add blank attributes (to be filled in manually for new layers)
blankAttr <- list(last_sync_modified_date = last_sync_modified_date,
                  notation = list(primary = "Main category of notation system (e.g., English, downcased English, Penn Treebank tags, DISC); links to `doc/notation-systems`",
                                  additional = "_If applicable_, symbols that augment the primary notation system (e.g., transcription prosody symbols, morpheme marker, DISC syllabification/stress, foll_segment pause symbol). Delete if not applicable",
                                  missing = "How missing values should be interpreted"),
                  inputs = list(list(input = "Name of input",
                                     type = "layer, dictionary, algorithm, script, transcription, or other"),
                                list(input = "Name of input",
                                     type = "layer, dictionary, algorithm, script, transcription, or other")),
                  versions = list(first_appeared = "Where layer first appeared",
                                  last_modified = "Where layer was last modified"),
                  last_modified_date = "Handled by Git pre-commit hook")

##List of to-be-created YAML headers
to_create <- to_create |>
  ##Nest synced attributes w/in "synced" element
  nest(data = -id) |>
  pull(data, id) |>
  map(~ c(synced = list(.x),
          ##Add blank attributes
          blankAttr) |>
        ##As a list of YAML headers
        as.yaml(indent.mapping.sequence=TRUE) |>
        ##Remove "Handled by Git pre-commit hook" text so pre-commit hook will
        ##  actually work
        str_remove("Handled by Git pre-commit hook"))

##List of Markdown files to be created
to_create <- to_create |>
  map(~ c("---", paste0(.x, "---"), "",
          "**Fill longer description here**", "",
          "Any headings should be level-3", "", "",
          "{% include linklist.html %}"))

##Optionally write new Markdown files
if (write_new_md_files) {
  to_create |>
    iwalk(~ write_lines(.x, paste0(.y, ".md"), sep="\r\n"))
}


# Update files for existing layers ----------------------------------------

##Make to_update structure match yaml
to_update <- to_update |> 
  nest(synced = -id) |>
  pull(synced, id) |>
  map(~ list(synced = .x))

##For layers in to_update, replace "synced" YAML sublists with to_update
new_yaml <- yaml |>
  list_modify(!!!to_update) |>
  map(~ assign_in(.x, "last_sync_modified_date", last_sync_modified_date)) |>
  keep_at(names(to_update)) |>
  map(as.yaml, indent.mapping.sequence=TRUE) |>
  ##Remove quotes added around last_modified_date
  map(~ str_replace(.x, "last_modified_date: '(.+?)'", "last_modified_date: \\1"))

##Add Markdown body
new_md <- map2(new_yaml, keep_at(body_md, names(new_yaml)),
               ~ c("---", str_remove(.x, "\n$"), "---", .y))

##Optionally write updated Markdown files
if (update_existing_md_files) {
  new_md |>
    iwalk(~ write_lines(.x, paste0(.y, ".md"), sep="\r\n"))
}

# Create JavaScript for layer title ------------------------------------------

##Construct new JavaScript
js_top <- c("var title;",
            "switch (hrefName) {")
js_bottom <- c("}",
               "a.title = title;")
js_middle <-
  layers |>
  rowwise() |>
  mutate(new = list(c(paste0("  case '", id, "':"),
                      paste0("    title = `", short_description, "`;"),
                      "    break;"))) |>
  pull(new) |>
  unlist()

##Read JS file to inject into and find location of block for injection
js_file <- read_lines(js_path)
js_bounds <- str_which(js_file, "//(BEGIN|END) generated by /_layers/sync-layers\\.R")
js_before <- js_file[1:js_bounds[1]]
js_after <- js_file[js_bounds[2]:length(js_file)]

##Inject into block
js_indent <- str_remove(js_file[js_bounds[1]], "//.+")
js_inject <- paste0(js_indent, c(js_top, js_middle, js_bottom))
new_js <- c(js_before,
            js_inject,
            js_after)

##Optionally write updated JavaScript file
if (update_existing_js_file) {
  write_lines(new_js, js_path)
}
