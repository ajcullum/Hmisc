## $Id$
		
if(!exists("NROW", mode='function')) {
  NROW <- function(x)
    if (is.array(x) || is.data.frame(x)) nrow(x) else length(x)
}

if(!exists("NCOL", mode='function')) {
  NCOL <- function(x)
    if (is.array(x) && length(dim(x)) > 1 || is.data.frame(x)) ncol(x) else as.integer(1)
}

prn <- function(x, txt)
{
  calltext <- as.character(sys.call())[2]

  if(!missing(txt)) {
    if(nchar(txt) + nchar(calltext) +3 > .Options$width)
      calltext <- paste('\n\n  ',calltext,sep='')
    else
      txt <- paste(txt, '   ', sep='')
    cat('\n', txt, calltext, '\n\n', sep='') 
  }
  else cat('\n',calltext,'\n\n',sep='')
  invisible(print(x))
}

format.sep <- function(x, digits, ...)
{
  y <- character(length(x))
  for(i in 1:length(x))
    y[i] <- if(missing(digits)) format(x[i], ...)
            else format(x[i],digits=digits, ...)  ## 17Apr02

  names(y) <- names(x)  ## 17Apr02
  y
}

nomiss <- function(x)
{
  if(is.data.frame(x)) na.exclude(x)
  else if(is.matrix(x))
    x[!is.na(x %*% rep(1,ncol(x))),]
  else x[!is.na(x)]
}

fillin <- function(v, p)
{
  v.f <- ifelse(is.na(v),p,v)
  if(length(p)==1)
    label(v.f) <- paste(label(v),"with",sum(is.na(v)),
                        "NAs replaced with",format(p))
  else
    label(v.f) <- paste(label(v),"with",sum(is.na(v)),"NAs replaced")
  v.f
}

spearman <- function(x, y)
{
  x <- as.numeric(x)
  y <- as.numeric(y)  ## 17Jul97
  
  notna <- !is.na(x+y)	##exclude NAs
  if(sum(notna) < 3)
    c(rho=NA)
  else
    c(rho=cor(rank(x[notna]), rank(y[notna])))
}

plotCorrPrecision <- function(rho=c(0,0.5), n=seq(10,400,length=100),
                              conf.int=0.95, offset=.025, ...)
{
  ## Thanks to Xin Wang for computations
  curves <- vector('list', length(rho))
  names(curves) <- paste('r',format(rho),sep='=')
  zcrit <- qnorm(1-(1-conf.int)/2)
  for(i in 1:length(rho)) {
    r <- rho[i]
    z <- .5*log((1+r)/(1-r))
    lo <- z - zcrit/sqrt(n-3)
    hi <- z + zcrit/sqrt(n-3)
    rlo <- (exp(2*lo)-1)/(exp(2*lo)+1)
    rhi <- (exp(2*hi)-1)/(exp(2*hi)+1)
    precision <- pmax(rhi-r, r-rlo)
    curves[[i]] <- list(N=n, Precision=precision)
  }
  labcurve(curves, pl=TRUE, xrestrict=quantile(n,c(.25,1)), offset=offset, ...)
  invisible()
}

trap.rule <- function(x,y) sum(diff(x)*(y[-1]+y[-length(y)]))/2

uncbind <- function(x, prefix="", suffix="")
{
  nn <- dimnames(x)[[2]]
  warning("You are using uncbind.  That was a really bad idea. If you had any variables in the global environment named ", paste(prefix, nn, suffix, sep="", collapse=", "), " they are now over writen.\n\nYou are now warned.", immediate. = TRUE, )
  for(i in 1:ncol(x))
    assign(paste(prefix,nn[i],suffix,sep=""), x[,i], pos=parent.env())
  invisible()
}

## Function to pick off ordinates of a step-function at user-chosen abscissas

stepfun.eval <- function(x, y, xout, type=c("left","right"))
{
  s <- !is.na(x+y)
  type <- match.arg(type)
  approx(x[s], y[s], xout=xout, method="constant", f=if(type=="left")0 else 1)$y
}


km.quick <- function(S, times, q)
{
  S <- S[!is.na(S),]
  n <- nrow(S)
  stratvar <- factor(rep(1,nrow(S)))
  f <- survfit:::survfitKM(stratvar, S, se.fit=FALSE, conf.type='none')
  tt <- c(0, f$time)
  ss <- c(1, f$surv)
  if(missing(times))
    min(tt[ss <= q])
  else
    approx(tt, ss, xout=times, method='constant', f=0)$y
}

oPar <- function()
{
  ## Saves existing state of par() and makes changes suitable
  ## for restoring at the end of a high-level graphics functions
  oldpar <- par()
  oldpar$fin <- NULL
  oldpar$new <- FALSE
  invisible(oldpar)
}

setParNro <- function(pars)
{
  ## Sets non-read-only par parameters from the input list
  i <- names(pars) %nin%
    c('cin','cra','csi','cxy','din','xlog','ylog','gamma')
  invisible(par(pars[i]))
}

mgp.axis.labels <- function(value,type=c('xy','x','y','x and y'))
{
  type <- match.arg(type)
  if(missing(value)) {
    value <- .Options$mgp.axis.labels
    pr <- par(c('mgp','las'))
    mgp <- pr$mgp
    if(!length(value))
      value <- c(.7, .7)
    ##value <- c(mgp[2], if(pr$las==1) max(mgp[2],1.3) else mgp[2])
    return(switch(type, 
                  xy = value, 
                  x = c(mgp[1], value[1], mgp[3]),
                  y = c(mgp[1], value[2], mgp[3]),
                  'x and y' = list(x = c(mgp[1], value[1], mgp[3]),
                                   y = c(mgp[1], value[2], mgp[3]))))
  }
  
  if(value[1]=='default')
    value <- c(.7,.7)
  
  ##c(.6, if(par('las')==1) 1.3 else .6)
  options(mgp.axis.labels=value, TEMPORARY=FALSE)
  invisible()
}

