#!/bin/bash -efu

# PDF version
version="v4.4"
outfile="${TMPDIR-/tmp}/altboot-$version.pdf"
n="$(type -P asciidoctor-pdf xdg-open |wc -l)"

if [ "$n" != 2 ]; then
	echo "First, install asciidoctor-pdf and xdg-utils!" >&2
	exit 1
fi

cd -- "${0%/*}"/bootchain-doc/
rm -f -- "$outfile"
asciidoctor-pdf \
	-a pdf-themesdir=build \
	-a pdf-theme=adoc-theme.yml \
	-o "$outfile" build/index.txt
cd - >/dev/null

if [ -s "$outfile" ]; then
	echo "The result is saved to $outfile"
	xdg-open "$outfile" >/dev/null 2>&1
fi
