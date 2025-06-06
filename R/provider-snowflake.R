#' @include provider-openai.R
#' @include content.R
NULL

#' Chat with a model hosted on Snowflake
#'
#' @description
#' The Snowflake provider allows you to interact with LLM models available
#' through the [Cortex LLM REST API](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-llm-rest-api).
#'
#' ## Authentication
#'
#' `chat_snowflake()` picks up the following ambient Snowflake credentials:
#'
#' - A static OAuth token defined via the `SNOWFLAKE_TOKEN` environment
#'   variable.
#' - Key-pair authentication credentials defined via the `SNOWFLAKE_USER` and
#'   `SNOWFLAKE_PRIVATE_KEY` (which can be a PEM-encoded private key or a path
#'   to one) environment variables.
#' - Posit Workbench-managed Snowflake credentials for the corresponding
#'   `account`.
#' - Viewer-based credentials on Posit Connect. Requires the \pkg{connectcreds}
#'   package.
#'
#' ## Known limitations
#' Note that Snowflake-hosted models do not support images or tool calling.
#'
#' See [chat_cortex_analyst()] to chat with the Snowflake Cortex Analyst rather
#' than a general-purpose model.
#'
#' @inheritParams chat_openai
#' @inheritParams chat_cortex_analyst
#' @param model `r param_model("claude-3-7-sonnet")`
#' @inherit chat_openai return
#' @examplesIf has_credentials("cortex")
#' chat <- chat_snowflake()
#' chat$chat("Tell me a joke in the form of a SQL query.")
#' @export
chat_snowflake <- function(
  system_prompt = NULL,
  account = snowflake_account(),
  credentials = NULL,
  model = NULL,
  params = NULL,
  api_args = list(),
  echo = c("none", "output", "all")
) {
  check_string(account, allow_empty = FALSE)
  model <- set_default(model, "claude-3-7-sonnet")
  params <- params %||% params()
  echo <- check_echo(echo)

  if (is_list(credentials)) {
    static_credentials <- force(credentials)
    credentials <- function(account) static_credentials
  }
  check_function(credentials, allow_null = TRUE)
  credentials <- credentials %||% default_snowflake_credentials(account)

  provider <- ProviderSnowflakeCortex(
    name = "Snowflake/Cortex",
    base_url = snowflake_url(account),
    account = account,
    credentials = credentials,
    model = model,
    params = params,
    extra_args = api_args,
    # We need an empty api_key for S7 validation.
    api_key = ""
  )

  Chat$new(provider = provider, system_prompt = system_prompt, echo = echo)
}

ProviderSnowflakeCortex <- new_class(
  "ProviderSnowflakeCortex",
  parent = ProviderOpenAI,
  properties = list(
    account = prop_string(),
    credentials = class_function
  )
)

method(base_request, ProviderSnowflakeCortex) <- function(provider) {
  req <- request(provider@base_url)
  req <- ellmer_req_credentials(req, provider@credentials)
  req <- req_retry(req, max_tries = 2)
  req <- ellmer_req_timeout(req, stream)
  # Snowflake uses the User Agent header to identify "parter applications", so
  # identify requests as coming from "r_ellmer" (unless an explicit partner
  # application is set via the ambient SF_PARTNER environment variable).
  req <- ellmer_req_user_agent(req, Sys.getenv("SF_PARTNER"))

  # Snowflake-specific error response handling:
  req <- req_error(req, body = function(resp) resp_body_json(resp)$message)

  req
}

method(chat_path, ProviderSnowflakeCortex) <- function(provider) {
  "/api/v2/cortex/inference:complete"
}