mgp.axis <-
  function(side, at=NULL, ...,
           mgp=mgp.axis.labels(type=if(side==1 | side==3)'x' else 'y'),
           axistitle=NULL)
{
  ## Version of axis() that uses appropriate mgp from mgp.axis.labels and
  ## gets around bug in axis(2, ...) that causes it to assume las=1
  mfrow <- par('mfrow')
  nr <- mfrow[1]; nc <- mfrow[2]
  w <- list(side=side)
  w <- c(w, list(...))
  if(length(at))
    w$at <- at
  if(side==1 || side==3) {
    w$mgp <- mgp/nr
    w$tcl <- -0.4/nr
    if(side==1 && length(axistitle))
      title(xlab=axistitle, mgp = mgp / min(2.25, nr))
  } else {
    w$mgp <- mgp/nc
    w$tcl <- -0.4/nc
    las <- par('las')
    w$srt <- 90*(las==0)
    w$adj <- if(las==0)0.5
    else 1
    if(side==2 && length(axistitle))
      title(ylab=axistitle, mgp=mgp/min(2.25,nc))
  }
  do.call('axis', w)
  invisible()
}

trellis.strip.blank <- function()
{
  s.b <- trellis.par.get("strip.background")
  s.b$col <- 0
  trellis.par.set("strip.background", s.b)
  s.s <- trellis.par.get("strip.shingle")
  s.s$col <- 0
  trellis.par.set("strip.shingle", s.s)
  invisible()
}

lm.fit.qr.bare <- function(x, y, 
                           tolerance = NULL,
                           intercept=TRUE, xpxi=FALSE,
                           singzero=FALSE)
{
  if(!length(tolerance)) tolerance <- 1e-7
  if(intercept)
    x <- cbind(Intercept=1, x)
  else x <- as.matrix(x)
  z    <- lm.fit(x, y, tol=tolerance)
  coef <- z$coefficients
  if(singzero && any(isna <- is.na(coef))) coef[isna] <- 0.
    
  res <- z$residuals
  sse <- sum(res^2)
  sst <- sum((y - mean(y))^2)

  res <- list(coefficients = coef,    residuals = res, 
              rsquared     = 1 - sse / sst,
              fitted.values = z$fitted.values)
  if(xpxi) {
    p <- 1L : z$rank
    res$xpxi <- chol2inv(z$qr$qr[p, p, drop=FALSE])
  }
  res
}

all.is.numeric <- function(x, what=c('test','vector'),
                           extras=c('.','NA'))
{
  what <- match.arg(what)
  old <- options(warn=-1)
  on.exit(options(old))
  ##.Options$warn <- -1  6Aug00
  x <- sub('[[:space:]]+$', '', x)
  x <- sub('^[[:space:]]+', '', x)
  xs <- x[x %nin% c('',extras)]
  isnum <- !any(is.na(as.numeric(xs)))
  if(what=='test')
    isnum
  else if(isnum)
    as.numeric(x)
  else x
}

Lag <- function(x, shift=1)
{
  ## Lags vector x shift observations, padding with NAs or blank strings
  ## preserving attributes of x

  xLen <- length(x)
  if(shift == 0) return(x)
  
  # Create base vector use character to generate "" for mode "character"
  # Coerce base vector to be type of x
  ret <- as.vector(character(xLen), mode=storage.mode(x))
  
  # set resp attributes equal to x attributes
  attrib <- attributes(x)

  if(length(attrib$label))
    attrib$label <- paste(attrib$label, 'lagged', shift, 'observations')

  if(abs(shift) < xLen)
    {
      if(shift > 0) ret[-(1:shift)] <- x[1:(xLen - shift)]
      else ret[1:(xLen+shift)] <- x[(1-shift):xLen]
    }
  
  attributes(ret) <- attrib
  return(ret)
}

xySortNoDupNoNA <- function(x, y)
{
  if(is.list(x)) {
    y <- x[[2]]; x <- x[[1]]
  }
  
  s <- !is.na(x + y)
  if(any(s)) {
    x <- x[s]; y <- y[s]
  }
  
  i <- order(x)
  x <- x[i]
  y <- y[i]
  i <- !duplicated(x)
  list(x=x[i], y=y[i])
}

outerText <-
  function(string, y, cex=par('cex'), ...) {
    usr <- par('usr'); plt <- par('plt')
    pos <- usr[2] + (usr[2] - usr[1])/(plt[2] - plt[1]) * (1 - plt[2])
    axis(2, at=y, labels=string, tick=FALSE, las=1,
         pos=pos, cex.axis=cex, xpd=NA)
  }

##    if(missing(space)) space <- max(nchar(string))*.5
##    mtext(string, side=side, las=1, at=y, adj=adj, cex=cex, line=space)


# This method does not survive shrinking the graphics window
# Right justifies (if adj=1) a vector of strings against the right margin
# (side=4) or against the y-axis (side=2)
#outerText <-
#  function(string, y, side=4, cex=par('cex'), adj=1, ...) {
#    if(side %nin% c(2,4)) stop('only works for side=2 or 4')
#    x <- if(side==4) grconvertX(1, from='nfc', to='user') else
#     par('usr')[1]
#    text(x, y, paste(string,''), cex=cex, adj=adj, xpd=NA)
#}    

## Old method [dropped because does not scale upon resizing device]
  ## Use text() to put test strings in left or right margins
  ## Temporarily sets par(xpd=NA) if using R
  ## For adj=1 side=4, setAside is a character string used to determine
  ## the space to set aside for all strings
  ## space is the number of extra characters to leave to the left of
  ## the string(s) (adj=0) or to the right (adj=1)
  
if(FALSE) outerText <- function(string, y, setAside=string[1], side=4, space=1,
                      adj=1, cex=par('cex'))
{
  usr <- par('usr')
  xpd <- par('xpd')
  if(!is.na(xpd)) {
    on.exit(par(xpd=xpd))
    par(xpd=NA)
  }
  
  ie <- is.expression(string)  ## 1sep02
  if(ie)
    adj <- 0  ## adj=1 not work well for expressions in R
  
  if(side!=4)
    stop('only side=4 implemented')
  if(adj==0)
    text(usr[2], y,
         if(ie)
           string
         else
           paste(space,string,sep=''),
         adj=0)
  else {
    usr.space.needed <- strwidth(setAside, units='user', cex=cex)
    text(usr[2]+0.5*strwidth(space, units='user', cex=cex)+usr.space.needed,
         y, string, adj=1, cex=cex) # was usr[2]- 18jul02;added 0* 25jul02
    ## was 0*strwidth(space,...) 31jan03
  }
  invisible()
}

if(FALSE) {
  expandUsrCoord <- function()
  {
    ## Expands usr coordinates of current plot to entire figure region
    ## so that out of range plots may be plotted
    pr <- par()
    usr <- pr$usr
    p <- pr$plt
    invisible(pr)
  }
}


