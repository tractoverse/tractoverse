# =============================================================================
# logo-family.R -- shared tractoverse logo family generator
# =============================================================================
# Renders one hexagon logo per package (fiber, master, rtists, riot, mascot,
# bot), all on the shared brand shell (#0d1117) with a per-package signature
# color glyph + white wordmark. Output is written to OUT_DIR; copy each
# PNG into its package's `man/figures/logo.png` and the tractoverse
# `inst/brand/logos/` dir when satisfied.
#
# Provenance: colors from the tractoverse useR! 2026 talk custom.css and the
# tractoverse _brand.yml. Uses only ggplot2 + png (no rgl) so it is fully
# reproducible headless.
# =============================================================================

suppressMessages({
  library(ggplot2)
  library(png)
  library(grid)
})

# -----------------------------------------------------------------------------
# Brand tokens
# -----------------------------------------------------------------------------
BG      <- "#0d1117"          # shell / hexagon background
SURF    <- "#161b22"          # subtle inner panel
FG      <- "white"            # wordmark + glyph stroke
SIG     <- c(fiber  = "#59aaea",
             master = "#ff9441",
             rtists = "#a980fc",
             riot   = "#3ec4b2",
             mascot = "#ffcf1b",
             bot    = "#3fb950")

OUT     <- Sys.getenv("PA_SCRATCH_DIR", "/tmp/pa-501")
OUT_DIR <- if (nzchar(OUT) && dir.exists(OUT)) file.path(OUT, "logos") else "logos"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

# -----------------------------------------------------------------------------
# Shared hexagon geometry (flat-top, centered at origin, radius r)
# -----------------------------------------------------------------------------
hex_point <- function(r, i) {
  a <- pi / 6 + (i - 1) * pi / 3
  c(x = r * cos(a), y = r * sin(a))
}
hex_df <- function(r, n = 6) {
  i <- seq_len(n)
  theta <- pi / 6 + (i - 1) * pi / 3
  data.frame(x = r * cos(theta), y = r * sin(theta))
}
# clip path polygon (for hex-shaped glyph region at unit scale -> we apply in plot)
hexpath <- hex_df(1)
hexpath <- rbind(hexpath, hexpath[1, ])  # close the loop

# -----------------------------------------------------------------------------
# Shared plotting canvas
# -----------------------------------------------------------------------------
base_plot <- function(sig) {
  ggplot() +
    # hexagon shell
    geom_polygon(data = hex_df(1), aes(x, y),
                 fill = BG, color = "#30363d", linewidth = 0.9) +
    # inner subtle panel for glyph area
    geom_polygon(data = hex_df(0.83), aes(x, y),
                 fill = SURF, color = "NA") +
    coord_fixed(ratio = 1, xlim = c(-1.08, 1.08), ylim = c(-1.08, 1.15)) +
    theme_void() +
    theme(plot.margin = margin(0, 0, 0, 0),
          plot.background = element_rect(fill = "transparent", color = NA)) +
    scale_color_identity() + scale_fill_identity()
}

# wordmark across the bottom
wordmark <- function(label, size = 5.2) {
  annotate("text", x = 0, y = -0.92, label = label, size = size,
           color = FG, family = "sans", fontface = "bold",
           lineheight = 0.9)
}
# per-package small monospace role tag under the wordmark
roletag <- function(txt) {
  annotate("text", x = 0, y = -1.10, label = txt, size = 3.0,
           color = "#8b949e", family = "mono")
}

hex_theme <- theme_void() +
  theme(plot.margin = margin(0, 0, 0, 0),
        plot.background = element_rect(fill = "transparent", color = NA))

# -----------------------------------------------------------------------------
# Glyph builders (each returns a ggplot layer, using sig color)
# -----------------------------------------------------------------------------

