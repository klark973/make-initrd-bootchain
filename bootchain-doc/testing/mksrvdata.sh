#!/bin/bash -efu

pubkey="${1-}"
server="@SERVER@"
TMPDIR="${TMPDIR:-/tmp}"
progdir="$(realpath -- "${0%/*}")"
netX_opts="ifname=bootif0:\${netX/mac} ip=bootif0:dhcp4"
common_opts="vmlinuz initrd=initrd.img fastboot root=bootchain bootchain=fg,altboot"
rescue_opts="live stagename=rescue showopts vga=normal nosplash autorun=directory:/boot"
altinst_opts="stagename=altinst lowmem showopts vga=normal quiet splash lang=ru_RU"
live_opts="live stagename=live lowmem showopts quiet splash lang=ru_RU"
forensic_base_opts="max_loop=16 forensic"
srcdir="$TMPDIR/out"


fatal()
{
	printf "%s fatal: %s\n" "${0##*/}" "$*" >&2
	exit 1
}

get_iso_uuid()
{
	/sbin/blkid -c /dev/null -o value -s UUID -- "$1"
}

extract_bootimgs()
{
	local sz stage2="$1" iso="$2"

	7z x "$iso" boot/initrd.img boot/vmlinuz "$stage2" >/dev/null
	sz="$(du -sB1k --apparent-size -- "$stage2" |sed -E 's/\s+.*$//')"
	[ "$stage2" != rescue ] || sha256sum rescue |sed -E 's/\s+.*$//' >"./hash"
	rm -f -- "$stage2"
	mv -f -- boot "$stage2"
	echo -n "$((1 + $sz))"
}

copy_iso_image()
{
	local sz stage2="$1" iso="$2"

	sz="$(du -sB1k --apparent-size -- "$iso" |sed -E 's/\s+.*$//')"
	cp -Lf -- "$iso" "$stage2"/image.iso
	echo -n "$((1 + $sz))"
}

write_tpl()
{
	local name="$1" opts="$2"

	cat >"$name" <<-EOF
	#!ipxe

	kernel http://$server/boot/vmlinuz
	initrd http://$server/boot/initrd.img
	imgargs $common_opts bc_test=$name $opts
	boot
	EOF
}

ns_suite()
{
	local method="$1" dir="$2" name="ns-$1"
	local opts="automatic=method:$method,type:iso,server:$server,directory:$dir"

	# normal boot
	write_tpl "altinst+$name+normal"	"bc_debug $opts $altinst_opts"
	write_tpl "live+$name+normal"		"bc_debug $opts $live_opts"
	write_tpl "rescue+$name+normal"		"bc_debug $opts $rescue_opts"
	write_tpl "rescue+$name+hash+normal"	"bc_debug $opts $forensic_opts"

	# no debug: use rdshell for check and save resulting log
	write_tpl "altinst+$name+no-debug"	"rdshell $opts $altinst_opts"
	write_tpl "live+$name+no-debug"		"rdshell $opts $live_opts"
	write_tpl "rescue+$name+no-debug"	"$opts $rescue_opts"
	write_tpl "rescue+$name+hash+no-debug"	"$opts $forensic_opts"

	# 3x network interfaces
	opts="$opts $netX_opts"
	write_tpl "altinst+$name+3xnet"		"bc_debug $opts $altinst_opts"
	write_tpl "live+$name+3xnet"		"bc_debug $opts $live_opts"
	write_tpl "rescue+$name+hash+3xnet"	"bc_debug $opts $forensic_opts"

	# errors: no such directory on the server
	opts="automatic=method:$method,server:$server,directory:/a/b/c"
	write_tpl "altinst+$name+errors"	"bc_debug $opts $altinst_opts"
	write_tpl "live+$name+errors"		"bc_debug $opts $live_opts"
	write_tpl "rescue+$name+errors"		"bc_debug $opts $rescue_opts"
	write_tpl "rescue+$name+hash+errors"	"bc_debug $opts $forensic_opts"
}