## Author: Patrick Connolly <P.Connolly@hortresearch.co.nz>
## HortResearch
## Mt Albert
## Auckland, New Zealand

print.char.matrix <-
  function (x, file = "",
            col.name.align = "cen", col.txt.align = "right", 
            cell.align = "cen", hsep = "|", vsep = "-", csep = "+",
            row.names = TRUE, col.names = FALSE,
            append = FALSE, top.border = TRUE, left.border = TRUE, ...) 
{
### To print a data frame or matrix to a text file or screen
###   and having names line up with stacked cells
###
### First, add row names as first column (might be removed later)
  
  ndimn <- names(dimnames(x))  ## FEH
  rownames <- dimnames(x)[[1]]
  x <- cbind(rownames, x)
  names(dimnames(x)) <- ndimn  ## FEH
  cnam <- dimnames(x)[[2]]     ## FEH
  if(length(ndimn))
    cnam[1] <- ndimn[1]  ## FEH
  ##dimnames(x)[[1]] <- seq(nrow(x))  25Mar02 for R  FEH
  dimnames(x) <- list(as.character(seq(nrow(x))), cnam)
  names(dimnames(x)) <- ndimn  ## 26Mar02 FEH
###  Set up some padding functions:
###
  pad.left <- function(z, pads)
  {
    ## Pads spaces to left of text
    padding <- paste(rep(" ", pads), collapse = "")
    paste(padding, z, sep = "")
  }
  
  pad.mid <- function(z, pads)
  {
    ## Centres text in available space
    padding.right <- paste(rep(" ", pads%/%2), collapse = "")
    padding.left <- paste(rep(" ", pads - pads%/%2), collapse = "")
    paste(padding.left, z, padding.right, sep = "")
  }
  
  pad.right <- function(z, pads) {
    ## Pads spaces to right of text
    padding <- paste(rep(" ", pads), collapse = "")
    paste(z, padding, sep = "")
  }
  
  ##  (Padding happens on the opposite side to alignment)
  pad.types <- c("left", "mid", "right")
  names(pad.types) <- c("right", "cen", "left")
  pad.name <- pad.types[col.name.align]
  pad.txt <- pad.types[col.txt.align]
  pad.cell <- pad.types[cell.align]
  
  ## Padding character columns
  ##    Need columns with uniform number of characters
  pad.char.col.right <- function(y)
  {
    ## For aligning text to LHS of column
    col.width <- nchar(y)
    biggest <- max(col.width)
    smallest <- min(col.width)
    padding <- biggest - col.width
    out <- NULL
    for (i in seq(y))
      out[i] <- pad.right(y[i], pads = padding[i])
    out
  }
  
  pad.char.col.left <- function(y)
  {
    ## For aligning text to RHS of column
    col.width <- nchar(y)
    biggest <- max(col.width)
    smallest <- min(col.width)
    padding <- biggest - col.width
    out <- NULL
    for (i in seq(y))
      out[i] <- pad.left(y[i], pads = padding[i])
    out
  }
  
  pad.char.col.mid <- function(y) {
    ## For aligning text to centre of column
    col.width <- nchar(y)
    biggest <- max(col.width)
    smallest <- min(col.width)
    padding <- biggest - col.width
    out <- NULL
    for (i in seq(y))
      out[i] <- pad.mid(y[i], pads = padding[i])
    out
  }
  
  ## which functions to use this time.
  pad.name.fn <- get(paste("pad.", pad.name, sep = ""))
  pad.txt.fn <- get(paste("pad.char.col.", pad.txt, sep = ""))
  pad.cell.fn <- get(paste("pad.", pad.cell, sep = ""))
  
  ## Remove troublesome factors
  x <- as.data.frame(x)
  fac.col <- names(x)[sapply(x, is.factor)]
  for (i in fac.col)
    x[, i] <- I(as.character(x[, i]))
  ## ARE ANY LINE BREAKS IN ANY COLUMNS?
  break.list <- list()
  for (i in seq(nrow(x))) {
    x.i <- unlist(x[i, ])
    rows.i <- sapply(strsplit(unlist(x[i, ]), "\n"), length)
    rows.i[rows.i < 1] <- 1
    break.list[[i]] <- rows.i
  }
  break.row <- sapply(break.list, function(x) any(x > 1))
  names(break.row) <- seq(nrow(x))
  xx <- x
  if (any(break.row)) {
    ## add in extra row/s
    xx <- NULL
    reprow <- lapply(break.list, unique)
    for (k in seq(nrow(x))) {
      x.k <- unlist(x[k, ])
      x.k[x.k == ""] <- " "
      if (break.row[k]) {
        l.k <- strsplit(x.k, "\n")
        add.blanks <- max(break.list[[k]]) - break.list[[k]]
        names(l.k) <- names(add.blanks) <- seq(length(l.k))
        if (any(add.blanks > 0)) {
          for (kk in names(add.blanks[add.blanks > 0]))
            l.k[[kk]] <- c(l.k[[kk]], rep(" ", add.blanks[kk]))
        }
        l.k.df <- as.data.frame(l.k)
        names(l.k.df) <- names(x)
        xx <- rbind(xx, as.matrix(l.k.df))
      }
      else xx <- rbind(xx, x.k)
    }
    row.names(xx) <- paste(rep(row.names(x), sapply(reprow, 
                                                    max)),
                           unlist(reprow), sep = ".")
    
    ## Make an index for the rows to be printed
    rn <- row.names(xx)
    rnb <- strsplit(rn, "\\.")
    rpref <- as.numeric(factor(sapply(rnb, function(z) z[1])))
    ## was codes( ) 10oct03
  }
  else
    rpref <- seq(nrow(x))
  x <- as.data.frame(xx)
  
  ## Character columns need different treatment from numeric columns
  char.cols <- sapply(x, is.character)
  if (any(char.cols)) 
    x[char.cols] <- sapply(x[char.cols], pad.txt.fn)
  
  ## Change numeric columns into character
  if (any(!char.cols)) 
    x[!char.cols] <- sapply(x[!char.cols], format)
  
  ## now all character columns each of which is uniform element width
  ##
  ## Lining up names with their columns
  ## Sometimes the names of columns are wider than the columns they name, 
  ##  sometimes vice versa.

  names.width <- nchar(names(x))
  if (!col.names) 
    names.width <- rep(0, length(names.width))
  cell.width <- sapply(x, function(y) max(nchar(as.character(y))))

  ## (the width of the characters in the cells as distinct
  ##  from their names)  
  name.pads <- cell.width - names.width
  cell.pads <- -name.pads
  name.pads[name.pads < 0] <- 0
  cell.pads[cell.pads < 0] <- 0
  pad.names <- name.pads > 0
  pad.cells <- cell.pads > 0
  
  ## Pad out the column names if necessary:
  if (any(pad.names)) {
    stretch.names <- names(x)[pad.names]
    for (i in stretch.names) {
      names(x)[names(x) == i] <- pad.name.fn(i, name.pads[i])
    }
  }
  
  ## likewise for the cells and columns
  if (any(pad.cells)) {
    stretch.cells <- names(x)[pad.cells]
    for (j in stretch.cells) x[, j] <- pad.cell.fn(x[, j], 
                                                   cell.pads[j])
  }
  
  ## Remove row names if not required
  if (!row.names) 
    x <- x[-1]
  ## Put the column names on top of matrix
  if (col.names) 
    mat2 <- rbind(names(x), as.matrix(x))
  else
    mat2 <- as.matrix(x)
  
  mat.names.width <- nchar(mat2[1, ])
  ## character string to separate rows
  space.h <- ""
  for (k in seq(along=mat.names.width)) {  ## added along= FEH 26Mar02
    space.h <- c(space.h, rep(vsep, mat.names.width[k]), csep)
  }
  
  line.sep <- paste(c(ifelse(left.border, csep, ""), space.h), 
                    collapse = "")
  if (col.names) 
    rpref <- c(0, rpref, 0)
  else
    rpref <- c(rpref, 0)
  
  ## print to screen or file
  if(top.border && line.sep !='') {
    write(line.sep, file = file, append = append)
    append <- TRUE
  }
  for (i in 1:nrow(mat2)) {
    if (left.border) 
      write(paste(paste(c("", mat2[i, ]), collapse = hsep), 
                  hsep, sep = ""), file = file, append = append)
    else
      write(paste(paste(mat2[i, ], collapse = hsep), hsep, 
                  sep = ""), file = file, append = append)
    append <- TRUE

    ## print separator if row prefix is not same as next one
    if (rpref[i] != rpref[i + 1] && line.sep != '') 
      write(line.sep, file = file, append = TRUE)
  }
}

