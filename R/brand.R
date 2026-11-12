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
    fiber  = "S7 data structures (streamline, bundle, bundle_set)",
    master = "Simulation of bundles and microstructural attributes",
    rtists = "Interactive 3D visualization of tractography",
    riot   = "Input/output for tractography formats",
    mascot = "Curated reference datasets",
    bot    = "Bundle optimal transport"
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
      mascot = "#ffcf1b",
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
