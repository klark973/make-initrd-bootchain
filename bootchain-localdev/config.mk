$(call feature-requires,bootchain-altboot)

BOOTCHAIN_LOCALDEV_DATADIR = $(FEATURESDIR)/bootchain-localdev/data

BOOTCHAIN_LOCALDEV_FILES = \
	/lib/udev/rules.d/60-cdrom_id.rules \
	/lib/udev/cdrom_id
