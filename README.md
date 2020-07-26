# expand-region-improved

## Improved expansion

This package aims to provide an improvement over the sometimes unpredictable expansion algorithm used by the original expand-region package.

We reuse most of the generic and mode-local expansions, which provides feature-parity with upstream expand-region.

Additionaly, we provide the following new features:

+ Support for overlapping regions
+ Grouped expansions in `eri-try-expand-list`
+ Moving cursor does not interrupt expansion
+ (Limited) recursion protection for expansion functions
+ Better default string detection

## New expansions

+ `eri/mark-line` :: mark a line of text including the trailing newline
+ `eri/mark-block` :: mark a text block enclosed by empty lines
+ `eri/mark-outside-quotes` :: improved `er/mark-outside-quotes`

## Easy customization

Simply inspect `eri/try-expand-list` and add functions to their fitting group.
