Note: this file is auto converted from expand-region-improved.el by [el2org](https://github.com/tumashu/el2org), please do not edit it by hand!!!


# Table of Contents

1.  [**expand-region-improved**](#org732000d)
    1.  [Improved expansion](#org6b79317)
    2.  [New expansions](#org310396d)
    3.  [Easy customization](#org04ea859)


<a id="org732000d"></a>

# **expand-region-improved**


<a id="org6b79317"></a>

## Improved expansion

This package provides an improvement over the sometimes
unpredictable expansion algorithm used by the original
expand-region.

We reuse most of the generic and mode-local expansions, which
provides feature-parity with upstream expand-region.

We provide the following additional features:

-   Overlapping regions
-   Better string detection
-   Grouped expansions
-   Moving cursor does not interrupt expansion
-   Recursion protection

There are some drawbacks as well:

-   Transient-mark-mode is required
-   FIXME: Multiple-cursors are not yet supported


<a id="org310396d"></a>

## New expansions


<a id="org04ea859"></a>

## Easy customization

