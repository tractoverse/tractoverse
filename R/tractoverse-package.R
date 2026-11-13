#' tractoverse: The Tractoverse
#'
#' The tractoverse is a curated collection of R packages for the analysis of
#' diffusion MRI tractography data, inspired by the tidyverse. Installing this
#' meta-package installs and attaches the whole family:
#'
#' - [fiber]: data structures for tractography data
#' - [master]: simulation of streamlines / bundles / bundle sets with
#'   microstructural parameters
#' - [rtists]: visualization
#' - [riot]: data I/O (through rvtk)
#' - [toad]: Tractography Open Atlases Data (companion dataset package)
#' - [bot]: bundle optimal transport; statistical methods for tractography data
#'
#' The package also ships the shared tractoverse brand as the single source of
#' truth: colors, theme and logo family, reused by the individual package
#' websites and applications (see [tractoverse_brand()]).
#'
#' @keywords internal
"_PACKAGE"

# Attach the core family when the meta-package is loaded, tidyverse-style.
# The core packages stay listed in `Imports:` (so they are present and correct
# for `R CMD check` / CRAN), and this hook attaches them to the search path so
# `library(tractoverse)` brings the whole family into scope. Each attachment is
# guarded so an unavailable package cannot prevent loading the meta-package.
.onAttach <- function(libname, pkgname) {
  core <- names(tractoverse_packages())
  for (pkg in core) {
    tryCatch(
      suppressPackageStartupMessages(
        library(pkg, character.only = TRUE)
      ),
      error = function(e) NULL
    )
  }
  invisible()
}
