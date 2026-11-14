# tractoverse 0.1.0

* Initial release of the tractoverse meta-package: installs and, with
  `library(tractoverse)`, attaches the six core packages (fiber, master,
  rtists, riot, toad, bot) in one call.

* `install_core_packages()` installs any selection of the family, preferring
  the CRAN release and falling back to the development version on GitHub when
  a package is not (yet) on CRAN.

* `tractoverse_packages()` lists the family with each package's role.

* The shared tractoverse brand (colors, theme and logo family) ships in the
  package (`tractoverse_brand()`, `tractoverse_theme()`) as a single source of
  truth reused by the individual package websites and applications.
