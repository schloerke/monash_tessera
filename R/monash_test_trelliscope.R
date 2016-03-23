# devtools::install_github("hafen/housingData")

# load packages
library(housingData)
library(datadr)
library(trelliscope)

# look at housing data
str(housing)
# 'data.frame':   224369 obs. of  7 variables:
#  $ fips            : Factor w/ 3235 levels "01001","01003",..: 187 187 187 187 187 187 187 187 187 187 ...
#  $ county          : Factor w/ 1969 levels "Abbeville County",..: 17 17 17 17 17 17 17 17 17 17 ...
#  $ state           : Factor w/ 57 levels "AK","AL","AR",..: 6 6 6 6 6 6 6 6 6 6 ...
#  $ time            : Date, format: "2008-10-01" "2008-11-01" ...
#  $ nSold           : num  NA NA NA NA NA NA NA NA NA NA ...
#  $ medListPriceSqft: num  308 299 NA 290 288 ...
#  $ medSoldPriceSqft: num  326 NA 318 306 292 ...
# We see that we have a data frame with the information we discussed, in addition to the number of units sold.

# Setting up a visualization database
# We create many plots throughout the course of analysis, and with Trelliscope, we can store these in a “visualization database” (VDB), which is a directory on our computer where all of the information about our display artifacts is stored. Typically we will set up a single VDB for each project we are working on. To initialize and connect to a VDB, we call the vdbConn() function with the path where our VDB is located (or where we would like it to be located), and optionally give it a name.

# connect to a "visualization database"
# conn <- vdbConn("vdb", name = "tesseraTutorial", autoYes = TRUE)

# # http://tessera.io/docs-datadr/#large_hdfs_rhipe
# library(Rhipe); rhinit()
# conn <- hdfsConn("/user/barret/housing/byCounty", autoYes = TRUE)



# This connects to a directory called "vdb" relative to our current working directory. The first time you do this it will ask to make sure you want to create the directory. R holds this connection in its global options so that subsequent calls will know where to put things without explicitly specifying the connection each time.

# Visualization by county and state
# Trelliscope allows us to visualize large data sets in detail. We do this by splitting the data into meaningful subsets and applying a visualization to each subset, and then interactively viewing the panels of the display.

# An interesting thing to look at with the housing data is the median list and sold price over time by county and state. To split the data in this way, we use the divide() function from the datadr package. It is recommended to have some familiarity with the datadr package.



hdfs_conn <- function(subPath, autoYes = TRUE, ...) {
  fullPath <- paste("/user/barret/monash/", subPath, sep = "")
  hdfsConn(fullPath, autoYes = autoYes, ...)
}
conn <- hdfs_conn("rawHousing")

addData(conn, list(
  list("key1", housing)
))

# addData(conn, housing)
housingDdf <- ddf(conn)
housingDdf
housingDdf <- updateAttributes(housingDdf)
housingDdf


# divide housing data by county and state
byCountyDdf <- divide(
  housingDdf,
  by = c("county", "state"),
  # overwrite = TRUE,
  output = hdfs_conn("byCountyOriginal"),
  update = TRUE
)
# rhcp("/user/barret/monash/byCountyOriginal", "/user/barret/monash/byCounty")
# byCountyDdf <- ddf(hdfsConn("/ln/bschloe/monash/byCounty"))
# byCountyDdf

# Our byCounty object is now a distributed data frame (ddf), which is simply a data frame split into chunks of key-value pairs. The key defines the split, and the value is the data frame for that split. We can see some of its attributes by printing the object:

# look at byCounty object
byCountyDdf

# Distributed data frame backed by 'kvMemory' connection
#
#  attribute      | value
# ----------------+-----------------------------------------------------------
#  names          | fips(cha), time(Dat), nSold(num), and 2 more
#  nrow           | 224369
#  size (stored)  | 15.73 MB
#  size (object)  | 15.73 MB
#  # subsets      | 2883
#
# * Other attributes: getKeys(), splitSizeDistn(), splitRowDistn(), summary()
# * Conditioning variables: county, state

# And we can look at one of the subsets:

