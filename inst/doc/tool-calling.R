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
chat <- chat_openai(model = "gpt-4o")
chat$chat("How long ago did Neil Armstrong touch down on the moon?")

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
chat$chat("How long ago did Neil Armstrong touch down on the moon?")

## -----------------------------------------------------------------------------
chat

## -----------------------------------------------------------------------------
get_weather <- tool(
  function(cities) {
    raining <- c(London = "heavy", Houston = "none", Chicago = "overcast")
    temperature <- c(London = "cool", Houston = "hot", Chicago = "warm")
    wind <- c(London = "strong", Houston = "weak", Chicago = "strong")

    data.frame(
      city = cities,
      raining = unname(raining[cities]),
      temperature = unname(temperature[cities]),
      wind = unname(wind[cities])
    )
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
chat$chat("Give me a weather udpate for London and Chicago")

## -----------------------------------------------------------------------------
chat