unPaste <- function(str, sep='/')
{
  w <- strsplit(str, sep)
  w <- matrix(unlist(w), ncol=length(str))
  nr <- nrow(w)
  ans <- vector('list', nr)
  for(j in 1:nr)
    ans[[j]] <- w[j,]
  ans
}

get2rowHeads <- function(str) {
  w <- strsplit(str, '\n')
  ## strsplit returns character(0) when element=""  23may03
  list(sapply(w, function(x)if(length(x))    x[[1]] else ''),
       sapply(w, function(x)if(length(x) > 1)x[[2]] else ''))
}


## Note: can't say f[vector of names] <- list(...) to update args
## In R you have to put ALL arguments in list(...) so sometimes we set
## unneeded ones to NULL.  Ignore this assignment in S

## Two lists of functions, one for primitives for S+ or R (either Trellis
## or low-level), one for R grid
## Note: rect is only defined in R, not S+
ordGridFun <- function(grid)
{
  if(!grid)
    list(lines    = function(...) lines(...),
         points   = function(..., size=NULL)
                    {
                      if(length(size))
                        warning('size not implemented yet')
                      points(...)
                    },
         text     = function(...) text(...),
         segments = function(...) segments(...),
         arrows   = function(..., open, size) arrows(..., length=size*.8),
         rect     = function(...) rect(...),
         polygon  = function(x, y=NULL, ..., type=c('l','s'))
         {
           type <- match.arg(type)
           if(!length(y))
             {
               y <- x$y
               x <- x$x
             }
           j <- !is.na(x+y)
           x <- x[j]
           y <- y[j]
           if(type=='s') polygon(makeSteps(x, y), ..., border=NA)
           else polygon(x, y, ..., border=NA)
         },
         abline   = function(...) abline(...),
         unit     = function(x, units='native')
                    {
                      if(units!='native')
                        stop('units="native" is only units implemented outside of grid')
                      x
                    },
         axis     = function(...) axis(...))
  else {
    list(lines = function(x, y, ...)
         {
           if(is.list(x)) {
             y <- x[[2]]; x <- x[[1]]
           }
           llines(if(is.unit(x))
                    convertX(x, 'native', valueOnly=TRUE)
                  else x,
                  if(is.unit(y))
                    convertY(y, 'native', valueOnly=TRUE)
                  else y,
                  ...)
         },

         points = function(x, y, ...)
         {
           if(is.list(x)) {
             y <- x[[2]]; x <- x[[1]]
           }
           lpoints(if(is.unit(x))
                     convertX(x, 'native', valueOnly=TRUE)
                   else x,
                   if(is.unit(y))
                   convertY(y, 'native', valueOnly=TRUE)
                   else y,
                   ...)
         },

         text = function(x, y, ...)
         {
           if(is.list(x)) {
             y <- x[[2]]; x <- x[[1]]
           }
           ltext(if(is.unit(x))
                   convertX(x, 'native', valueOnly=TRUE)
                 else x,
                 if(is.unit(y))
                   convertY(y, 'native', valueOnly=TRUE)
                 else y,
                 ...)
         },

         segments = function(x0, y0, x1, y1, ...)
         {
           grid.segments(x0, y0, x1, y1, default.units='native',
                         gp=gpar(...))
         },
       
         arrows = function(...) larrows(...),

         rect = function(xleft, ybottom, xright, ytop, density, angle,
                         border, xpd, ...)
         {
           grid.rect(xleft, ybottom, width=xright-xleft,
                     height=ytop-ybottom, just='left',
                     default.units='native', gp=gpar(...))
         },
         polygon  = function(x, y=NULL, col=par('col'), type=c('l','s'), ...)
         {
           type <- match.arg(type)
           if(!length(y))
             {
               y <- x$y
               x <- x$x
             }
           j <- !is.na(x+y)
           x <- x[j]
           y <- y[j]
           if(type=='s') grid.polygon(makeSteps(x, y),
                default.units='native',
                gp=gpar(fill=col, col='transparent', ...))
           else grid.polygon(x, y, default.units='native',
                      gp=gpar(fill=col,col='transparent',...))
              },
         abline=function(...) panel.abline(...),
         unit = function(x, units='native', ...) unit(x, units=units, ...),
       
         axis = function(side=1, at=NULL, labels, ticks=TRUE,
                         distn, line, pos, outer, ...)
         {
           if(!length(at))stop('not implemented for at= unspecified')
           if(side > 2) stop('not implemented for side=3 or 4')
           ## ticks=ticks removed from grid.?axis FEH 30Aug09
           if(side==1) grid.xaxis(at=at, label=labels, gp=gpar(...))
           if(side==2) grid.yaxis(at=at, label=labels, gp=gpar(...))
         })
  }
}

