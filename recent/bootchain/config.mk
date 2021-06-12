$(call feature-disables,pipeline nfsroot)
$(call feature-requires,depmod-image network)

BOOTCHAIN_DATADIR = $(FEATURESDIR)/bootchain/data

BOOTCHAIN_PROGS = \
	less \
	chvt \
	openvt \
	reset \
	pv \
	dialog \
	resolve \
	mount.nfs \
	mount.cifs \
	losetup \
	curl \
	ss \
	sfdisk \
	blockdev \
	mke2fs \
	e2label \
	wipefs

BOOTCHAIN_FILES = \
	/lib/terminfo/l/linux \
	/lib/udev/rules.d/60-cdrom_id.rules \
	/lib/udev/cdrom_id \
	/etc/mke2fs.conf

BOOTCHAIN_MODULES = isofs squashfs overlay
BOOTCHAIN_PRELOAD = af_packet nfs
