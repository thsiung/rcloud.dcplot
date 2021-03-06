wdcplot.special.variable <- function(name) structure(name, wdcplot.placeholder = "special")
wdcplot.column <- function(name) structure(name, wdcplot.placeholder = "column")

wdcplot.state <- new.env()

# really we want multiple contexts and chart groups and so on
wdcplot.get.default.context <- function()
  wdcplot.state$default.context


wdcplot.keywords <- c('group', 'groups', 'dimension', 'dimensions', 'chart', 'charts')

wdcplot.substitute <- function(context, expr) {
  data <- context$data

  # make a pseudo-environment which maps columns and special variables to placeholders
  specials <- list(..index.. = wdcplot.special.variable('index'),
                   ..value.. = wdcplot.special.variable('value'),
                   ..selected.. = wdcplot.special.variable('selected'),
                   ..key.. = wdcplot.special.variable('key'))
  # reserved keywords should not be interpreted as columns - this is pretty
  # dumb and will get better when we only interpret expressions, not the whole block
  column.names <- setdiff(names(data), wdcplot.keywords)
  cols2placeholders <- Map(wdcplot.column, column.names)
  looksee <- list2env(c(cols2placeholders, specials))

  # this feint comes from pryr: make substitute work in the global environment
  parent.env <- parent.frame(2);
  if (identical(parent.env, globalenv())) {
    parent.env <- as.list(parent.env)
  }

  # substitute in this order:
  # - first evaluate anything bquoted with .(expr)
  # - then substitute in the dataframe pseudo-environment
  # - then substitute in the parent environment
  do.call(substitute,
          list(do.call(substitute,
                       list(do.call(bquote, list(expr, where = parent.env)),
                            looksee)),
               parent.env))

}

wdcplot <- function(data, dims=NULL, groups=NULL, charts=NULL) {
  context <- list(data=data)
  assign('default.context', context, envir=wdcplot.state)

  dims2 <- wdcplot.substitute(context, substitute(dims))
  groups2 <- wdcplot.substitute(context, substitute(groups))
  charts2 <- wdcplot.substitute(context, substitute(charts))

  div.maker <- dcplot.caps$handle_dcplot(list("dcplot", data, dims2, groups2, charts2))

  deferred.rcloud.result(function() div.maker)
}
