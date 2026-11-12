# compose_logo5.R - light-background high-quality compositor for the fiber logo.
# Changes vs compose_logo4:
#  * light/white background (bg_color) with a black hexagon OUTLINE border
#  * horizontal class-family emblem (grandmother left, mother centre, child right)
#    wired in below the package name, mapped to the left/right tract halves.
#  * name + tract colours re-tuned for a light background.

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

# ===== horizontal class-family emblem (bundle_set -> bundle -> streamline) =====
emblem_env <- new.env()
box_r <- function(e, x0,y0,x1,y1) {
  xa<-max(1,floor(x0)); xb<-min(ncol(e$a),ceiling(x1))
  ya<-max(1,floor(y0)); yb<-min(nrow(e$a),ceiling(y1))
  if (xb<xa||yb<ya) return(invisible())
  e$a[ya:yb, xa:xb] <- 1
  invisible()
}
seg_r <- function(e, x0,y0,x1,y1,w) {
  xa<-max(1,floor(min(x0,x1)-w)); xb<-min(ncol(e$a),ceiling(max(x0,x1)+w))
  ya<-max(1,floor(min(y0,y1)-w)); yb<-min(nrow(e$a),ceiling(max(y0,y1)+w))
  if (xb<xa||yb<ya) return(invisible())
  gx<-rep(xa:xb,each=length(ya:yb)); gy<-rep(ya:yb,times=length(xa:xb))
  dx<-x1-x0; dy<-y1-y0; L2<-dx*dx+dy*dy
  if (L2<1e-9) d<-sqrt((gx-x0)^2+(gy-y0)^2) else {
    t<-((gx-x0)*dx+(gy-y0)*dy)/L2; t<-pmin(pmax(t,0),1)
    d<-sqrt((gx-x0-t*dx)^2+(gy-y0-t*dy)^2)}
  near<-d<=w; e$a[cbind(gy[near],gx[near])]<-pmax(e$a[cbind(gy[near],gx[near])],1-d[near]/w)
  invisible()
}
tri_r <- function(e,P,Q,R,val=1) {
  xa<-max(1,floor(min(P[1],Q[1],R[1])-1)); xb<-min(ncol(e$a),ceiling(max(P[1],Q[1],R[1])+1))
  ya<-max(1,floor(min(P[2],Q[2],R[2])-1)); yb<-min(nrow(e$a),ceiling(max(P[2],Q[2],R[2])+1))
  if (xb<xa||yb<ya) return(invisible())
  gx<-rep(xa:xb,each=length(ya:yb)); gy<-rep(ya:yb,times=length(xa:xb))
  v0x<-R[1]-P[1];v0y<-R[2]-P[2];v1x<-Q[1]-P[1];v1y<-Q[2]-P[2]
  v2x<-gx-P[1];v2y<-gy-P[2]
  dot00<-v0x*v0x+v0y*v0y;dot01<-v0x*v1x+v0y*v1y
  dot02<-v0x*v2x+v0y*v2y;dot11<-v1x*v1x+v1y*v1y;dot12<-v1x*v2x+v1y*v2y
  inv<-1/(dot00*dot11-dot01*dot01)
  u<-(dot11*dot02-dot01*dot12)*inv; vv<-(dot00*dot12-dot01*dot02)*inv
  ins<-(u>=0)&(vv>=0)&(u+vv<=1)
  e$a[cbind(gy[ins],gx[ins])]<-val
  invisible()
}
class_emblem_h <- function(W, H, xf=0.5, yf=0.72, s=0.34,
                           size_frac=c(g=1.0, m=0.84, c=0.66),
                           hw_frac=0.34, linew=0.028, aw_frac=0.42, ah_frac=0.24) {
  cx<-xf*W; cy<-yf*H
  span<-s*W
  left<-cx-span/2; right<-cx+span/2
  wsum<-sum(size_frac); nbox<-3; ngap<-2
  gap_w  <- span * 0.16
  box_w_units<-span - ngap*gap_w
  bw <- size_frac/wsum * box_w_units
  h  <- span*hw_frac; h <- c(h*1.0, h*0.88, h*0.76)
  x <- numeric(3)
  x[1]<-left
  x[2]<-x[1]+bw[1]+gap_w
  x[3]<-x[2]+bw[2]+gap_w
  e<-new.env(); e$a<-array(0,c(H,W))
  y0<-cy - h/2; y1<-cy + h/2
  for (i in 1:3) box_r(e, x[i], y0[i], x[i]+bw[i], y1[i])
  lw<-linew*span * 0
  aw<-span*aw_frac; ah<-span*ah_frac
  arrow_right<-function(gap_cx){
    apex<-c(gap_cx+aw*0.5, cy)
    b0<-c(gap_cx-aw*0.5, cy-ah/2); b1<-c(gap_cx-aw*0.5, cy+ah/2)
    tri_r(e,b0,b1,apex,1)
    sc<-0.55
    in0<-apex+(b0-apex)*sc; in1<-apex+(b1-apex)*sc
    inA<-apex+(c(apex[1]-aw*0.5, cy)-apex)*sc*0.95
    tri_r(e,in0,in1,apex,0)
    tri_r(e,in0,in1,inA,0)
  }
  arrow_right(x[1]+bw[1]+gap_w/2)
  arrow_right(x[2]+bw[2]+gap_w/2)
  e$a
}

