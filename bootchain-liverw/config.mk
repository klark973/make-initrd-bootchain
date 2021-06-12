$(call feature-requires,bootchain-local)

BOOTCHAIN_LIVERW_DATADIR = $(FEATURESDIR)/bootchain-liverw/data

BOOTCHAIN_LIVERW_PROGS = addpart sfdisk mke2fs e2label wipefs

BOOTCHAIN_LIVERW_FILES = /etc/mke2fs.conf
