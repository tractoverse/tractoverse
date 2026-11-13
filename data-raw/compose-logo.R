# compose-logo.R - light-bg compositor for the full 6-package logo family.
#
#  * The tract is centered HORIZONTALLY by its CONTENT centre-of-mass (not by its
#    bounding box). The rendered two-tract scene has a mild left/right mass
#    imbalance (the anatomy halves differ), so bbox-centering leaves the glyph
#    visibly off the hex's vertical axis. Shifting so the tract's mass centroid
#    lands on the hex centre col W/2 fixes the perceived horizontal off-centering
#    deterministically for every package.
#  * Vertical placement fills the pointy-top hexagon symmetrically (apexes near
#    top/bottom).
#  * The emblem is a FontAwesome icon (per-package) chroma-keyed from rsvg into an
#    alpha mask and tinted with the package colour.
#  * Every per-package element (tract, name, icon) is parameterized by the package
#    palette colour.

# ----- tract glyph helpers -----
glyph_scale <- function(
  occ,
  R,
  cfg = list(pad = 0.02, fill = 0.93, log_a = 1.4)
) {
  # R = hex radius in pixels (pointy-top, R*2 tall). Compute how much the raw
  # render's content bbox must scale to fill the hex at cfg$fill fraction.
  cs <- which(colMeans(occ) > 0)
  rs <- which(rowMeans(occ) > 0)
  sw <- diff(range(cs)) + 1
  sh <- diff(range(rs)) + 1
  H <- round(2 * R)
  W <- round(sqrt(3) * R)
  fs <- min(H / sh, W / sw)
  fs
}

# Horizontal content-CM offset (render px) of a rendered glyph relative to bbox center.
content_cm_x <- function(occ) {
  cs <- which(colMeans(occ) > 0)
  colw <- colSums(occ)
  com <- sum(cs * colw[cs]) / sum(colw)
  bbox_cx <- (min(cs) + max(cs)) / 2
  com - bbox_cx
}

# ----- FontAwesome icon -> tinted RGBA tile (600x600 canvas) -----
# Horizontal anchor column for an icon's alpha mask (in bbox-cropped coords,
# 1..ncol). Each icon is aligned on the hexagon's vertical apex axis by this
# column, so we want its *visually central feature* (the blob the eye reads as
# "the icon"), not its mass centroid -- protruding appendages (handles, feet,
# quills) drag the mass off-axis. For icons with no clear single central feature
# (or that are already symmetric), we fall back to the glyph mass centroid.
icon_anchor_col <- function(icon, crop) {
  occ <- crop > 0.3
  Hh <- nrow(occ)
  Ww <- ncol(occ)
  mass_cm <- function() {
    cs <- which(colSums(occ) > 0)
    cw <- colSums(occ)
    sum(cs * cw[cs]) / sum(cw)
  }
  bbox_cen <- function() {
    cs <- which(colSums(occ) > 0)
    (min(cs) + max(cs)) / 2
  }
  # blender: align the base "hole" -- the gap between the two pedestal feet at
  # the bottom of the jar. Feature = horizontal centre of that gap.
  if (icon == "blender") {
    gaps <- numeric()
    for (r in (Hh - 130):(Hh - 35)) {
      xs <- which(occ[r, ])
      if (length(xs)) {
        runs <- split(xs, cumsum(c(TRUE, diff(xs) > 1)))
        if (length(runs) == 2) {
          gaps <- c(gaps, (max(runs[[1]]) + min(runs[[2]])) / 2)
        }
      }
    }
    if (length(gaps)) {
      return(mean(gaps))
    }
    return(mass_cm())
  }
  # magnifying-glass-chart: align the glass circle (lens) -- the large ring,
  # NOT the mass (which the off-left... handle drags to the right). Feature =
  # centre of the lens equator (widest row in the upper lens region).
  if (icon == "magnifying-glass-chart") {
    best <- 0
    bestr <- NA
    for (r in seq_len(round(0.55 * Hh))) {
      xs <- which(occ[r, ])
      if (length(xs)) {
        w <- max(xs) - min(xs) + 1
        if (w > best) {
          best <- w
          bestr <- r
        }
      }
    }
    if (!is.na(bestr)) {
      xs <- which(occ[bestr, ])
      return((min(xs) + max(xs)) / 2)
    }
    return(mass_cm())
  }
  # palette: align the palette dish (the rounded body). The protruding lower
  # handle drags the mass well off-axis; the dish itself is the visual feature.
  if (icon == "palette") {
    br <- seq_len(round(0.62 * Hh))
    bm <- occ[br, , drop = FALSE]
    cs <- which(colSums(bm) > 0)
    cw <- colSums(bm)
    if (length(cs)) {
      return(sum(cs * cw[cs]) / sum(cw))
    }
    return(mass_cm())
  }
  # All other icons: no single central feature -> mass centroid (their mass is
  # already close to symmetric / optically central: bezier-curve, feather-pointed,
  # book-atlas).
  mass_cm()
}

