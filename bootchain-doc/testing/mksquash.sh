#!/bin/bash -efu

srcdir="${1-}"
dstdir="${TMPDIR:-/tmp}"/out
result="$dstdir"/root.squashfs


exit_handler()
{
	local rc=$?

	trap - EXIT
	[ -z "$srcdir" ] ||
		rm -rf --one-file-system -- "$srcdir"
	exit $rc
}

fill_sample_rootfs()
{
	cd -- "$srcdir"/
	mkdir -p test1/test2/test3 test4/test5 test6
	echo "Test #3" >test1/test2/test3/test3.txt
	echo "Test #2" >test1/test2/test2.txt
	echo "Test #1" >test1/test1.txt
	echo "Test #5" >test4/test5/test5.txt
	echo "Test #4" >test4/test4.txt
	echo "Test #6" >test6/test6.txt
	echo "Test #7" >test7.txt
	cd -
}


rm -f -- "$result"

if [ -n "$srcdir" ]; then
	srcdir="$(realpath -- "$srcdir")"
else
	trap exit_handler EXIT
	srcdir="$(mktemp -dt)"
	fill_sample_rootfs
fi

# shellcheck disable=SC2174
mkdir -p -m755 -- "$dstdir"
/sbin/mksquashfs "$srcdir" "$result" -root-owned \
	-no-exports -no-sparse -no-xattrs -noappend -no-recovery