parGrid <- function(grid=FALSE)
{
  pr <- par()
  cin <- pr$cin
  cex <- pr$cex
  lwd <- pr$lwd
  if(grid) {
    ## cvp <- current.viewport()
    ## usr <- c(cvp$xscale, cvp$yscale)
    usr <- c(convertX(unit(0:1, "npc"), "native", valueOnly=TRUE),
             convertY(unit(0:1, "npc"), "native", valueOnly=TRUE))

    pin <- 
      c(convertWidth(unit(1, "npc"), "inches", valueOnly=TRUE),
        convertHeight(unit(1, "npc"), "inches", valueOnly=TRUE))

    uin <- 
      c(convertWidth(unit(1, "native"), "inches", valueOnly=TRUE),
        convertHeight(unit(1, "native"), "inches", valueOnly=TRUE))
    
  }
  else {
    usr <- pr$usr
    pin <- pr$pin
    uin <- c(pin[1]/(usr[2]-usr[1]), pin[2]/(usr[4]-usr[3]))
    ## 22Mar01 - R does not have par(uin)
  }
  list(usr=usr, pin=pin, uin=uin, cin=cin, cex=cex, lwd=lwd)
}

## Replaces R's xinch, yinch, extending them to grid
## Defines these for S-Plus
## These convert inches to data units
xInch <- function(x=1, warn.log=!grid, grid=FALSE)
{
  if (warn.log && par("xlog"))
    warning("x log scale:  xInch() is nonsense")
  pr <- parGrid(grid)
  x * diff(pr$usr[1:2])/pr$pin[1]
}

yInch <- function (y = 1, warn.log=!grid, grid=FALSE)
{
  if (warn.log && par("ylog"))
    warning("y log scale:  yInch is nonsense")
  pr <- parGrid(grid)
  y * diff(pr$usr[3:4])/pr$pin[2]
}

  na.include <- function(obj) {
    if(inherits(obj,'data.frame'))
      for(i in seq(along=obj))
        obj[[i]] <- na.include(obj[[i]])
    else {
      if(length(levels(obj)) && any(is.na(obj)))
        obj <- factor(obj,exclude=NULL)
    }
    obj
  }


if(FALSE) {
  whichClosest <- function(x, w)
  {
    ## x: vector of reference values
    ## w: vector of values to find closest matches in x
    ## Returns: subscripts in x corresponding to w
    i <- order(x)
    x <- x[i]
    n <- length(x)
    br <- c(-1e30, x[-n]+diff(x)/2,1e30)
    m <- length(w)
    i[.C("bincode", as.double(w), m, as.double(br),
         length(br), code = integer(m), right = TRUE, 
         include = FALSE, NAOK = TRUE, DUP = FALSE, 
         PACKAGE = "base")$code]
  }
  NULL
}

## Just as good, ties shuffled to end
## function(x, w) round(approx(x,1:length(x),xout=w,rule=2,ties='ordered')$y)
## Remove ties= for S-Plus.  Note: does not work when 2nd arg to
## approx is not uniformly spaced
## NO! ties='ordered' bombs in x not ordered
## Try
## approx(c(1,3,5,2,4,2,4),1:7,xout=c(1,3,5,2,4,2,4),rule=2,ties=function(x)x[1])
## NO: only works in general if both x and y are already ordered


## The following runs the same speed as the previous S version (in R anyway)
whichClosest <- function(x, w)
{
  ## x: vector of reference values
  ## w: vector of values for which to lookup closest matches in x
  ## Returns: subscripts in x corresponding to w
  ## Assumes no NAs in x or w
  .Fortran("wclosest",as.double(w),as.double(x),
           length(w),length(x),
           j=integer(length(w)),PACKAGE="Hmisc")$j
}

whichClosePW <- function(x, w, f=0.2) {
  lx <- length(x)
  lw <- length(w)
  .Fortran("wclosepw",as.double(w),as.double(x),
           as.double(runif(lw)),as.double(f),
           lw, lx, double(lx), j=integer(lw),
           PACKAGE="Hmisc")$j
}              

whichClosek <- function(x, w, k) {
  ## x: vector of reference values
  ## w: vector of values for which to lookup close matches in x
  ## Returns: subscripts in x corresponding to w
  ## Assumes no NAs in x or w
  ## First jitters x so there are no ties
  ## Finds the k closest matches and takes a single random pick of these k
  y <- diff(sort(x))
  mindif <- if(all(y == 0)) 1 else min(y[y > 0])
  x <- x + runif(length(x), -mindif/100, mindif/100)
  z <- abs(outer(w, x, "-"))
  s <- apply(z, 1, function(u) order(u)[1:k])
  if(k == 1) return(s)
  apply(s, 2, function(u) sample(u, 1))
}
                        
if(FALSE) {
  sampWtdDist <- function(x, w)
  {
    ## x: vector of reference values
    ## w: vector of values to find closest matches in x
    ## Returns: subscripts in x corresponding to w

    ## 25% slower but simpler method:
    ## z <- abs(outer(w, x, "-"))
    ## s <- apply(z, 1, max)
    ## z <- (1 - sweep(z, 1, s, FUN='/')^3)^3
    ## sums <- apply(z, 1, sum)
    ## z <- sweep(z, 1, sums, FUN='/')

    lx <- length(x)
    lw <- length(w)
    z <- matrix(abs( rep( x , lw ) - rep( w, each = lx ) ),
                nrow=lw, ncol=lx, byrow=TRUE) ## Thanks: Chuck Berry
    ## s <- pmax( abs( w - min(x) ), abs( w - max(x) ) )  # to use max dist
    s <- rowSums(z)/lx/3   # use 1/3 mean dist for each row
    tricube <- function(u) (1 - pmin(u,1)^3)^3
    ## z <- (1 - (z/rep(s,length=lx*lw))^3)^3   # Thanks: Tim Hesterberg
    z <- tricube(z/s)   # Thanks: Tim Hesterberg
    sums <- rowSums(z)
    z <- z/sums 
    as.vector(rMultinom(z, 1))
  }
  NULL
}

