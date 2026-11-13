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

# Suppress R CMD check note
# Namespace in Imports field not imported from: PKG
#   All declared Imports should be used.
#
# The core packages are kept in `Imports:` (not `Depends:`) so they are
# guaranteed present and correct for `R CMD check` / CRAN, and are attached on
# load by `.onAttach()` (see R/zzz.R and R/attach.R). Because they are never
# called with `::` in the normal code path, R CMD check would otherwise report
# them as unused imports; referencing one symbol from each (as tidyverse does)
# satisfies the check.
ignore_unused_imports <- function() {
  fiber::streamline
  master::create_axons
  rtists::plot3d
  riot::read_bundle
  toad::HCP1065_TR_P_R
  bot::optimal_transport
}
