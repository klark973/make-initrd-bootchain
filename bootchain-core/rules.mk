MODULES_TRY_ADD += $(BOOTCHAIN_CORE_MODULES)

PUT_FEATURE_DIRS += $(BOOTCHAIN_CORE_DATADIR)

.PHONY: bootchain-core

# copy the config from any place
bootchain-core: create
	@bootchain_path=`realpath $(BOOTCHAIN_PATH)` && \
	    [ ! -f "$$bootchain_path"/bootchain ] || \
	    put-file -r "$$bootchain_path" -fv "$(ROOTDIR)"/etc/sysconfig \
	        "$$bootchain_path"/bootchain

pack: bootchain-core