fa_tile <- function(icon, color, size = 600) {
  svg <- fa(icon)
  f <- tempfile(fileext = ".svg")
  cat(svg, file = f)
  p <- tempfile(fileext = ".png")
  rsvg::rsvg_png(f, p, width = size, height = size)
  im <- readPNG(p)
  a <- im[,, 4] # shape lives in alpha channel
  occ <- a > 0.5
  rs <- which(rowMeans(occ) > 0)
  cs <- which(colMeans(occ) > 0)
  xr <- range(cs)
  yr <- range(rs)
  crop <- a[yr[1]:yr[2], xr[1]:xr[2], drop = FALSE]
  # normalize each icon to a standard box (preserve aspect, fit into nxn)
  c2 <- col2rgb(color) / 255
  # horizontal anchor column of the glyph (absolute column within the cropped
  # mask) -- the icon's visual central feature, falling back to the glyph mass
  # centroid when there is no clear single feature. This is the column placed on
  # the hexagon's vertical axis.
  gcm <- icon_anchor_col(icon, crop)
  list(alpha = crop, color = c2, gcm = gcm)
}

# Place a (variable-size) tile centered at a point, wrapping to [0,1] alpha.
ic_place <- function(
  base,
  alpha,
  color,
  cx,
  cy,
  target_h,
  target_w = NA,
  amax = 0.95,
  gcm = NA # glyph horizontal mass-centroid in alpha-mask columns (from bbox left)
) {
  # alpha = H x W shape mask; resize to target_h (preserving aspect)
  ah <- nrow(alpha)
  aw <- ncol(alpha)
  if (is.na(target_w)) {
    target_w <- round(target_h * aw / ah)
  }
  a2 <- resample_area(alpha, target_w, target_h)
  a2 <- pmin(pmax(a2, 0), 1) * amax
  H <- nrow(base)
  W <- dim(base)[2]
  # centre on the glyph mass-centroid so lopsided icons sit on the axis.
  # gcm is the centroid column (1..aw) of the source mask; its scaled position
  # within target_w is (gcm-1)/(aw-1)*target_w. Shift the tile left edge so that
  # the centroid lands on cx.
  if (!is.na(gcm)) {
    frac <- (gcm - 1) / (aw - 1)
    x0 <- round(cx - frac * target_w)
  } else {
    x0 <- round(cx - target_w / 2)
  }
  y0 <- round(cy - target_h / 2)
  if (x0 < 1 || y0 < 1 || x0 + target_w - 1 > W || y0 + target_h - 1 > H) {
    stop("icon tile out of bounds -- reduce icon size")
  }
  for (ch in 1:3) {
    base[y0:(y0 + target_h - 1), x0:(x0 + target_w - 1), ch] <-
      base[y0:(y0 + target_h - 1), x0:(x0 + target_w - 1), ch] *
      (1 - a2) +
      color[ch] * a2
  }
  base
}