# See: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-llm-rest-api#api-reference
method(chat_body, ProviderSnowflakeCortex) <- function(
  provider,
  stream = TRUE,
  turns = list(),
  tools = list(),
  type = NULL
) {
  call <- quote(chat_snowflake())
  if (length(tools) != 0) {
    cli::cli_abort("Tool calling is not supported.", call = call)
  }

  messages <- as_json(provider, turns)

  if (!is.null(type)) {
    # Note: Snowflake uses a slightly different format than OpenAI.
    response_format <- list(type = "json", schema = as_json(provider, type))
  } else {
    response_format <- NULL
  }

  params <- chat_params(provider, provider@params)
  compact(list2(
    messages = messages,
    model = provider@model,
    !!!params,
    stream = stream,
    response_format = response_format
  ))
}

method(as_json, list(ProviderSnowflakeCortex, TypeObject)) <- function(
  provider,
  x
) {
  # Unlike OpenAI, Snowflake does not support the "additionalProperties" field.
  names <- names2(x@properties)
  required <- map_lgl(x@properties, function(prop) prop@required)
  properties <- as_json(provider, x@properties)
  names(properties) <- names
  list(
    type = "object",
    description = x@description %||% "",
    properties = properties,
    required = as.list(names[required])
  )
}

# See: https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-llm-rest-api#optional-json-arguments
method(chat_params, ProviderSnowflakeCortex) <- function(provider, params) {
  standardise_params(
    params,
    c(
      temperature = "temperature",
      top_p = "top_p",
      max_tokens = "max_tokens"
    )
  )
}

# Snowflake -> ellmer --------------------------------------------------------

method(stream_merge_chunks, ProviderSnowflakeCortex) <- function(
  provider,
  result,
  chunk
) {
  if (is.null(result)) {
    chunk
  } else {
    merge_snowflake_dicts(result, chunk)
  }
}

# Identical to merge_dicts(), but with special handling for Snowflake's
# non-indexed choices format.
merge_snowflake_dicts <- function(left, right) {
  for (right_k in names(right)) {
    right_v <- right[[right_k]]
    left_v <- left[[right_k]]

    if (is.null(right_v)) {
      if (!has_name(left, right_k)) {
        left[right_k] <- list(NULL)
      }
    } else if (is.null(left_v)) {
      left[[right_k]] <- right_v
    } else if (identical(left_v, right_v)) {
      next
    } else if (is.character(left_v)) {
      left[[right_k]] <- paste0(left_v, right_v)
    } else if (is.integer(left_v)) {
      left[[right_k]] <- right_v
    } else if (is.list(left_v)) {
      if (!is.null(names(right_v))) {
        left[[right_k]] <- merge_dicts(left_v, right_v)
      } else if (right_k == "choices") {
        left[[right_k]] <- merge_snowflake_choices(left_v, right_v)
      } else {
        left[[right_k]] <- merge_lists(left_v, right_v)
      }
    } else if (!identical(class(left_v), class(right_v))) {
      stop(paste0(
        "additional_kwargs['",
        right_k,
        "'] already exists in this message, but with a different type."
      ))
    } else {
      stop(paste0(
        "Additional kwargs key ",
        right_k,
        " already exists in left dict and value has unsupported type ",
        class(left[[right_k]]),
        "."
      ))
    }
  }

  left
}

merge_snowflake_choices <- function(left, right) {
  if (is.null(right)) {
    return(left)
  } else if (is.null(left)) {
    return(right)
  }

  for (e in right) {
    idx <- find_index(left, e)
    if (is.na(idx)) {
      idx <- 1L
    }
    # If a top-level "type" has been set for a chunk, it should no
    # longer be overridden by the "type" field in future chunks.
    if (!is.null(left[[idx]]$type) && !is.null(e$type)) {
      e$type <- NULL
    }
    left[[idx]] <- merge_dicts(left[[idx]], e)
  }
  left
}

# ellmer -> Snowflake --------------------------------------------------------

# Snowflake only supports simple textual messages.

method(as_json, list(ProviderSnowflakeCortex, Turn)) <- function(provider, x) {
  list(
    role = x@role,
    content = as_json(provider, x@contents[[1]])
  )
}