std_suite()
{
	local method="$1" dir="$2" name="$3"
	local opts="bc_debug automatic=method:$method,directory:$dir"

	# normal boot
	write_tpl "altinst+$name+normal+rd"		\
		  "$opts ramdisk_size=$altinst_st2size $altinst_opts"
	write_tpl "altinst+$name+normal+tmpfs"		\
		  "$opts $altinst_opts"
	write_tpl "live+$name+slices+rd"		\
		  "$opts ramdisk_size=$live_st2size $live_opts"
	write_tpl "live+$name+slices+tmpfs"		\
		  "$opts $live_opts"
	write_tpl "rescue+$name+hash+slices"		\
		  "$opts ramdisk_size=$rescue_st2size $forensic_opts"
	write_tpl "live+$name+normal+rd"		\
		  "$opts ramdisk_size=$live_st2size profile=none $live_opts"
	write_tpl "live+$name+normal+tmpfs"		\
		  "$opts profile=none $live_opts"
	write_tpl "rescue+$name+normal+rd"		\
		  "$opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
	write_tpl "rescue+$name+normal+tmpfs"		\
		  "$opts profile=none $rescue_opts"
	write_tpl "rescue+$name+hash+normal+rd"		\
		  "$opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
	write_tpl "rescue+$name+hash+normal+tmpfs"	\
		  "$opts profile=none $forensic_opts"

	# no debug: use rdshell for check and save resulting log
	opts="rdshell automatic=method:$method,directory:$dir"
	write_tpl "altinst+$name+no-debug+rd"		\
		  "$opts ramdisk_size=$altinst_st2size $altinst_opts"
	write_tpl "altinst+$name+no-debug+tmpfs" 	\
		  "$opts $altinst_opts"
	write_tpl "live+$name+slices+no-debug+rd"	\
		  "$opts ramdisk_size=$live_st2size $live_opts"
	write_tpl "live+$name+slices+no-debug+tmpfs"	\
		  "$opts $live_opts"
	write_tpl "rescue+$name+slices+no-debug+rd"	\
		  "$opts ramdisk_size=$rescue_st2size $rescue_opts"
	write_tpl "rescue+$name+slices+no-debug+tmpfs"	\
		  "$opts $rescue_opts"
	write_tpl "live+$name+no-debug+rd"		\
		  "$opts ramdisk_size=$live_st2size profile=none $live_opts"
	write_tpl "live+$name+no-debug+tmpfs"		\
		  "$opts profile=none $live_opts"
	write_tpl "rescue+$name+no-debug+rd"		\
		  "$opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
	write_tpl "rescue+$name+no-debug+tmpfs"		\
		  "$opts profile=none $rescue_opts"
	write_tpl "rescue+$name+hash+no-debug+rd"	\
		  "$opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
	write_tpl "rescue+$name+hash+no-debug+tmpfs"	\
		  "$opts profile=none $forensic_opts"

	# 3x network interfaces
	opts="bc_debug automatic=method:$method,directory:$dir $netX_opts"
	write_tpl "altinst+$name+3xnet+rd"		\
		  "$opts ramdisk_size=$altinst_st2size $altinst_opts"
	write_tpl "altinst+$name+3xnet+tmpfs"		\
		  "$opts $altinst_opts"
	write_tpl "live+$name+3xnet+rd"			\
		  "$opts ramdisk_size=$live_st2size profile=none $live_opts"
	write_tpl "live+$name+3xnet+tmpfs"		\
		  "$opts profile=none $live_opts"
	write_tpl "rescue+$name+3xnet+rd"		\
		  "$opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
	write_tpl "rescue+$name+3xnet+tmpfs"		\
		  "$opts profile=none $rescue_opts"
	write_tpl "rescue+$name+hash+3xnet+rd"		\
		  "$opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
	write_tpl "rescue+$name+hash+3xnet+tmpfs"	\
		  "$opts profile=none $forensic_opts"

	# Check only once
	if [ -z "$dir" ]; then
		# errors: no such directory on the server
		opts="bc_debug automatic=method:$method,directory:/a/b/c"
		write_tpl "altinst+$name+errors+rd"	\
			  "$opts ramdisk_size=$altinst_st2size $altinst_opts"
		write_tpl "altinst+$name+errors+tmpfs"	\
			  "$opts $altinst_opts"
		write_tpl "live+$name+errors+rd"	\
			  "$opts ramdisk_size=$live_st2size $live_opts"
		write_tpl "live+$name+errors+tmpfs"	\
			  "$opts ramdisk_size=$live_st2size $live_opts"
		write_tpl "rescue+$name+errors+rd"	\
			  "$opts ramdisk_size=$rescue_st2size $rescue_opts"
		write_tpl "rescue+$name+errors+tmpfs"	\
			  "$opts ramdisk_size=$rescue_st2size $rescue_opts"
		write_tpl "rescue+$name+hash+errors"	\
			  "$opts ramdisk_size=$rescue_st2size $forensic_opts"
	fi
}

cons_suite()
{
	local method="$1" dir="$2"
	local opts="bc_debug automatic=method:$method,server:$server,directory:$dir"

	write_tpl "altinst+$method+netcons+rd"		\
		  "$opts ramdisk_size=$altinst_st2size $altinst_opts"
	write_tpl "altinst+$method+netcons+tmpfs"	\
		  "$opts $altinst_opts"
	write_tpl "altinst+$method+silent+rd"		\
		  "$opts noaskuser ramdisk_size=$altinst_st2size $altinst_opts"
	write_tpl "altinst+$method+silent+tmpfs"	\
		  "$opts noaskuser $altinst_opts"
	write_tpl "rescue+$method+hash+netcons+rd"	\
		  "$opts ramdisk_size=$rescue_st2size $forensic_opts"
	write_tpl "rescue+$method+hash+netcons+tmpfs"	\
		  "$opts $forensic_opts"
	write_tpl "rescue+$method+hash+silent+rd"	\
		  "$opts noaskuser ramdisk_size=$rescue_st2size $forensic_opts"
	write_tpl "rescue+$method+hash+silent+tmpfs"	\
		  "$opts noaskuser $forensic_opts"
}


