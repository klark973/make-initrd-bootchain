$(call feature-requires,depmod-image)
$(call feature-disables,pipeline)

BOOTCHAIN_CORE_DATADIR = $(FEATURESDIR)/bootchain-core/data

BOOTCHAIN_CORE_MODULES = fs-iso9660 fs-squashfs fs-overlay devname:loop-control

BOOTCHAIN_PATH ?= /etc/sysconfig