method(as_json, list(ProviderSnowflakeCortex, ContentText)) <- function(
  provider,
  x
) {
  x@text
}

# Utilities ------------------------------------------------------------------

snowflake_account <- function() {
  key_get("SNOWFLAKE_ACCOUNT")
}

snowflake_url <- function(account) {
  paste0("https://", account, ".snowflakecomputing.com")
}

default_snowflake_credentials <- function(account = snowflake_account()) {
  # Detect viewer-based credentials from Posit Connect.
  url <- snowflake_url(account)
  if (is_installed("connectcreds") && connectcreds::has_viewer_token(url)) {
    return(function() {
      token <- connectcreds::connect_viewer_token(url)
      list(
        Authorization = paste("Bearer", token$access_token),
        `X-Snowflake-Authorization-Token-Type` = "OAUTH"
      )
    })
  }

  token <- Sys.getenv("SNOWFLAKE_TOKEN")
  if (nchar(token) != 0) {
    return(function() {
      list(
        Authorization = paste("Bearer", token),
        # See: https://docs.snowflake.com/en/developer-guide/snowflake-rest-api/authentication#using-oauth
        `X-Snowflake-Authorization-Token-Type` = "OAUTH"
      )
    })
  }

  # Support for Snowflake key-pair authentication.
  # See: https://docs.snowflake.com/en/developer-guide/snowflake-rest-api/authentication#generate-a-jwt-token
  user <- Sys.getenv("SNOWFLAKE_USER")
  private_key <- Sys.getenv("SNOWFLAKE_PRIVATE_KEY")
  if (nchar(user) != 0 && nchar(private_key) != 0) {
    check_installed("jose", "for key-pair authentication")
    key <- openssl::read_key(private_key)
    return(function() {
      token <- snowflake_keypair_token(account, user, key)
      list(
        Authorization = paste("Bearer", token),
        `X-Snowflake-Authorization-Token-Type` = "KEYPAIR_JWT"
      )
    })
  }

  # Check for Workbench-managed credentials.
  sf_home <- Sys.getenv("SNOWFLAKE_HOME")
  if (grepl("posit-workbench", sf_home, fixed = TRUE)) {
    token <- workbench_snowflake_token(account, sf_home)
    if (!is.null(token)) {
      return(function() {
        # Ensure we get an up-to-date token.
        token <- workbench_snowflake_token(account, sf_home)
        list(
          Authorization = paste("Bearer", token),
          `X-Snowflake-Authorization-Token-Type` = "OAUTH"
        )
      })
    }
  }

  if (is_testing()) {
    testthat::skip("no Snowflake credentials available")
  }

  cli::cli_abort("No Snowflake credentials are available.")
}

snowflake_keypair_token <- function(
  account,
  user,
  key,
  cache = snowflake_keypair_cache(account, key),
  lifetime = 600L,
  reauth = FALSE
) {
  # Producing a signed JWT is a fairly expensive operation (in the order of
  # ~10ms), but adding a cache speeds this up approximately 500x.
  creds <- cache$get()
  if (reauth || is.null(creds) || creds$expiry < Sys.time()) {
    cache$clear()
    expiry <- Sys.time() + lifetime
    # We can't use openssl::fingerprint() here because it uses a different
    # algorithm.
    fp <- openssl::base64_encode(
      openssl::sha256(openssl::write_der(key$pubkey))
    )
    sub <- toupper(paste0(account, ".", user))
    iss <- paste0(sub, ".SHA256:", fp)
    # Note: Snowflake employs a malformed issuer claim, so we have to inject it
    # manually after jose's validation phase.
    claim <- jwt_claim("dummy", sub, exp = as.integer(expiry))
    claim$iss <- iss
    creds <- list(expiry = expiry, token = jwt_encode_sig(claim, key))
    cache$set(creds)
  }
  creds$token
}

snowflake_keypair_cache <- function(account, key) {
  credentials_cache(key = hash(c("sf", account, openssl::fingerprint(key))))
}
