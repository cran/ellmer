% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/params.R
\name{params}
\alias{params}
\title{Standard model parameters}
\usage{
params(
  temperature = NULL,
  top_p = NULL,
  top_k = NULL,
  frequency_penalty = NULL,
  presence_penalty = NULL,
  seed = NULL,
  max_tokens = NULL,
  log_probs = NULL,
  stop_sequences = NULL,
  ...
)
}
\arguments{
\item{temperature}{Temperature of the sampling distribution.}

\item{top_p}{The cumulative probability for token selection.}

\item{top_k}{The number of highest probability vocabulary tokens to keep.}

\item{frequency_penalty}{Frequency penalty for generated tokens.}

\item{presence_penalty}{Presence penalty for generated tokens.}

\item{seed}{Seed for random number generator.}

\item{max_tokens}{Maximum number of tokens to generate.}

\item{log_probs}{Include the log probabilities in the output?}

\item{stop_sequences}{A character vector of tokens to stop generation on.}

\item{...}{Additional named parameters to send to the provider.}
}
\description{
This helper function makes it easier to create a list of parameters used
across many models. The parameter names are automatically standardised and
included in the correctly place in the API call.

Note that parameters that are not supported by a given provider will generate
a warning, not an error. This allows you to use the same set of parameters
across multiple providers.
}
