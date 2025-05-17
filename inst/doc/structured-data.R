## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = ellmer:::openai_key_exists(),
  cache = TRUE
)

## ----setup--------------------------------------------------------------------
library(ellmer)

## -----------------------------------------------------------------------------
chat <- chat_openai()
chat$chat_structured(
  "My name is Susan and I'm 13 years old",
  type = type_object(
    name = type_string(),
    age = type_number()
  )
)

## -----------------------------------------------------------------------------
chat$chat_structured(
  content_image_url("https://www.r-project.org/Rlogo.png"),
  type = type_object(
    primary_shape = type_string(),
    primary_colour = type_string()
  )
)

## -----------------------------------------------------------------------------
prompts <- list(
  "I go by Alex. 42 years on this planet and counting.",
  "Pleased to meet you! I'm Jamal, age 27.",
  "They call me Li Wei. Nineteen years young.",
  "Fatima here. Just celebrated my 35th birthday last week.",
  "The name's Robert - 51 years old and proud of it.",
  "Kwame here - just hit the big 5-0 this year."
)
parallel_chat_structured(
  chat,  
  prompts,
  type = type_object(
    name = type_string(),
    age = type_number()
  )
)

## -----------------------------------------------------------------------------
type_logical_vector <- type_array(items = type_boolean())
type_integer_vector <- type_array(items = type_integer())
type_double_vector <- type_array(items = type_number())
type_character_vector <- type_array(items = type_string())

## -----------------------------------------------------------------------------
list_of_integers <- type_array(items = type_integer_vector)

## -----------------------------------------------------------------------------
type_person <- type_object(
  name = type_string(),
  age = type_integer(),
  hobbies = type_array(items = type_string())
)

## -----------------------------------------------------------------------------
type_type_person <- type_object(
  "A person",
  name = type_string("Name"),
  age = type_integer("Age, in years."),
  hobbies = type_array(
    "List of hobbies. Should be exclusive and brief.",
    items = type_string()
  )
)

## -----------------------------------------------------------------------------
text <- readLines(system.file("examples/third-party-testing.txt", package = "ellmer"))
# url <- "https://www.anthropic.com/news/third-party-testing"
# html <- rvest::read_html(url)
# text <- rvest::html_text2(rvest::html_element(html, "article"))

type_summary <- type_object(
  "Summary of the article.",
  author = type_string("Name of the article author"),
  topics = type_array(
    'Array of topics, e.g. ["tech", "politics"]. Should be as specific as possible, and can overlap.',
    type_string(),
  ),
  summary = type_string("Summary of the article. One or two paragraphs max"),
  coherence = type_integer("Coherence of the article's key points, 0-100 (inclusive)"),
  persuasion = type_number("Article's persuasion score, 0.0-1.0 (inclusive)")
)

chat <- chat_openai()
data <- chat$chat_structured(text, type = type_summary)
cat(data$summary)

str(data)

## -----------------------------------------------------------------------------
text <- "
  John works at Google in New York. He met with Sarah, the CEO of
  Acme Inc., last week in San Francisco.
"

type_named_entity <- type_object(
  name = type_string("The extracted entity name."),
  type = type_enum("The entity type", c("person", "location", "organization")),
  context = type_string("The context in which the entity appears in the text.")
)
type_named_entities <- type_array(items = type_named_entity)

chat <- chat_openai()
chat$chat_structured(text, type = type_named_entities)

## -----------------------------------------------------------------------------
text <- "
  The product was okay, but the customer service was terrible. I probably
  won't buy from them again.
"

type_sentiment <- type_object(
  "Extract the sentiment scores of a given text. Sentiment scores should sum to 1.",
  positive_score = type_number("Positive sentiment score, ranging from 0.0 to 1.0."),
  negative_score = type_number("Negative sentiment score, ranging from 0.0 to 1.0."),
  neutral_score = type_number("Neutral sentiment score, ranging from 0.0 to 1.0.")
)

chat <- chat_openai()
str(chat$chat_structured(text, type = type_sentiment))

## -----------------------------------------------------------------------------
text <- "The new quantum computing breakthrough could revolutionize the tech industry."

type_classification <- type_array(
  "Array of classification results. The scores should sum to 1.",
  type_object(
    name = type_enum(
      "The category name",
      values = c(
        "Politics",
        "Sports",
        "Technology",
        "Entertainment",
        "Business",
        "Other"
      )
    ),
    score = type_number(
      "The classification score for the category, ranging from 0.0 to 1.0."
    )
  )
)

chat <- chat_openai()
data <- chat$chat_structured(text, type = type_classification)
data

## ----eval = ellmer:::anthropic_key_exists()-----------------------------------
type_characteristics <- type_object(
  "All characteristics",
  .additional_properties = TRUE
)

prompt <- "
  Given a description of a character, your task is to extract all the characteristics of that character.

  <description>
  The man is tall, with a beard and a scar on his left cheek. He has a deep voice and wears a black leather jacket.
  </description>
"

chat <- chat_anthropic()
str(chat$chat_structured(prompt, type = type_characteristics))

## -----------------------------------------------------------------------------
type_asset <- type_object(
  assert_name = type_string(),
  owner = type_string(),
  location = type_string(),
  asset_value_low = type_integer(),
  asset_value_high = type_integer(),
  income_type = type_string(),
  income_low = type_integer(),
  income_high = type_integer(),
  tx_gt_1000 = type_boolean()
)
type_assets <- type_array(items = type_asset)

chat <- chat_openai()
image <- content_image_file("congressional-assets.png")
data <- chat$chat_structured(image, type = type_assets)
data

## -----------------------------------------------------------------------------
type_article <- type_object(
  "Information about an article written in markdown",
  title = type_string("Article title"),
  author = type_string("Name of the author"),
  date = type_string("Date written in YYYY-MM-DD format.")
)

prompt <- "
  Extract data from the following text:

  <text>
  # Structured Data
  By Hadley Wickham

  When using an LLM to extract data from text or images, you can ask the chatbot to nicely format it, in JSON or any other format that you like.
  </text>
"

chat <- chat_openai()
chat$chat_structured(prompt, type = type_article)
str(data)

## -----------------------------------------------------------------------------
type_article <- type_object(
  "Information about an article written in markdown",
  title = type_string("Article title", required = FALSE),
  author = type_string("Name of the author", required = FALSE),
  date = type_string("Date written in YYYY-MM-DD format.", required = FALSE)
)
chat$chat_structured(prompt, type = type_article)

## -----------------------------------------------------------------------------
type_my_df <- type_object(
  name = type_array(items = type_string()),
  age = type_array(items = type_integer()),
  height = type_array(items = type_number()),
  weight = type_array(items = type_number())
)

## -----------------------------------------------------------------------------
type_my_df <- type_array(
  items = type_object(
    name = type_string(),
    age = type_integer(),
    height = type_number(),
    weight = type_number()
  )
)

## -----------------------------------------------------------------------------
knitr::kable(token_usage())

