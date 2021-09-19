$(call feature-requires,bootchain-waitnet)
$(call feature-disables,nfsroot)

BOOTCHAIN_NFS_DATADIR = $(FEATURESDIR)/bootchain-nfs/data

BOOTCHAIN_NFS_PROGS = mount.nfs ss

BOOTCHAIN_NFS_PRELOAD = af_packet nfs