approxExtrap <- function(x, y, xout, method='linear', n=50, rule=2,
                         f=0, ties='ordered', na.rm=FALSE)
{
  ## Linear interpolation using approx, with linear extrapolation
  ## beyond the data
  if(is.list(x)) {
    y <- x[[2]]; x <- x[[1]]
  }

  ## remove duplicates and order so can do linear extrapolation
  if(na.rm) {
    d <- !is.na(x+y)
    x <- x[d]; y <- y[d]
  }
  
  d <- !duplicated(x)
  x <- x[d]
  y <- y[d]
  d <- order(x)
  x <- x[d]
  y <- y[d]
  
  w <- approx(x, y, xout=xout, method=method, n=n,
              rule=2, f=f, ties=ties)$y
  
  r <- range(x)
  d <- xout < r[1]
  if(any(is.na(d)))
    stop('NAs not allowed in xout')
  
  if(any(d))
    w[d] <- (y[2]-y[1])/(x[2]-x[1])*(xout[d]-x[1])+y[1]
  
  d <- xout > r[2]
  n <- length(y)
  if(any(d))
    w[d] <- (y[n]-y[n-1])/(x[n]-x[n-1])*(xout[d]-x[n-1])+y[n-1]
  
  list(x=xout, y=w)
}


inverseFunction <- function(x, y) {
  d <- diff(y)
  xd <- x[-1]
  dl <- c(NA, d[-length(d)])
  ic <- which(d>=0 & dl<0 | d>0 & dl<=0 | d<=0 & dl>0 | d<0 & dl>=0)
  nt <- length(ic)
  k <- nt + 1
  if(k==1) {
    h <- function(y, xx, yy, turns, what, coef)
      approx(yy, xx, xout=y, rule=2)$y
    formals(h) <- list(y=numeric(0), xx=x, yy=y, turns=numeric(0),
                       what=character(0), coef=numeric(0))
  return(h)
  }
  turns <- x[ic]
  turnse <- c(-Inf, turns, Inf)
  xrange <- yrange <- matrix(NA, nrow=k, ncol=2)
  for(j in 1:k) {
    l <- which(x >= turnse[j] & x <= turnse[j+1])
    xrange[j,] <- x[l[c(1,length(l))]]
    yrange[j,] <- y[l[c(1,length(l))]]
  }

  for(j in 1:length(ic)) {
    l <- (ic[j]-1):(ic[j]+1)
    turns[j] <- approxExtrap(d[l], xd[l], xout=0, na.rm=TRUE)$y
  }

  h <- function(y, xx, yy, turns, xrange, yrange, what, coef) {
    what <- match.arg(what)
    ## Find number of monotonic intervals containing a given y value
    ylo <- pmin(yrange[,1],yrange[,2])
    yhi <- pmax(yrange[,1],yrange[,2])
    n <- outer(y, ylo, function(a,b)a >= b) &
         outer(y, yhi, function(a,b)a <= b)
    ## Columns of n indicate whether or not y interval applies
    ni <- nrow(yrange)
    fi <- matrix(NA, nrow=length(y), ncol=ni)
    turnse <- c(-Inf, turns, Inf)
    for(i in 1:ni) {
      w <- n[,i]
      if(any(w)) {
        l <- xx >= turnse[i] & xx <= turnse[i+1]
        fi[w,i] <- approx(yy[l], xx[l], xout=y[w])$y
      }
    }
    noint <- !apply(n, 1, any)
    if(any(noint)) {
      ## Determine if y is closer to yy at extreme left or extreme right
      ## of an interval
      m <- length(yy)
      yl <- as.vector(yrange); xl <- as.vector(xrange)
      fi[noint,1] <- xl[whichClosest(yl, y[noint])]
    }
    if(what=='sample')
      apply(fi, 1, function(x) {
       z <- x[!is.na(x)]
       if(length(z)==1) z else if(length(z)==0) NA else sample(z, size=1)
       }) else fi
  }
  formals(h) <- list(y=numeric(0), xx=x, yy=y, turns=turns,
                     xrange=xrange, yrange=yrange,
                     what=c('all', 'sample'), coef=numeric(0))
  ## coef is there for compatibility with areg use
  h
}

Names2names <- function(x)
{
  if(is.list(x)) {
  }
  else {
    n <- names(attributes(x))
    if(any(n=='.Names'))
      names(attributes(x)) <- ifelse(n=='.Names','names',n)
  }
  x
}

##xedit <- function(file, header, title, delete.file=FALSE) {
## In R, use e.g. options(pager=xedit); page(x,'p')
##  sys(paste('xedit -title "', title, '" ', file, ' &',
##            sep=''))
##  invisible()
##}

if(FALSE) {
  gless <- function(x, ...)
  {
    ## Usage: gless(x) - uses print method for x, puts in window with
    ## gless using name of x as file name prefixed by ~, leaves window open
    nam <- substring(deparse(substitute(x)), 1, 40)
    file <- paste('/tmp/',nam,sep='~')  #tempfile('Rpage.')
    sink(file)
    ##  cat(nam,'\n' )
    ##  if(length(attr(x,'label')) && !inherits(x,'labelled'))
    ##    cat(attr(x,'label'),'\n')
    ##  cat('\n')
    print(x, ...)
    sink()
    sys(paste('gless --geometry=600x400 "',file,'" &',sep=''))
    ## gless does not have a title option
    invisible()
  }
  NULL
}

xless <-
  function(x, ..., title=substring(deparse(substitute(x)),1,40))
{
  ## Usage: xless(x) - uses print method for x, puts in persistent window with
  ## xless using name of x as title (unless title= is specified)
	file <- tempfile()
  	sink(file)
  	print(x, ...)
  	sink()
  	cmd <- paste('xless -title "',title,'" -geometry "90x40" "',
               file,'" &',sep='')
    system(cmd)
invisible()
}