# fiber: a single clean streamline sweeping across the glyph (data backbone)
glyph_fiber <- function(sig) {
  t <- seq(-0.62, 0.62, length.out = 200)
  df <- data.frame(
    x = t,
    y = 0.42 * sin(pi * (t + 0.62) / 1.24)   # gentle S-curve
  )
  df2 <- data.frame(x = -df$x, y = -df$y)      # mirrored second streamline
  list(
    geom_line(data = df,  aes(x, y), color = sig, linewidth = 1.6),
    geom_line(data = df2, aes(x, y), color = sig, linewidth = 1.6, alpha = 0.55),
    geom_point(data = data.frame(x = 0, y = 0), aes(x, y),
               color = "white", size = 1.4)
  )
}

# master: crossing hyperbola centerlines + perturbed axon fan (simulator)
glyph_master <- function(sig) {
  t <- seq(-0.72, 0.72, length.out = 300)
  # two crossing arms sweeping bottom-left -> top-right and opposite
  df <- rbind(
    data.frame(x = t,             y = 0.55 * t^2 - 0.42, grp = "a"),  # parabola down
    data.frame(x = t,             y = -0.55 * t^2 + 0.42, grp = "b")  # parabola up
  )
  layers <- list()
  layers <- c(layers, list(geom_line(data = df, aes(x, y, group = grp),
                                     color = sig, linewidth = 1.6)))
  # perturbed axon fan: short segment stubs radiating from centre
  set.seed(7)
  for (ang in seq(0, pi - 0.35, length.out = 6)) {
    r0 <- 0.12; r1 <- 0.42
    x0 <- r0 * cos(ang); y0 <- r0 * sin(ang)
    dx <- (r1 - r0) * cos(ang) + rnorm(1, 0, 0.04)
    dy <- (r1 - r0) * sin(ang) + rnorm(1, 0, 0.04)
    layers <- c(layers, list(geom_segment(
      data = data.frame(x = x0, y = y0, xend = x0 + dx, yend = y0 + dy),
      aes(x, y, xend = xend, yend = yend),
      color = sig, linewidth = 0.7, alpha = 0.6)))
  }
  layers
}

# rtists: a cluster of 3D-rendered tubes (central rod + elliptical cross-section)
glyph_rtists <- function(sig) {
  t <- seq(-0.45, 0.45, length.out = 120)
  # central vertical rod
  rod <- data.frame(x = t, y = 0)
  # two angled tubes passing behind / in front
  tb <- data.frame(x = -0.42 * sin(pi * (t + 0.45) / 0.9), y = t)
  tc <- data.frame(x =  0.09 + 0.42 * sin(pi * (t + 0.45) / 0.9), y = t * 0.9)
  ell <- function(cx, cy, r, col, alpha) {
    a <- seq(0, 2 * pi, length.out = 60)
    data.frame(x = cx + r * cos(a), y = cy + 0.32 * r * sin(a))
  }
  list(
    geom_path(data = tb, aes(x, y), color = sig, linewidth = 1.5, alpha = 0.75),
    geom_path(data = tc, aes(x, y), color = sig, linewidth = 1.5, alpha = 0.75),
    geom_path(data = rod, aes(x, y), color = sig, linewidth = 2.6),
    geom_polygon(data = ell(0.0, 0.0, 0.17, sig, 0.9), aes(x, y),
                 fill = sig, color = "white", linewidth = 0.7, alpha = 0.9)
  )
}

# riot: in/out arrows around a central streamline (I/O flows)
glyph_riot <- function(sig) {
  t <- seq(-0.42, 0.42, length.out = 120)
  core <- data.frame(x = 0.4 * t, y = t)
  core2 <- data.frame(x = 0.26, y = -t)  # vertical-ish secondary
  arrows <- data.frame(
    x  = c(-0.72, 0.72, 0.40, -0.30),
    y  = c( 0.10,-0.10, 0.60, -0.55),
    xe = c(-0.28, 0.28, 0.58, -0.08),
    ye = c( 0.32,-0.32, 0.42, -0.38)
  )
  list(
    geom_path(data = core, aes(x, y), color = sig, linewidth = 1.7),
    geom_path(data = core2, aes(x, y), color = sig, linewidth = 1.2, alpha = 0.6),
    geom_segment(data = arrows, aes(x, y, xend = xe, yend = ye),
                 color = sig, linewidth = 1.1,
                 arrow = arrow(length = unit(0.09, "inches"), type = "closed"))
  )
}

