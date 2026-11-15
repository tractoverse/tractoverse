# The core packages

The tractoverse is a curated family of R packages for diffusion MRI
tractography, inspired by the tidyverse. The six core packages each have
their own website and GitHub repository; follow the links below to learn
more about each one.

| Package | Role | Website | Source |
|----|----|----|----|
| **fiber** | Data structures for tractography data (`streamline`, `bundle`, `bundle_set`) | <https://tractoverse.github.io/fiber/> | <https://github.com/tractoverse/fiber> |
| **master** | Simulation of streamlines / bundles / bundle sets with microstructural parameters | <https://tractoverse.github.io/master/> | <https://github.com/tractoverse/master> |
| **rtists** | Interactive 3D visualization | <https://tractoverse.github.io/rtists/> | <https://github.com/tractoverse/rtists> |
| **riot** | Data I/O (through `rvtk`) | <https://tractoverse.github.io/riot/> | <https://github.com/tractoverse/riot> |
| **toad** | Tractography Open Atlases Data (companion dataset package) | <https://tractoverse.github.io/toad/> | <https://github.com/tractoverse/toad> |
| **bot** | Bundle Optimal Transport; statistical methods for tractography data | <https://tractoverse.github.io/bot/> | <https://github.com/tractoverse/bot> |

## Installing the family

The simplest way to bring in any selection of the family is
[`install_core_packages()`](https://tractoverse.github.io/tractoverse/articles/reference/install_core_packages.md),
which prefers the CRAN release and falls back to the GitHub development
branch:

``` r

#| eval: false
# Default: install all six core packages
tractoverse::install_core_packages()

# …or just the ones you need, and force an upgrade
tractoverse::install_core_packages(c("fiber", "bot"), force = TRUE)
```

Once installed, [`library(tractoverse)`](https://tractoverse.github.io/)
attaches the whole family, and
[`tractoverse_packages()`](https://tractoverse.github.io/tractoverse/articles/reference/tractoverse_packages.md)
lists each package with its role.
