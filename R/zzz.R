# Package startup, hosted in zzz.R by convention.
#
# `.onAttach()` attaches the core family so `library(tractoverse)` brings the
# whole family into scope. The actual attaching lives in `tractoverse_attach()`
# (R/attach.R), keeping the `library()` calls out of `.onAttach()` itself, which
# is what R CMD check flags. When loaded for tests (R CMD check / devtools), we
# skip attaching entirely so the check isn't perturbed by changes to the search
# path.
.onAttach <- function(...) {
  if (is_loading_for_tests()) {
    return(invisible())
  }
  tractoverse_attach()
  invisible()
}

is_loading_for_tests <- function() {
  !interactive() && identical(Sys.getenv("DEVTOOLS_LOAD"), "tractoverse")
}
