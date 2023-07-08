$(call feature-requires,bootchain-core)

BOOTCHAIN_INTERACTIVE_DATADIR = $(FEATURESDIR)/bootchain-interactive/data

BOOTCHAIN_INTERACTIVE_PROGS = chvt dialog less openvt pv

BOOTCHAIN_INTERACTIVE_FILES = $(shell [ ! -f /etc/dialogrc.error ] || echo -n "/etc/dialogrc.error")