# look at a subset of byCounty
byCountyDdf[[1]]
# $key
# [1] "county=Abbeville County|state=SC"
#
# $value
#    fips       time nSold medListPriceSqft medSoldPriceSqft
# 1 45001 2008-10-01    NA         73.06226               NA
# 2 45001 2008-11-01    NA         70.71429               NA
# 3 45001 2008-12-01    NA         70.71429               NA
# 4 45001 2009-01-01    NA         73.43750               NA
# 5 45001 2009-02-01    NA         78.69565               NA
# ...

# The key tells us that this is Abbeville county in South Carolina, and the value is the price data for this county.

# Creating a panel function
# To create a Trelliscope display, we need to first provide a panel function, which specifies what to plot for each subset. It takes as input either a key-value pair or just a value, depending on whether the function has two arguments or one.
#
# For example, here is a panel function that takes a value and creates a lattice xyplot of list and sold price over time:

# create a panel function of list and sold price vs. time
library(lattice)
timePanel <- function(x) {
  xyplot(
    medListPriceSqft + medSoldPriceSqft ~ time,
    data = x,
    auto.key = TRUE,
    ylab = "Price / Sq. Ft."
  )
}

library(ggplot2)
library(reshape2)
timePanel <- function(x) {
  dt <- melt(
    x[, c("fips", "time", "medListPriceSqft", "medSoldPriceSqft")],
    c("fips", "time")
  )
  qplot(
    x = time, y = value,
    data = dt,
    geom = c("line", "point"),
    color = variable
  ) +
    labs(y = "Price / Sq. Ft")
}
# Note that you can use most any R plot command here (base R plots, lattice, ggplot, rCharts, ggvis).

# test it on a subset:

# test function on a subset
timePanel(byCountyDdf[[20]]$value)

# Great!

# Creating a cognostics function
# Another thing we can do is specify a cognostics function for each subset. A cognostic is a metric that tells us an interesting attribute about a subset of data, and we can use cognostics to have more worthwhile interactions with all of the panels in the display. A cognostic function needs to return a list of metrics:

# create a cognostics function of metrics of interest
library(trelliscope)
priceCog <- function(x) {
  # do work here!
  zillowString <- gsub(" ", "-", do.call(paste, getSplitVars(x)))

  # return list of cogs
  list(
    slope = cog(
      coef(lm(medListPriceSqft ~ time, data = x))[2],
      desc = "list price slope"
    ),
    meanList = cogMean(x$medListPriceSqft),
    meanSold = cogMean(x$medSoldPriceSqft),
    nObs = cog(
      length(which(!is.na(x$medListPriceSqft))),
      desc = "number of non-NA list prices"
    ),
    zillowHref = cogHref(
      sprintf("http://www.zillow.com/homes/%s_rb/", zillowString),
      desc = "zillow link"
    )
  )
}
# We use the cog() function to wrap our metrics so that we can provide a description for the cognostic, and we also employ special cognostics functions cogMean() and cogRange() to compute mean and range with a default description.

# We should test the cognostics function on a subset:

# test cognostics function on a subset
priceCog(byCountyDdf[[1]]$value)
# $slope
#          time
# -0.0002323686
#
# $meanList
# [1] 72.76927
#
# $meanSold
# [1] NaN
#
# $nObs
# [1] 66
#
# $zillowHref
# [1] "<a href=\"http://www.zillow.com/homes/Abbeville-County-SC_rb/\" target=\"_blank\">link</a>"
# Making the display
# Now we can create a Trelliscope display by sending our data, our panel function, and our cognostics function to makeDisplay():

# create the display and add to vdb
vdbConn <- vdbConn("vdb2", autoYes = TRUE)
# byCountyDdf <- makeExtractable(byCountyDdf)

makeDisplay(
  byCountyDdf,
  conn = vdbConn,
  name = "list_sold_vs_time_quickstart",
  desc = "List and sold price over time",
  panelFn = timePanel,
  cogFn = priceCog,
  width = 400, height = 400
)
# makeDisplay(...)
# makeDisplay(...)
# makeDisplay(...)

# This creates a new entry in our visualization database and stores all of the appropriate information for the Trelliscope viewer to know how to construct the panels.

# If you have been dutifully following along with this example in your own R console, you can now view the display with the following:


vdbConn <- vdbConn("vdb", autoYes = TRUE)
view(port = 4000, openBrowser = FALSE)


# # To load the vdb when you return...
# vdbConn <- vdbConn("vdb", autoYes = TRUE)
# view(port = 4000, openBrowser = FALSE)