pasteFit <- function(x, sep=',', width=.Options$width)
{
  ## pastes as many elements of character vector x as will fit in a line
  ## of width 'width', starting new lines when needed
  ## result is the lines of pasted text
  m <- nchar(x)
  out <- character(0)
  cur <- ''
  n   <- 0
  for(i in 1:length(x)) {
    if(cur=='' | (m[i] + nchar(cur) <= width))
      cur <- paste(cur, x[i],
                   sep=if(cur=='')''
                       else sep)
    else {
      out <- c(out, cur)
      cur <- x[i]
    }
  }
  if(cur != '') out <- c(out, cur)
  out
}

## Determine if variable is a date, time, or date/time variable in R
## or S-Plus.  The following 2 functions are used by describe.vector
## timeUsed assumes is date/time combination variable and has no NAs
testDateTime <- function(x, what=c('either','both','timeVaries'))
{
  what <- match.arg(what)
  cl <- class(x)
  if(!length(cl))
    return(FALSE)

  dc <- c('Date', 'POSIXt','POSIXct','dates','times','chron')
  
  dtc <- c('POSIXt','POSIXct','chron')
  
  switch(what,
         either = any(cl %in% dc),
         both   = any(cl %in% dtc),
         timeVaries = {
           if('chron' %in% cl || 'Date' %in% cl) { 
             ## chron or S+ timeDate
             y <- as.numeric(x)
             length(unique(round(y - floor(y),13))) > 1
           }
           else length(unique(format(x,'%H%M%S'))) > 1
         })
}

## Format date/time variable from either R or S+
## x = a numeric summary of the original variable (e.g., mean)
## at = attributes of original variable
formatDateTime <- function(x, at, roundDay=FALSE)
{
  cl <- at$class
  w <- if(any(cl %in% c('chron','dates','times'))){
         attributes(x) <- at
         fmt <- at$format
         if(roundDay) {
           if(length(fmt)==2 && is.character(fmt))
             format(dates(x), fmt[1])
           else
             format(dates(x))
         }
         else x
       } else {
         attributes(x) <- at
         if(roundDay && 'Date' %nin% at$class) 
           as.POSIXct(round(x, 'days'))
         else x
       }
  format(w)
}


getHdata <-
  function(file, what=c('data','contents','description','all'),
           where='http://biostat.mc.vanderbilt.edu/twiki/pub/Main/DataSets')
  {
    what <- match.arg(what)
    fn <- as.character(substitute(file))
    ads <-
      scan(paste(where,'Rcontents.txt',sep='/'),list(''),quiet=TRUE)[[1]]
    a <- unlist(strsplit(ads,'.sav|.rda'))
    if(missing(file))
      return(a)
    
    wds <- paste(substitute(file),c('rda','sav'),sep='.')
    if(!any(wds %in% ads))
      stop(paste(paste(wds, collapse=','),
                 'are not on the web site.\nAvailable datasets:\n',
                 paste(a, collapse=' ')))
    wds <- wds[wds %in% ads]
    if(what %in% c('contents','all')) {
      w <- paste(if(fn=='nhgh')'' else 'C',fn,'.html',sep='')
      browseURL(paste(where,w,sep='/'))
    }
    
    if(what %in% c('description','all')) {
      ades <- scan(paste(where,'Dcontents.txt',sep='/'),list(''),
                   quiet=TRUE)[[1]]
      i <- grep(paste(fn,'\\.',sep=''),ades)
      if(!length(i))
        warning(paste('No description file available for',fn))
      else {
        w <- ades[i[1]]
        browseURL(paste(where,w,sep='/'))
      }
    }
    
    if(what %nin% c('data','all'))
      return(invisible())
    
    f <- paste(where,wds,sep='/')
    tf <- tempfile()
    download.file(f, tf, mode='wb', quiet=TRUE)
    load(tf, .GlobalEnv)
    invisible()
  }

hdquantile <- function(x, probs=seq(0, 1, 0.25), se=FALSE,
                       na.rm=FALSE, names=TRUE, weights=FALSE)
{
  if(na.rm) {
    na <- is.na(x)
    if(any(na))
      x <- x[!na]
  }
  
  x <- sort(x, na.last=TRUE)
  n <- length(x)
  if(n < 2)
    return(rep(NA, length(probs)))
  
  m  <- n + 1

  ps <- probs[probs > 0 & probs < 1]
  qs <- 1 - ps

  a <- outer((0:n)/n, ps,
             function(x,p,m) pbeta(x, p*m, (1-p)*m), m=m)
  w <- a[-1,] - a[-m,]

  r <- drop(x %*% w)
  rp <- range(probs)
  pp <- ps
  if(rp[1]==0) {
    r <- c(x[1], r); pp <- c(0,pp)
  }

  if(rp[2]==1) {
    r <- c(r, x[n]); pp <- c(pp,1)
  }
  
  r <- r[match(pp, probs)]

  if(names) names(r) <- format(probs)

if(weights)
  attr(r,'weights') <- structure(w, dimnames=list(NULL,format(ps)))

  if(!se)
    return(r)
  if(n < 3)
    stop('must have n >= 3 to get standard errors')

  l <- n - 1
  a <- outer((0:l)/l, ps,
             function(x,p,m) pbeta(x, p*m, (1-p)*m), m=m)
  w <- a[-1,] - a[-n,]

  storage.mode(x) <- 'double'
  storage.mode(w) <- 'double'

  nq <- length(ps)
  ## Get all n leave-out-one quantile estimates
  S <- matrix(.Fortran("jacklins", x, w, as.integer(n), as.integer(nq),
                       res=double(n*nq), PACKAGE='Hmisc')$res, ncol=nq)

  se <- l * sqrt(diag(var(S))/n)

  if(rp[1]==0)
    se <- c(NA, se)
  
  if(rp[2]==1)
    se <- c(se, NA)
  
  se <- se[match(pp,probs)]
  if(names)
    names(se) <- names(r)
  
  attr(r, 'se') <- se
  r
}

sepUnitsTrans <- function(x, 
                          conversion=c(day=1, month=365.25/12, year=365.25, week=7),
                          round=FALSE, digits=0)
{
  if(!any(is.present(x)))
    return(x)
  
  target <- names(conversion[conversion==1])
  if(!length(target))
    stop('must specify a target unit with conversion factor=1')
  
  lab <- attr(x,'label')
  x <- ifelse(is.present(x),casefold(as.character(x)),'')

  for(w in names(conversion)) {
    i <- grep(w, x)
    if(length(i)) x[i] <-
      as.character(as.numeric(gsub(paste(w,'s*',sep=''), '', x[i]))*
                   conversion[w])
  }

  i <- grep('[a-z]', x)
  if(any(i))
    warning(paste('variable contains units of measurement not in',
                  paste(names(conversion), collapse=','),':',
                  paste(unique(x[i]),collapse=' ')))
  
  x <- as.numeric(x)
  if(round)
    x <- round(x, digits)
  
  units(x) <- target
  if(length(lab))
    label(x) <- lab
  x
}

