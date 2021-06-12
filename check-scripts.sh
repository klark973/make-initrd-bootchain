#!/bin/bash -efu

bindirs=SCRIPTDIR
bindirs="$bindirs:bootchain-core/data/sbin"
bindirs="$bindirs:bootchain-core/data/bin"
bindirs="$bindirs:bootchain-altboot/data/bin"
bindirs="$bindirs:bootchain-interactive/data/bin"
bindirs="$bindirs:bootchain-localdev/data/bin"

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
"

do_check()
{
	local fname ftype

	# shellcheck disable=SC2035
	( set +f; find *.sh bootchain-* -type f ) |
	while read -r fname; do
		ftype="$(file -b -- "$fname")"
		[ -n "${ftype##*shell script*}" ] ||
			shellcheck --norc -s bash -P "$bindirs" "$@" -x "$fname" ||
				:> ERROR
	done

	if [ -f ERROR ]; then
		rm -f ERROR
		return 1
	fi
}


excludes=
for e in $sclist; do
	excludes="${excludes:+$excludes,}$e"

	if [ "x${1-}" = "x-v" ] || [ "x${1-}" = "x--verbose" ]; then
		printf "*** Checking to %s...\n" "$e"
		do_check -i "$e" ||:
	fi
done

printf "*** Checking with all excludes...\n"
do_check -e "$excludes"
