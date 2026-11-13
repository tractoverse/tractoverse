#' Install the core tractoverse packages
#'
#' Convenience installer for the packages that make up the tractoverse family:
#' `fiber`, `master`, `rtists`, `riot`, `toad` and `bot`. These are also listed
#' in `Imports:`/`Remotes:` of the meta-package (so `install_github()`/`pak`
#' resolve them automatically); this function gives an explicit, user-run way to
#' bring in (or update) any selection of them.
#'
#' For each requested package the function prefers the released CRAN version
#' when the package is available on CRAN; otherwise it installs the current
#' `main` branch from the `tractoverse` GitHub organisation. Packages that are
#' already installed are left untouched unless `force = TRUE`.
#'
#' @param packages Character vector of package names. Defaults to all core
#'   packages (`names(tractoverse_packages())`).
#' @param force Logical. If `FALSE` (default) already-installed packages are
#'   skipped; if `TRUE` they are reinstalled (upgraded).
#' @param branch Branch/ref to install from GitHub for packages not on CRAN.
#'   Defaults to `"main"`.
#' @param repos CRAN repositories to use, passed to `install.packages()`. If
#'   `NULL` the user's configured `options("repos")` is used.
#' @param ... Additional arguments passed to `install.packages()` (CRAN path)
#'   or `remotes::install_github()` (GitHub path).
#'
#' @return Invisibly, a named character vector mapping each requested package to
#'   the outcome: `"already_installed"`, `"cran"` (installed from CRAN) or
#'   `"github"` (installed from the `tractoverse` GitHub organisation).
#' @importFrom stats setNames
#' @export
install_core_packages <- function(
    packages  = names(tractoverse_packages()),
    force     = FALSE,
    branch    = "main",
    repos     = getOption("repos"),
    ...) {

  pkgs <- unique(packages)
  ok <- pkgs %in% names(tractoverse_packages())
  if (!all(ok)) {
    stop("Unknown tractoverse package(s): ", paste(pkgs[!ok], collapse = ", "))
  }

  # Which of the requested packages are on CRAN?
  cran <- .on_cran(pkgs, repos)

  outcome <- setNames(character(length(pkgs)), pkgs)
  for (pkg in pkgs) {
    if (!force && requireNamespace(pkg, quietly = TRUE)) {
      outcome[[pkg]] <- "already_installed"
      message(sprintf("  * %s already installed -- skipped", pkg))
      next
    }
    if (pkg %in% cran) {
      utils::install.packages(pkg, repos = repos, ...)
      outcome[[pkg]] <- "cran"
    } else {
      msg <- sprintf("tractoverse/%s@%s not on CRAN; installing from GitHub main", pkg, branch)
      message("  ", msg)
      remotes::install_github(
        sprintf("tractoverse/%s", pkg),
        ref = branch,
        ...
      )
      outcome[[pkg]] <- "github"
    }
  }
  invisible(outcome)
}

# Determine which requested packages exist on the configured CRAN repositories.
.on_cran <- function(pkgs, repos) {
  # Resolve the @CRAN@ placeholder and empty config to a real mirror.
  if (is.null(repos) || length(repos) == 0L ||
      any(grepl("^@CRAN@$", repos))) {
    repos <- c(CRAN = "https://cloud.r-project.org")
  }
  ap <- tryCatch(
    utils::available.packages(repos = repos, type = getOption("pkgType")),
    error = function(e) NULL
  )
  if (is.null(ap)) {
    warning("Could not query CRAN availability; assuming all packages come from GitHub")
    return(character(0))
  }
  intersect(pkgs, rownames(ap))
}
