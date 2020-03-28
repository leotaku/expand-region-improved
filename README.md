Note: this file is auto converted from expand-region-improved.el by [el2org](https://github.com/tumashu/el2org), please do not edit it by hand!!!


# Table of Contents

1.  [**expand-region-improved**](#org46c5b46)
    1.  [Better expansion](#orga8811df)
    2.  [New expansions](#org4cd3dd7)
    3.  [Easy customization](#org521a1e0)


<a id="org46c5b46"></a>

# **expand-region-improved**


<a id="orga8811df"></a>

## Better expansion

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


<a id="org4cd3dd7"></a>

## New expansions


<a id="org521a1e0"></a>

## Easy customization

