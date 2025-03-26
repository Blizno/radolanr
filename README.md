radolanr
================

<!-- README.md is generated from README.Rmd. Please edit that file -->

# 1 Description

This package helps to download series of radolan data and to create
timeseries of this data for given centroids provided as shape files.
This package provides some usefull wrappers around the rdwd package to
make more convinient processes. Outputs may likewise be used by rdwd
package functions.

# 2 Usage

## 2.1 Install Package

``` r
# This package is not yet on CRAN. The easiest way to get sapflowr is to install it via github:
library(devtools)
install_github("Blizno/radolanr") # this will install the version on "main"
```

``` r
# At the moment the package is a private package, you will need credentials
https://rdrr.io/cran/remotes/man/install_github.html recomends: 
# "
# To install from a private repo, use auth_token with a token
# from https://github.com/settings/tokens. You only need the
# repo scope. Best practice is to save your PAT (Personal Access Token) in env var called
# GITHUB_PAT.
# "
install_github("Blizno/radolanr", auth_token = "abcdefasdf")

# pottentially you may also use the https link if you are logged into your github account at the same time (e.g. via www.github.de in our browser)
```

## 2.2 load the package

``` r
library(radolanr)
```