makeNames <- function(names, unique=FALSE, allow=NULL)
{
  ## Runs make.names with exceptions in vector allow
  ## By default, R 1.9 make.names is overridden to convert _ to . as
  ## with S-Plus and previous versions of R.  Specify allow='_' otherwise.
  n <- make.names(names, unique)
  if(!length(allow))
    n <- gsub('_', '.', n)
  n
}

Load <- function(object)
{
  nam <- deparse(substitute(object))
  path <- .Options$LoadPath
  if(length(path))
    path <- paste(path,'/',sep='')
  file <- paste(path, nam, '.rda', sep='')
  load(file, .GlobalEnv)
}

Save <- function(object, name=deparse(substitute(object)))
{
  path <- .Options$LoadPath
  if(length(path))
    path <- paste(path, '/', sep='')
  
  .FileName <- paste(path, name, '.rda', sep='')
  assign(name, object)
  eval(parse(text=paste('save(', name, ', file="',
                        .FileName, '", compress=TRUE)', sep='')))
}

getZip <- function(url, password=NULL) {
  ## Allows downloading and reading a .zip file containing one file
  ## File may be password protected.  Password will be requested unless given.
  ## Example: read.csv(getZip('http://biostat.mc.vanderbilt.edu/twiki/pub/Sandbox/WebHome/z.zip'))
  ## Password is 'foo'
  ## url may also be a local file
  ## Note: to make password-protected zip file z.zip, do zip -e z myfile
  if(toupper(substring(url, 1, 7)) == 'HTTP://') {
    f <- tempfile()
    download.file(url, f)
  } else f <- url
  cmd <- if(length(password))
    paste('unzip -p -P', password) else 'unzip -p'
  pipe(paste(cmd, f))
}

getLatestSource <- function(x=NULL, package='Hmisc',
                            recent=NULL, avail=FALSE,
                            type=c('svn','cvs')) {
  type <- match.arg(type)
  url <- switch(type,
                cvs=paste('http://biostat.mc.vanderbilt.edu/cgi-bin/cvsweb.cgi',
                  package, 'R/', sep='/'),
                svn=paste('http://biostat.mc.vanderbilt.edu/cgi-bin/viewvc.cgi',
                  package, 'trunk/R/', sep='/'))
  if(length(recent)) url <- paste(url, '?sortby=date#dirlist', sep='')
  
  w <- scan(url, what='',quiet=TRUE)
  i <- switch(type,
              cvs=grep('\\.s\\?rev=',w),
              svn=grep('\\.s\\?view=markup&amp;rev=', w))
  w <- w[i]
  
  files <- switch(type,
                  cvs=sub('href=\"(.*)\\?.*','\\1', w),
                  svn=sub('href=\".*/trunk/R/(.*)\\?.*','\\1', w))
  files <- sub('\\.s$','',files)
  ver <- switch(type,
                cvs=if(length(recent))
                sub('^.*rev=(.*);.*','\\1',w) else
                sub('\"$','',sub('^.*rev=','',w)),
                svn=if(length(recent))
                sub('^.*rev=(.*)&amp.*', '\\1', w) else
                sub('^.*rev=(.*)\"', '\\1', w))

  if(avail) return(data.frame(file=files, version=ver))

  if(length(recent)) x <- files[1:recent]
  if(length(x)==1 && x=='all') x <- files
  for(fun in x) {
    i <- which(files==fun)
    if(!length(i)) stop(paste('no file ', fun,' in ',package, sep=''))
    cat('Fetching', fun, 'version', ver[i],'\n')
    url <- switch(type,
                  cvs=paste('http://biostat.mc.vanderbilt.edu/cgi-bin/cvsweb.cgi/~checkout~/',package,'/R/',fun,'.s?rev=',ver[i],';content-type=text%2Fplain', sep=''),
                  svn=paste('http://biostat.mc.vanderbilt.edu/svn/R/',
                    package,'/trunk/R/', fun,'.s',sep=''))
    source(url)
  }
}
  
clowess <- function(x, y=NULL, iter=3, ...) {
  ## to get around bug in lowess with occasional wild values with iter>0
  r <- range(if(length(y)) y else x$y)
  f <- lowess(x, y, iter=iter, ...)
  if(iter != 0 && any(f$y < r[1] | f$y > r[2]))
    f <- lowess(x, y, iter=0)
  f
}

prselect <- function(x, start=NULL, stop=NULL, i=0, j=0, pr=TRUE)
  {
    f <- function(pattern, x)
      {
        y <- grep(pattern, x)
        if(length(y) > 1) y <- y[1]
        y
      }
    lx <- length(x)
    k <- if(length(start)) f(start, x) else 1
    if(length(k))
      {
        k <- k + i
        m <- if(length(stop))
          {
            w <- f(stop, x[k:lx])
            if(length(w)) w + k - 1 + j else -1
          }
        else lx
        if(m > 0) x <- if(k==1) (if(m==lx) '...' else c('...', x[-(k:m)]))
        else
          {
            if(m==lx) c(x[-(k:m)], '...')
            else c(x[1:(k-1)], '...', x[(m+1):lx])
          }
      }
    else # no start specified; keep lines after stop
      {
        m <- f(stop, x)
        if(length(m) > 0)
          {
            m <- if(length(m)) m + j - 1 else lx
            x <- if(m==lx) '...' else c('...', x[-(1:m)])
          }
      }
    if(pr) cat(x, sep='\n')
    invisible(x)
  }

## The following is taken from survival:::plot.survfit internal dostep function
## Remove code to remove duplicates in y

makeSteps <- function(x, y)
{
  if (is.na(x[1] + y[1]))
    {
      x <- x[-1]
      y <- y[-1]
    }
  n <- length(x)
  if (n > 2)
    {
      xrep <- rep(x, c(1, rep(2, n - 1)))
      yrep <- rep(y, c(rep(2, n - 1), 1))
      list(x = xrep, y = yrep)
    }
  else if (n == 1)
    list(x = x, y = y)
  else list(x = x[c(1, 2, 2)], y = y[c(1, 1, 2)])
}
