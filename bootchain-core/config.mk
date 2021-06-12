$(call feature-requires,depmod-image)
$(call feature-disables,pipeline)

BOOTCHAIN_CORE_DATADIR = $(FEATURESDIR)/bootchain-core/data

BOOTCHAIN_CORE_MODULES = isofs squashfs overlay
