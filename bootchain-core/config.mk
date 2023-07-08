$(call feature-requires,depmod-image)
$(call feature-disables,pipeline)

BOOTCHAIN_CORE_DATADIR = $(FEATURESDIR)/bootchain-core/data

BOOTCHAIN_CORE_MODULES = isofs squashfs overlay

BOOTCHAIN_CORE_FILES = $(shell [ ! -f /etc/sysconfig/bootchain ] || echo -n "/etc/sysconfig/bootchain")
