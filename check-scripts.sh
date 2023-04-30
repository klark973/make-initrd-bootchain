#!/bin/bash -efu

bindirs=SCRIPTDIR
bindirs="$bindirs:bootchain-core/data/sbin"
bindirs="$bindirs:bootchain-core/data/bin"
bindirs="$bindirs:bootchain-altboot/data/bin"
bindirs="$bindirs:bootchain-interactive/data/bin"
bindirs="$bindirs:bootchain-localdev/data/bin"
bindirs="$bindirs:bootchain-waitnet/data/bin"

sclist="
	SC1003
	SC1090
	SC1091
	SC2004
	SC2006
	SC2015
	SC2034
	SC2086
	SC2154
	SC2317
"

skip_check="
	bootchain-doc/samples/80-make-initrd-for-pipeline
"

do_check()
{
	local fname ftype nc

	# shellcheck disable=SC2035
	( set +f; find *.sh bootchain-* -type f ) |
		grep -v bootchain-doc/altboot-mixed/ |
	while read -r fname; do
		ftype="$(file -b -- "$fname")"
		[ -z "${ftype##*shell script*}" ] ||
			continue
		for nc in $skip_check _; do
			[ "x$nc" != x_ ] ||
				continue
			[ "x$nc" != "x$fname" ] ||
				continue 2
		done
		shellcheck --norc -s bash -P "$bindirs" "$@" -x "$fname" || :> ERROR
	done

	if [ -f ERROR ]; then
		rm -f ERROR
		return 1
	fi
}


excludes=
for e in $sclist; do
	excludes="${excludes:+$excludes,}$e"

	if [ "${1-}" = "-v" ] || [ "${1-}" = "--verbose" ]; then
		printf "*** Checking to %s...\n" "$e"
		do_check -i "$e" ||:
	fi
done

printf "*** Checking with all excludes...\n"
do_check -e "$excludes"
