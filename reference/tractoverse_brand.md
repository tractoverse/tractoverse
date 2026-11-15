# The shared tractoverse brand

Returns the shared brand as an R data structure, mirroring
\`\_brand.yml\` shipped in \`inst/brand/\_brand.yml\`. This is the
single source of truth for the tractoverse visual identity: the dark
shell, the per-package signature colors, and the shared typography.

## Usage

``` r
tractoverse_brand()
```

## Value

A list with named elements \`palette\`, \`packages\` and \`shell\`.
