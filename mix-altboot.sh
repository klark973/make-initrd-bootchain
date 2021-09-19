#!/bin/bash -efu

MODULES="
	core
	getimage
	waitdev
	interactive
	altboot
	localdev
	waitnet
	nfs
	cifs
	liverw
"
BASHDIRS="
	automatic
	global-args
	add-methods
	forget-args
	liveboot-init
	liveboot-pre
	liveboot-post
	livecd-slice
	rw-overlay
	translate
"
PACKAGE=bootchain
COMMON="$PACKAGE-doc/altboot-mixed"


bash_hooks()
{
	local hook

	if [ ! -d "$hdir" ]; then
		printf '### %s not found in /lib/altboot\n\n' "${hdir##*/}"
		return 0
	fi

	printf '### Bash hooks in %s:\n\n' "${hdir##*/}"

	# shellcheck disable=SC2012
	ls -1 -- "$hdir/" 2>/dev/null |sort |
	while read -r hook; do
		[ -r "$hdir/$hook" ] ||
			continue
		if [ ! -s "$hdir/$hook" ]; then
			printf '### %s (hook is empty)\n\n' "$hook"
		else
			sed -e "s,^#\!/bin/bash.*$,### $hook," "$hdir/$hook"
			printf '\n'
		fi
	done
}


[ ! -d "$COMMON" ] ||
	rm -rf -- "$COMMON"
mkdir -p -- "$COMMON/hooks"

for x in $MODULES; do
	cp -aRf -- "$PACKAGE-$x/data" "$COMMON/"
done

for x in $BASHDIRS; do
	hdir="$COMMON/data/lib/altboot/$x.d"
	bash_hooks >"$COMMON/hooks/$x.sh"
done
