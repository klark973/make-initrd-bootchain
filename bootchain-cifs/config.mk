$(call feature-requires,bootchain-waitnet)

BOOTCHAIN_CIFS_DATADIR = $(FEATURESDIR)/bootchain-cifs/data

BOOTCHAIN_CIFS_PROGS = mount.cifs resolve

# See ALTBUG #40554 about cmac.ko
BOOTCHAIN_CIFS_MODULES = cifs cmac