# mascot: an archive chest / drawer of datasets
glyph_mascot <- function(sig) {
  list(
    # chest body
    geom_rect(data = data.frame(xmin = -0.45, xmax = 0.45, ymin = -0.35, ymax = 0.35),
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
              fill = BG, color = sig, linewidth = 1.5),
    # lid band
    geom_rect(data = data.frame(xmin = -0.50, xmax = 0.50, ymin = 0.20, ymax = 0.34),
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
              fill = sig, color = NA),
    # handle
    geom_segment(data = data.frame(x = -0.18, y = 0.12, xe = 0.18, ye = 0.12),
                 aes(x, y, xend = xe, yend = ye), color = sig, linewidth = 1.2),
    # stacked data "plates" inside
    geom_segment(data = data.frame(x = -0.30, y = -0.18, xe = 0.30, ye = -0.18),
                 aes(x, y, xend = xe, yend = ye), color = sig, linewidth = 0.9, alpha = 0.7),
    geom_segment(data = data.frame(x = -0.30, y = -0.02, xe = 0.30, ye = -0.02),
                 aes(x, y, xend = xe, yend = ye), color = sig, linewidth = 0.9, alpha = 0.7)
  )
}

# bot: two point blobs with a transport/coupling arrow (optimal transport)
glyph_bot <- function(sig) {
  blobs <- function(cx, cy, r, fill) {
    a <- seq(0, 2 * pi, length.out = 80)
    data.frame(x = cx + r * cos(a), y = cy + r * sin(a))
  }
  list(
    geom_polygon(data = blobs(-0.40, 0, 0.20, sig), aes(x, y),
                 fill = sig, color = NA, alpha = 0.85),
    geom_polygon(data = blobs(0.40, 0, 0.20, sig), aes(x, y),
                 fill = sig, color = NA, alpha = 0.85),
    geom_segment(data = data.frame(x = -0.12, y = -0.05, xe = 0.12, ye = 0.05),
                 aes(x, y, xend = xe, yend = ye), color = "white",
                 linewidth = 1.3,
                 arrow = arrow(length = unit(0.12, "inches"), type = "closed"))
  )
}

# -----------------------------------------------------------------------------
# Package registry -> glyph + wordmark + role tag
# -----------------------------------------------------------------------------
PKGS <- list(
  fiber  = list(glyph = glyph_fiber,  word = "fiber",  tag = "data structures",
                file = "fiber.png"),
  master = list(glyph = glyph_master, word = "master", tag = "simulation",
                file = "master.png"),
  rtists = list(glyph = glyph_rtists, word = "rtists", tag = "3D visualization",
                file = "rtists.png"),
  riot   = list(glyph = glyph_riot,   word = "riot",   tag = "input / output",
                file = "riot.png"),
  mascot = list(glyph = glyph_mascot, word = "mascot", tag = "reference data",
                file = "mascot.png"),
  bot    = list(glyph = glyph_bot,    word = "bot",    tag = "optimal transport",
                file = "bot.png")
)

render_logo <- function(name, spec, width = 1200) {
  p <- base_plot(SIG[[name]]) +
    spec$glyph(SIG[[name]]) +
    wordmark(spec$word) +
    roletag(spec$tag)
  f <- file.path(OUT_DIR, spec$file)
  ggsave(f, p, width = width/300, height = width/300, dpi = 300, bg = "transparent")
  message(sprintf("wrote %-8s -> %s", name, f))
}

# -----------------------------------------------------------------------------
# Render everything
# -----------------------------------------------------------------------------
for (nm in names(PKGS)) render_logo(nm, PKGS[[nm]])

message("\nAll 6 logos rendered to: ", OUT_DIR)