compose_logo5 <- function(
  render_path, pal, name, R = 300,
  bg_color = "#ffffff", border_color = "#111111", border_w = 14,
  vigain = 1.8, name_darken = 0.92, name_yfrac = 0.33, name_cex = 7.5,
  amax = 0.55, show_emblem = FALSE, emblem_color = NULL, emblem_alpha = 0.95,
  emblem_xf = 0.5, emblem_yf = 0.74, emblem_size = 0.34,
  out_path
) {
  suppressMessages(library(png))
  im <- readPNG(render_path)
  al <- chroma_key_white(im)
  occ <- al > 0.12
  rowocc <- rowMeans(occ); colocc <- colMeans(occ)
  xr <- range(which(colocc>0)); yr <- range(which(rowocc>0))
  if (any(is.infinite(xr)) || any(is.infinite(yr))) stop("empty render")
  sw <- diff(xr)+1; sh <- diff(yr)+1
  W <- round(sqrt(3)*R); H <- round(2*R)
  tractc <- col2rgb(pal)/255; bgc <- col2rgb(bg_color)/255
  namec <- tractc * name_darken
  calpha <- array(0, c(H,W,4))
  calpha[,,1] <- bgc[1]; calpha[,,2] <- bgc[2]; calpha[,,3] <- bgc[3]
  calpha[,,4] <- 1
  sc <- min(H/sh, W/sw); th <- round(sh*sc); tw <- round(sw*sc)
  crop <- al[yr[1]:(yr[1]+sh-1), xr[1]:(xr[1]+sw-1), drop=FALSE]
  tA <- resample_area(crop, tw, th)
  ox <- round((W-tw)/2); oy <- round(H-th)
  base <- overlay_tile4(calpha, tractc[1], tractc[2], tractc[3], tA, ox, oy, vigain, amax)
  mask <- hex_mask(W,H,R,W/2,H/2)
  for (ch in 1:3) base[,,ch] <- base[,,ch]*mask
  base[,,4] <- base[,,4]*mask
  # black hexagon border (outside mask is transparent, but stroke sits ON the edge)
  if (border_w > 0) {
    bc <- col2rgb(border_color)/255
    ba <- hex_border_alpha(W,H,R,W/2,H/2, border_w)
    bm <- ba > 0
    for (ch in 1:3) base[,,ch][bm] <- base[,,ch][bm]*(1-ba[bm]) + bc[ch]*ba[bm]
    base[,,4][bm] <- pmax(base[,,4][bm], ba[bm])
  }
  if (show_emblem) {
    ec <- if (is.null(emblem_color)) namec else col2rgb(emblem_color)/255
    ea <- class_emblem_h(W, H, xf=emblem_xf, yf=emblem_yf, s=emblem_size) * emblem_alpha
    emask <- ea > 0
    for (ch in 1:3) base[,,ch][emask] <- base[,,ch][emask]*(1-ea[emask]) + ec[ch]*ea[emask]
    base[,,4][emask] <- pmax(base[,,4][emask], ea[emask])
  }
  base <- stamp_name5(base, name, namec, yfrac=name_yfrac, cex=name_cex)
  writePNG(base, out_path)
  cat("wrote", out_path, "(", W, "x", H, ") for", name, " vigain", vigain,
      " darken", name_darken, " border", border_w, "\n")
  invisible(list(W=W,H=H))
}
