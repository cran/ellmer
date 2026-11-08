## -----------------------------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## -----------------------------------------------------------------------------
# pak::pak(c("otel", "otelsdk"))

## -----------------------------------------------------------------------------
# library(ellmer)
# 
# chat <- chat_anthropic()
# chat$chat("What's the capital of France?")

## -----------------------------------------------------------------------------
# chat <- chat_anthropic()
# chat$conversation_id <- "user-42-session-7"
# chat$chat("Hi!")
# chat$chat("What did I just say?")

## -----------------------------------------------------------------------------
# answer_question <- function(chat, question) {
#   otel::start_local_active_span("handle question")
#   chat$chat(question)
# }

## -----------------------------------------------------------------------------
# answer_question_async <- function(chat, question) {
#   promises::with_otel_promise_domain(
#     promises::with_otel_span(
#       "handle question",
#       chat$chat_async(question),
#       tracer = otel::get_tracer("my-app")
#     )
#   )
# }