# Entry point
[ -d "$srcdir" ] ||
	fatal "source directory not found: $srcdir"
srcdir="$(realpath -- "$srcdir")"
dstdir="$(realpath .)"

cd "$srcdir"/
# shellcheck disable=SC2012
src_rescue="$srcdir/$(set +f; ls -X1 regular-rescue-*.iso 2>/dev/null |tail -n1)"
[ -s "$src_rescue" ] ||
	fatal "ALT Rescue not found"
# shellcheck disable=SC2012
src_altinst="$srcdir/$(set +f; ls -X1 regular-jeos-sysv-*.iso 2>/dev/null |tail -n1)"
[ -s "$src_altinst" ] ||
	fatal "JeOS Installer not found"
# shellcheck disable=SC2012
src_live="$srcdir/$(set +f; ls -X1 regular-mate-*.iso 2>/dev/null |tail -n1)"
[ -s "$src_live" ] ||
	fatal "MATE LiveCD not found"
src_squash="$srcdir"/root.squashfs
[ -s "$src_squash" ] ||
	fatal "Rootfs overlay squash not found"
[ -z "$pubkey" ] || [ -s "$pubkey" ] ||
	fatal "Public SSH-key not found"
cd "$dstdir"/

# Create data disk skeleton
mkdir -p templates public/netinst/overlays-live/default
cp -Lrf -- "$progdir"/server ./scripts
cp -f -- "$progdir"/server.conf ./scripts/
[ -z "$pubkey" ] ||
	cat -- "$pubkey" >scripts/PUBKEY
ln -snf public pub
mkdir boot && cd boot/

cat >autorun <<-EOF
#!/bin/sh -efu

[ -s /var/log/BC-TEST.passed ]
testname="\$(head -n1 /var/log/BC-TEST.passed)"
echo "Test case '\$testname' passed in the stage2."

mount -t 9p backup /mnt
[ ! -s /var/log/chaind.log ] ||
    cp -Lf /var/log/chaind.log /mnt/
cp -Lf /var/log/BC-TEST.passed /mnt/
umount /mnt

exec poweroff -f
EOF

chmod +x autorun
ln -snf /srv/public/netinst/ipxe/rescue+ns-http+no-debug script.ipxe
ln -snf /srv/public/netinst/boot/initrd.img ./
ln -snf /srv/public/netinst/boot/vmlinuz ./
cd ../public/netinst/ && mkdir mnt ipxe
cp -Lf -- "$src_squash" overlays-live/default/

rescue_hash="$(sha256sum "$src_rescue" |sed -E 's/\s+.*$//')"
forensic_opts="$rescue_opts $forensic_base_opts hash=$rescue_hash"

live_st2size="$(extract_bootimgs live "$src_live")"
rescue_st2size="$(extract_bootimgs rescue "$src_rescue")"
altinst_st2size="$(extract_bootimgs altinst "$src_altinst")"

live_isosize="$(copy_iso_image live "$src_live")"
rescue_isosize="$(copy_iso_image rescue "$src_rescue")"
altinst_isosize="$(copy_iso_image altinst "$src_altinst")"

read -r r_hash <"./hash" && rm -f "./hash"
ln -snf boot/image.iso current
ln -snf rescue boot
cd ../../templates/

## Netstart test cases: complete ISO-image will be
## downloaded into the tmpfs, RAM-disk do not used

ns_suite http	/pub/netinst/current
ns_suite ftp	/pub/netinst/current

## Standalone alterator-netinst test cases

forensic_opts="$rescue_opts $forensic_base_opts hash=$r_hash"

# Use default path

std_suite nfs	''				def-nfs
std_suite cifs	''				def-cifs
std_suite http	''				def-http
std_suite ftp	''				def-ftp

# Symlink to ISO-image file

std_suite nfs	/srv/public/netinst/current	iso-nfs
std_suite cifs	/srv/public/netinst/current	iso-cifs
std_suite http	/pub/netinst/current		iso-http
std_suite ftp	/pub/netinst/current		iso-ftp

# Mount point or directory with the image contents

std_suite nfs	/srv/public/netinst/mnt		mnt-nfs
std_suite cifs	/srv/public/netinst/mnt		mnt-cifs
std_suite http	/pub/netinst/mnt		mnt-http
std_suite ftp	/pub/netinst/mnt		mnt-ftp

## Network and serial console test cases

altinst_opts="${altinst_opts//splash/nosplash console=ttyS0,115200n8}"
forensic_opts="$forensic_opts console=ttyS0,115200n8"

cons_suite nfs	/srv/public/netinst/current
cons_suite cifs	/srv/public/netinst/current
cons_suite http	/pub/netinst/current
cons_suite ftp	/pub/netinst/current

