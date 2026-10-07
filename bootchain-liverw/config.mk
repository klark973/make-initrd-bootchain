$(call feature-requires,bootchain-localdev)

BOOTCHAIN_LIVERW_DATADIR = $(FEATURESDIR)/bootchain-liverw/data

BOOTCHAIN_LIVERW_PROGS = addpart sfdisk mke2fs e2label wipefs checkisomd5

BOOTCHAIN_LIVERW_FILES = /etc/mke2fs.conf
