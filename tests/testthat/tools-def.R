# fmt: skip file

#' A function for foo-ing three numbers.
#'
#' @param x The first param
#' @param y The second param
#' @param z Take a guess
#' @returns The result of x %foo% y %foo% z.
has_roxygen_comments <- function(x, y, z = pi - 3.14) {
  super_secret_code()
}


  #' A function for foo-ing three numbers.
  #'
  #' @param x The first param
  #' @param y The second param
  #' @param z Take a guess
  #' @returns The result of x %foo% y %foo% z.
  indented_comments <- function(x, y, z = pi - 3.14) {
    super_secret_code()
  }

no_roxygen_comments <- function(i, j, k = pi - 3.14) {
  super_secret_code()
}

no_srcfile <- eval(quote(
  #' A function for foo-ing three numbers.
  function(a, b, c = pi - 3.14) {
    super_secret_code()
  }
))
