# compose-core.R - shared LOW-LEVEL compositing helpers used by compose-logo.R.
#
# The full compositor from the old scratch generation and the rejected
# hand-drawn polygon class-family emblem were removed (superseded by
# compose-logo.R + FontAwesome icons). What remains are the reusable raster
# helpers that compose_logo relies on: hexagon geometry/masking, anti-aliased
# border, area-average resampling, tract over-blending, chroma-keying, and name
# stamping.

hex_vertices <- function(R, cx, cy) {
  ang <- c(90, 30, -30, -90, -150, 150) * pi / 180
  cbind(cx + R * cos(ang), cy + R * sin(ang))
}
hex_mask <- function(W, H, R, cx, cy) {
  vert <- hex_vertices(R, cx, cy)
  xx <- rep(seq_len(W), each = H); yy <- rep(seq_len(H), times = W)
  n <- nrow(vert); inside <- rep(TRUE, length(xx))
  for (i in seq_len(n)) {
    j <- if (i == n) 1L else i + 1L
    x1 <- vert[i,1]; y1 <- vert[i,2]; x2 <- vert[j,1]; y2 <- vert[j,2]
    inside <- inside & (((xx-x1)*(y2-y1)-(yy-y1)*(x2-x1)) >= 0)
  }
  matrix(inside, H, W)
}
chroma_key_white <- function(im) (im[,,1] + im[,,2] + im[,,3]) / 3

# anti-aliased thick hexagon border as an H x W alpha raster (stroke along the 6 edges)
hex_border_alpha <- function(W, H, R, cx, cy, w) {
  vert <- hex_vertices(R, cx, cy)
  n <- nrow(vert)
  gx <- rep(seq_len(W), each = H); gy <- rep(seq_len(H), times = W)
  a <- rep(0, length(gx))
  dist <- function(px,py,qx,qy){
    dx<-qx-px; dy<-qy-py; L2<-dx*dx+dy*dy
    t<-((gx-px)*dx+(gy-py)*dy)/L2; t<-pmin(pmax(t,0),1)
    sqrt((gx-(px+t*dx))^2+(gy-(py+t*dy))^2)
  }
  d <- rep(Inf, length(gx))
  for (i in seq_len(n)) {
    j <- if (i==n) 1L else i+1L
    d <- pmin(d, dist(vert[i,1],vert[i,2],vert[j,1],vert[j,2]))
  }
  near <- d <= w
  a[near] <- pmax(a[near], 1 - d[near]/w)
  matrix(a, H, W)
}

# area-average downsample a 2D matrix src (H x W) into tw x th (smooth, no aliasing)
resample_area <- function(src, tw, th) {
  H <- nrow(src); W <- ncol(src)
  x0 <- (seq_len(tw) - 1) * W / tw + 1
  x1 <- seq_len(tw) * W / tw
  y0 <- (seq_len(th) - 1) * H / th + 1
  y1 <- seq_len(th) * H / th
  out <- matrix(0, th, tw)
  for (j in seq_len(tw)) {
    cs <- floor(x0[j]):ceiling(x1[j]); cs <- cs[cs >= 1 & cs <= W]
    for (i in seq_len(th)) {
      rs <- floor(y0[i]):ceiling(y1[i]); rs <- rs[rs >= 1 & rs <= H]
      out[i, j] <- mean(src[rs, cs, drop = FALSE])
    }
  }
  out
}

# overlay recoloured tract over base, over-blend with a cap to avoid smear
overlay_tile4 <- function(base, R, G, B, A, ox, oy, vigain = 1.0, amax = 0.6) {
  H <- dim(base)[1]; W <- dim(base)[2]
  th <- dim(A)[1]; tw <- dim(A)[2]
  x0 <- max(1, ox); x1 <- min(W, ox+tw-1)
  y0 <- max(1, oy); y1 <- min(H, oy+th-1)
  if (x1 < x0 || y1 < y0) return(base)
  bx <- x0:x1; by <- y0:y1
  tx <- bx-ox+1; ty <- by-oy+1
  a <- pmin(pmax(A[ty,tx],0),1)
  a <- pmin(amax, a * vigain)
  dim(a) <- c(length(by), length(bx))
  keep <- a > 0
  if (!any(keep)) return(base)
  for (ch in 1:3) {
    tint <- array(c(R,G,B)[ch], dim(a))
    base[by,bx,ch] <- base[by,bx,ch]*(1-a) + tint*a
  }
  base[by,bx,4] <- pmax(base[by,bx,4], a)
  base
}

# stamp name into the (now light) canvas; col should be a dark, readable colour
stamp_name5 <- function(base, name, col, yfrac = 0.5, cex = 1.0, outcolor=NA) {
  H <- dim(base)[1]; W <- dim(base)[2]
  tfile <- tempfile(fileext=".png")
  png(tfile, width=W, height=H, bg="black")
  par(mar=c(0,0,0,0)); plot.new()
  # render text white on black to recover alpha, then recolour via col over bg
  text(0.5, 1-yfrac, name, cex=cex, col="white", family="sans", font=2, adj=c(0.5,0.5))
  dev.off()
  tl <- readPNG(tfile); a <- (tl[,,1]+tl[,,2]+tl[,,3])/3
  a <- pmin(pmax(a,0),1)
  for (ch in 1:3) base[,,ch] <- base[,,ch]*(1-a) + col[ch]*a
  base[,,4] <- pmax(base[,,4], a)
  base
}

