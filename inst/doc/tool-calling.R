## -----------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = ellmer:::eval_vignette()
)
vcr::setup_knitr()

## ----setup--------------------------------------------------------------------
library(ellmer)

## -----------------------------------------------------------------------------
chat <- chat_openai(model = "gpt-5.4-mini")
chat$chat("What time is it right now in Chicago?")

## -----------------------------------------------------------------------------
#' Gets the current time in the given time zone.
#'
#' @param tz The time zone to get the current time in.
#' @return The current time in the given time zone.
get_current_time <- function(tz = "UTC") {
  format(Sys.time(), tz = tz, usetz = TRUE)
}

## -----------------------------------------------------------------------------
# Fake it for the vignette so we always get the same results
get_current_time <- function(tz = "UTC") {
  format(
    as.POSIXct("2025-06-25 11:53:23", tz = "America/Chicago"),
    tz = tz,
    usetz = TRUE
  )
}

## -----------------------------------------------------------------------------
get_current_time <- tool(
  get_current_time,
  name = "get_current_time",
  description = "Returns the current time.",
  arguments = list(
    tz = type_string(
      "Time zone to display the current time in. Defaults to `\"UTC\"`.",
      required = FALSE
    )
  )
)

## -----------------------------------------------------------------------------
get_current_time()

## -----------------------------------------------------------------------------
chat$register_tool(get_current_time)

## -----------------------------------------------------------------------------
chat$chat("What time is it right now in Chicago?")

## -----------------------------------------------------------------------------
chat

## -----------------------------------------------------------------------------
get_weather <- tool(
  function(cities) {
    raining <- c(London = "heavy", Houston = "none", Chicago = "overcast")
    temperature <- c(London = "cool", Houston = "hot", Chicago = "warm")
    wind <- c(London = "strong", Houston = "weak", Chicago = "strong")

    df <- data.frame(
      city = cities,
      raining = unname(raining[cities]),
      temperature = unname(temperature[cities]),
      wind = unname(wind[cities])
    )
    jsonlite::toJSON(df, auto_unbox = TRUE)
  },
  name = "get_weather",
  description = "
    Report on weather conditions in multiple cities. For efficiency, request
    all weather updates using a single tool call
  ",
  arguments = list(
    cities = type_array(type_string(), "City names")
  )
)

## -----------------------------------------------------------------------------
chat <- chat_openai()
chat$register_tool(get_weather)
chat$chat("Give me a weather update for London and Chicago")

## -----------------------------------------------------------------------------
chat

## -----------------------------------------------------------------------------
# screenshot_website <- tool(
#   function(url) {
#     tmpf <- withr::local_tempfile(fileext = ".png")
#     webshot2::webshot(url, file = tmpf)
#     content_image_file(tmpf)
#   },
#   name = "screenshot_website",
#   description = "Take a screenshot of a website.",
#   arguments = list(
#     url = type_string("The URL of the website")
#   )
# )

## -----------------------------------------------------------------------------
# chat <- chat_openai()
# #> Using model = "gpt-6.1-terra".
# chat$register_tool(screenshot_website)
# chat$chat("Describe the design aesthetic of https://tidyverse.org")
# #> https://tidyverse.org screenshot completed
# #> The design aesthetic of the Tidyverse website (https://tidyverse.org) is
# #> clean, modern, and minimalistic, with several distinct features:
# #>
# #> - **Color Palette**: The overall site uses a lot of white space with navy
# #>   and dark backgrounds for some elements, accentuated by the colorful
# #>   hexagonal logos for various R packages.
# #> - **Typography**: Simple, sans-serif fonts contribute to readability and
# #>   a contemporary look.
# #> - **Hexagonal Icons**: Prominent display of tidyverse package logos in
# #>   hexagonal shapes, emphasizing the modular, package-oriented
# #>   nature of the Tidyverse.
# #> - **Layout**: A balanced, spacious two-column layout. The left side
# #>   features graphic elements; the right side provides concise, text-based
# #>   information.
# #>
# #> Overall, the design communicates clarity, ease of use, and a focus on
# #> modern data science tools.

## -----------------------------------------------------------------------------
# report_tool <- tool(
#   function(query) {
#     ctx <- tool_context()
#     cli::cli_alert_info("Running report for request {ctx$request@id}")
#     run_report(query)
#   },
#   description = "Run a report for the given query.",
#   arguments = list(query = type_string("The report query."))
# )

## -----------------------------------------------------------------------------
# my_async_tool <- tool(
#   coro::async(function(query) {
#     ctx <- tool_context()          # capture before any await()
#     result <- await(run_report_async(query))
#     cli::cli_alert_info("Finished request {ctx$request@id}")
#     result
#   }),
#   description = "Run a report asynchronously.",
#   arguments = list(query = type_string("The report query."))
# )

## -----------------------------------------------------------------------------
# Assistant <- R6::R6Class(
#   "Assistant",
#   public = list(
#     initialize = function(user_email) {
#       private$user_email <- user_email
#     },
# 
#     # Return the ellmer tools, each wrapping a bound method. `tool()` can't
#     # infer a name from `self$method`, so we pass `name` explicitly.
#     tools = function() {
#       list(
#         tool(
#           self$add_note,
#           name = "add_note",
#           description = "Save a note for the current user.",
#           arguments = list(text = type_string("The note to save."))
#         ),
#         tool(
#           self$list_notes,
#           name = "list_notes",
#           description = "List the current user's saved notes."
#         )
#       )
#     },
# 
#     add_note = function(text) {
#       private$notes <- c(private$notes, text)
#       sprintf("Saved. You now have %d note(s).", length(private$notes))
#     },
# 
#     list_notes = function() {
#       if (length(private$notes) == 0) {
#         return("No notes yet.")
#       }
#       private$notes
#     }
#   ),
#   private = list(
#     user_email = NULL,
#     notes = character()
#   )
# )

## -----------------------------------------------------------------------------
# assistant <- Assistant$new(user_email = "hadley@posit.co")
# 
# chat <- chat_openai()
# chat$register_tools(assistant$tools())
# 
# chat$chat("Remember that I need to buy milk.")
# chat$chat("What do I need to do?")
# 
# # Inspect the state directly; this never passed through the model
# assistant$list_notes()
# #> [1] "buy milk"

