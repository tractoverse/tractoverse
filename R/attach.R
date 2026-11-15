# Attaching the core family on load, tidyverse-style.
#
# The family stays listed in `Imports:` (see R/tractoverse-package.R) so the
# packages are present and correct for R CMD check / CRAN; `.onAttach()` (in
# R/zzz.R) calls `tractoverse_attach()`, which puts any not-yet-attached core
# packages on the search path. This mirrors how the `tidyverse` meta-package
# attaches its core packages.

core <- function() {
  names(tractoverse_packages())
}

# Packages that are already loaded but not attached.
core_unloaded <- function() {
  loaded <- paste0("package:", core())
  core()[!loaded %in% search()]
}

# Attach a package from the same library its namespace was loaded from, so
# `library()` finds it even when R CMD check runs from a temporary install
# directory. Keeps the `library()` call here, outside `.onAttach()`.
same_library <- function(pkg) {
  loc <- if (pkg %in% loadedNamespaces()) dirname(getNamespaceInfo(pkg, "path"))
  library(pkg, lib.loc = loc, character.only = TRUE, warn.conflicts = FALSE)
}

tractoverse_attach <- function() {
  to_load <- core_unloaded()
  suppressPackageStartupMessages(lapply(to_load, same_library))
  invisible(to_load)
}
