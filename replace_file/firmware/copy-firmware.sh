#!/bin/sh
# SPDX-License-Identifier: GPL-2.0
#
# Copy firmware files based on WHENCE list
#

verbose=:
if [ x"$1" = x"-v" ]; then
    verbose=echo
    shift
fi

destdir="$1"

grep '^File:' WHENCE | sed -e's/^File: *//g' -e's/"//g' | while read f; do
    test -f "$f" || continue
    $verbose "copying file $f"
    mkdir -p $destdir/$(dirname "$f")
    cp -d "$f" $destdir/"$f"
done

grep -E '^Link:' WHENCE | sed -e's/^Link: *//g' -e's/-> //g' | while read f d; do
    test -L "$f" || continue
    test -f "$destdir/$f" && continue
    $verbose "copying link $f"
    mkdir -p $destdir/$(dirname "$f")
    cp -d "$f" $destdir/"$f"
done

exit 0
