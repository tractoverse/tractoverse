#' The tractoverse package family
#'
#' The names and roles of the packages that make up the tractoverse, each with
#' its signature brand color.
#'
#' @return A named character vector of package roles, with each element named by
#'   the package name.
#' @export
tractoverse_packages <- function() {
  c(
    fiber  = "Data structures for tractography data",
    master = "Simulation of streamlines / bundles / bundle sets with microstructural parameters",
    rtists = "Visualization",
    riot   = "Data I/O (through rvtk)",
    toad   = "Tractography Open Atlases Data (companion dataset package)",
    bot    = "Bundle optimal transport; statistical methods for tractography data"
  )
}

#' The shared tractoverse brand
#'
#' Returns the shared brand as an R data structure, mirroring `_brand.yml`
#' shipped in `inst/brand/_brand.yml`. This is the single source of truth for
#' the tractoverse visual identity: the dark shell, the per-package signature
#' colors, and the shared typography.
#'
#' @return A list with named elements `palette`, `packages` and `shell`.
#' @export
tractoverse_brand <- function() {
  list(
    shell = c(
      black   = "#0d1117",
      surface = "#161b22",
      border  = "#30363d",
      silver  = "#e6edf3",
      grey    = "#8b949e"
    ),
    palette = c(
      fiber  = "#59aaea",
      master = "#ff9441",
      rtists = "#a980fc",
      riot   = "#3ec4b2",
      toad   = "#ffcf1b",
      bot    = "#3fb950"
    ),
    packages = tractoverse_packages()
  )
}

#' Path to the shared tractoverse theme stylesheet
#'
#' Returns the path to `tractoverse.scss`, the reusable dark theme for
#' tractoverse Quarto / pkgdown sites.
#'
#' @return An absolute file path.
#' @export
tractoverse_theme <- function() {
  system.file("brand", "tractoverse.scss", package = "tractoverse")
}
