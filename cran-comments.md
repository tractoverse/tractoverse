## R CMD check results

0 errors | 0 warnings | 0 notes

* R CMD check was run locally on the `tractoverse_0.1.0.tar.gz` source tarball
  with `--no-manual` and returned clean.

## Reverse dependencies

Not applicable. tractoverse is a meta-package that installs and attaches its
six core packages (fiber, master, rtists, riot, toad, bot); it has no code of
its own beyond helpers such as `install_core_packages()` and the shared brand
objects, so there are no downstream reverse dependencies to check.

## Notes for CRAN maintainers

* tractoverse declares its six core packages in `Imports:` and attaches them on
  load (tidyverse convention). Nested packages are developed alongside this
  meta-package; `install_core_packages()` prefers the released CRAN version of
  each where available.

* This is a new submission.
