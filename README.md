# expand-region-improved

## Improved expansion

This package aims to provide an improvement over the sometimes unpredictable expansion algorithm used by the original expand-region package.

We reuse most of the generic and mode-local expansions, which provides feature-parity with upstream expand-region.
Like upstream expand-region, expand-region-improved is fully compatible with multiple-cursors.

Additionaly, we provide the following new features:

+ Support for overlapping regions
+ Grouped expansions in `eri-try-expand-list`
+ Moving cursor does not interrupt expansion
+ Better default string detection
+ (LIMITED) Recursion protection for expansion functions
+ (TO BE DOCUMENTED) Helpers for creating custom expansion functions

## New expansions

+ `eri/mark-line` :: mark a line of text including the trailing newline
+ `eri/mark-block` :: mark a text block enclosed by empty lines
+ `eri/mark-outside-quotes` :: improved `er/mark-outside-quotes`

## Easy customization

Simply inspect `eri/try-expand-list` and add functions to their fitting group.