# ----- compositor -----
compose_logo <- function(
  render_path,
  pal,
  name,
  R = 300,
  bg_color = "#eaf4fc", # chosen light-blue background
  border_color = "#111111",
  border_w = 14,
  vigain = 1.8,
  amax = 0.55,
  name_darken = 0.92,
  name_yfrac = 0.33,
  name_cex = 6.0, # lowered (was 7.5) so the longest name (master) fits w/o cone overlap
  vy_frac = 0.5, # vertical anchor: 0.5 = center the tract bbox
  icon = NULL, # FontAwesome icon name, or NULL for none
  icon_h = 132, # icon height in px (preserves aspect); smaller (was 180)
  icon_cx = NA,
  icon_cy = NA, # icon anchor; default = hex center (250 in R=300?)
  icon_y_frac = 0.56, # raised (was 0.60) to sit higher, clear of the package name
  icon_alpha = 0.95,
  out_path
) {
  suppressMessages({
    library(png)
    library(fontawesome)
    library(rsvg)
  })
  im <- readPNG(render_path)
  al <- chroma_key_white(im)
  occ <- al > 0.12
  xr <- range(which(colMeans(occ) > 0))
  yr <- range(which(rowMeans(occ) > 0))
  sw <- diff(xr) + 1
  sh <- diff(yr) + 1
  W <- round(sqrt(3) * R)
  H <- round(2 * R)
  tractc <- col2rgb(pal) / 255
  bgc <- col2rgb(bg_color) / 255
  namec <- tractc * name_darken
  base <- array(0, c(H, W, 4))
  base[,, 1] <- bgc[1]
  base[,, 2] <- bgc[2]
  base[,, 3] <- bgc[3]
  base[,, 4] <- 1
  # scale render bbox to fill hex
  sc <- min(H / sh, W / sw)
  th <- round(sh * sc)
  tw <- round(sw * sc)
  crop <- al[yr[1]:(yr[1] + sh - 1), xr[1]:(xr[1] + sw - 1), drop = FALSE]
  tA <- resample_area(crop, tw, th)
  # OLD: bbox-central horizontal placement
  # ox <- round((W - tw)/2)
  # NEW: content-CM horizontal placement -- shift so the render's mass centroid
  # lands on the hex centre. content_cm_x() is in render px; after scaling by sc
  # (crop->final) this is the shift in final px.
  dcm <- content_cm_x(occ) * sc # render-px CM offset -> final px
  # vertical: for a full-hex cone the bbox already spans the cone, so anchor via
  # vy_frac here.
  oy <- round(vy_frac * H - th / 2)
  # horizontal: center content CM at W/2  => place bbox so CM at W/2.
  # CM_final = ox + (CM_render_final - bbox_center_final) = ox + dcm
  # want CM_final = W/2  =>  ox = W/2 - dcm - tw/2
  ox <- round(W / 2 - dcm - tw / 2)
  base <- overlay_tile4(
    base,
    tractc[1],
    tractc[2],
    tractc[3],
    tA,
    ox,
    oy,
    vigain,
    amax
  )
  # hex mask
  mask <- hex_mask(W, H, R, W / 2, H / 2)
  for (ch in 1:3) {
    base[,, ch] <- base[,, ch] * mask
  }
  base[,, 4] <- base[,, 4] * mask
  # border
  bc2 <- col2rgb(border_color) / 255
  ba <- hex_border_alpha(W, H, R, W / 2, H / 2, border_w)
  bm <- ba > 0
  for (ch in 1:3) {
    base[,, ch][bm] <- base[,, ch][bm] * (1 - ba[bm]) + bc2[ch] * ba[bm]
  }
  base[,, 4][bm] <- pmax(base[,, 4][bm], ba[bm])
  # emblem: FA icon tinted with package colour
  if (!is.null(icon)) {
    tile <- fa_tile(icon, pal)
    icx <- if (is.na(icon_cx)) W / 2 else icon_cx
    icy <- if (is.na(icon_cy)) icon_y_frac * H else icon_cy
    base <- ic_place(
      base,
      tile$alpha,
      tile$color,
      icx,
      icy,
      icon_h,
      amax = icon_alpha,
      gcm = tile$gcm
    )
  }
  # name
  base <- stamp_name5(base, name, namec, yfrac = name_yfrac, cex = name_cex)
  writePNG(base, out_path)
  invisible(list(
    base = base,
    W = W,
    H = H,
    th = th,
    tw = tw,
    ox = ox,
    oy = oy,
    dcm = dcm
  ))
}
