#!/bin/bash -efu

server="@SERVER@"
TMPDIR="${TMPDIR:-/tmp}"
srcdir="${1:-$TMPDIR/out}"
common_opts="vmlinuz initrd=initrd.img fastboot root=bootchain bootchain=fg,altboot ip=dhcp"
altinst_opts="stagename=altinst lowmem showopts vga=normal quiet splash lang=ru_RU"
live_opts="live stagename=live lowmem showopts quiet splash lang=ru_RU"
rescue_opts="live stagename=rescue showopts vga=normal splash=0"
forensic_opts="max_loop=16 forensic"


fatal()
{
	printf "fatal: %s\n" "$*" >&2
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
	imgargs $common_opts $opts
	boot
	EOF
}


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
cd "$dstdir"/

mkdir -p public/netinst/overlays-live/default
cd public/netinst/ && mkdir -p -m755 templates
cp -Lf -- "$src_squash" overlays-live/default/

live_st2size="$(extract_bootimgs live "$src_live")"
rescue_st2size="$(extract_bootimgs rescue "$src_rescue")"
altinst_st2size="$(extract_bootimgs altinst "$src_altinst")"

read -r rescue_hash <"./hash"
forensic_opts="$rescue_opts $forensic_opts hash=$rescue_hash"
unset rescue_hash
rm -f hash

live_isosize="$(copy_iso_image live "$src_live")"
rescue_isosize="$(copy_iso_image rescue "$src_rescue")"
altinst_isosize="$(copy_iso_image altinst "$src_altinst")"

ln -snf rescue/image.iso current
cd templates/

### HTTP

# normal boot
altboot_opts="automatic=method:http,network:dhcp,server:$server,directory:/boot/image.iso"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+http+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+http+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+http+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+http+hash+normal" "$image_opts"

# no debug: use rdshell for check and save resulting /var/log/bootchained.log
image_opts="rdshell $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+http+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+http+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+http+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+http+hash+no-debug" "$image_opts"

# errors: no such directory on the server
altboot_opts="automatic=method:http,network:dhcp,directory:/a/b/c"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+http+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+http+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+http+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+http+hash+errors" "$image_opts"

### FTP

# normal boot
altboot_opts="automatic=method:ftp,network:dhcp,server:$server,directory:/boot/image.iso"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+ftp+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+ftp+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+ftp+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+ftp+hash+normal" "$image_opts"

# no debug: use rdshell for check and save resulting /var/log/bootchained.log
image_opts="rdshell $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+ftp+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+ftp+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+ftp+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+ftp+hash+no-debug" "$image_opts"

# errors: no such directory on the server
altboot_opts="automatic=method:ftp,network:dhcp,directory:/a/b/c"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+ftp+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_isosize $live_opts"
write_tpl "live+ftp+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $rescue_opts"
write_tpl "rescue+ftp+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+ftp+hash+errors" "$image_opts"

### NFS

# normal boot
altboot_opts="automatic=method:nfs,network:dhcp"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+nfs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+nfs+slices" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+nfs+hash+slices" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size profile=none $live_opts"
write_tpl "live+nfs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
write_tpl "rescue+nfs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
write_tpl "rescue+nfs+hash+normal" "$image_opts"

# no debug: use rdshell for check and save resulting /var/log/bootchained.log
image_opts="rdshell $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+nfs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+nfs+slices+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size $rescue_opts"
write_tpl "rescue+nfs+slices+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_st2size profile=none $live_opts"
write_tpl "live+nfs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
write_tpl "rescue+nfs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
write_tpl "rescue+nfs+hash+no-debug" "$image_opts"

# errors: no such directory on the server
altboot_opts="automatic=method:nfs,network:dhcp,directory:/a/b/c"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+nfs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+nfs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $rescue_opts"
write_tpl "rescue+nfs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+nfs+hash+errors" "$image_opts"

### CIFS

# normal boot
altboot_opts="automatic=method:cifs,network:dhcp"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+cifs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+cifs+slices" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+cifs+hash+slices" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size profile=none $live_opts"
write_tpl "live+cifs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
write_tpl "rescue+cifs+normal" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
write_tpl "rescue+cifs+hash+normal" "$image_opts"

# no debug: use rdshell for check and save resulting /var/log/bootchained.log
image_opts="rdshell $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+cifs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+cifs+slices+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size $rescue_opts"
write_tpl "rescue+cifs+slices+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$live_st2size profile=none $live_opts"
write_tpl "live+cifs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size profile=none $rescue_opts"
write_tpl "rescue+cifs+no-debug" "$image_opts"
image_opts="rdshell $altboot_opts ramdisk_size=$rescue_st2size profile=none $forensic_opts"
write_tpl "rescue+cifs+hash+no-debug" "$image_opts"

# errors: no such directory on the server
altboot_opts="automatic=method:cifs,network:dhcp,directory:/a/b/c"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+cifs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$live_st2size $live_opts"
write_tpl "live+cifs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $rescue_opts"
write_tpl "rescue+cifs+errors" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+cifs+hash+errors" "$image_opts"

### Network console

altinst_opts="${altinst_opts//splash/splash=0 nottys}"
forensic_opts="$forensic_opts nottys"

### HTTP

altboot_opts="automatic=method:http,network:dhcp,server:$server,directory:/boot/image.iso"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+http+netcons" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+http+hash+netcons" "$image_opts"

### FTP

altboot_opts="automatic=method:ftp,network:dhcp,server:$server,directory:/boot/image.iso"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_isosize $altinst_opts"
write_tpl "altinst+ftp+netcons" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_isosize $forensic_opts"
write_tpl "rescue+ftp+hash+netcons" "$image_opts"

### NFS

altboot_opts="automatic=method:nfs,network:dhcp"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+nfs+netcons" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+nfs+hash+netcons" "$image_opts"

### CIFS

altboot_opts="automatic=method:cifs,network:dhcp"
image_opts="bc_debug $altboot_opts ramdisk_size=$altinst_st2size $altinst_opts"
write_tpl "altinst+cifs+netcons" "$image_opts"
image_opts="bc_debug $altboot_opts ramdisk_size=$rescue_st2size $forensic_opts"
write_tpl "rescue+cifs+hash+netcons" "$image_opts"

