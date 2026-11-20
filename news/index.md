# Changelog

## tractoverse (development version)

- riot now requires v2.0.0 (renamed `read_bundle()`/`write_bundle()`, S7
  model moved to fiber).

## tractoverse 0.1.0

- Initial release of the tractoverse meta-package: installs and, with
  [`library(tractoverse)`](https://tractoverse.github.io/), attaches the
  six core packages (fiber, master, rtists, riot, toad, bot) in one
  call.

- [`install_core_packages()`](https://tractoverse.github.io/tractoverse/reference/install_core_packages.md)
  installs any selection of the family, preferring the CRAN release and
  falling back to the development version on GitHub when a package is
  not (yet) on CRAN.

- [`tractoverse_packages()`](https://tractoverse.github.io/tractoverse/reference/tractoverse_packages.md)
  lists the family with each package’s role.

- The shared tractoverse brand (colors, theme and logo family) ships in
  the package
  ([`tractoverse_brand()`](https://tractoverse.github.io/tractoverse/reference/tractoverse_brand.md),
  [`tractoverse_theme()`](https://tractoverse.github.io/tractoverse/reference/tractoverse_theme.md))
  as a single source of truth reused by the individual package websites
  and applications.
