$(call feature-requires,bootchain-core)

BOOTCHAIN_WAITDEV_DATADIR = $(FEATURESDIR)/bootchain-waitdev/data

BOOTCHAIN_WAITDEV_FILES = \
	/lib/udev/rules.d/60-cdrom_id.rules \
	/lib/udev/cdrom_id \
