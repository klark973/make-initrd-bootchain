# Feature bootchain-waitdev

This is not a standalone feature. This is an add-on to the bootchain-core
feature. It allows to wait a specified block or character special devices.

## Chain elements

- `waitdev` waits for the local device to appear.

## Boot parameters

- `waitdev` describes the local device to wait. The format of this parameter is
   the same as `root=`, but with optional `CDROM:` prefix. This parameter can be
   specified more than once depending on how many times a corresponding element
   is mentioned in the `bootchain`.
- `waitdev_timeout` describes a common timeout for all `waitdev` steps in the
  `bootchain`. Defining a timeout allows to use a fallback if the specified
  devices are not ready yet. By default is not set, which makes to wait forever.

## Example

Cmdline: root=bootchain bootchain=waitdev,mountfs,mountfs,overlayfs,rootfs waitdev=CDROM:LABEL=ALT_regular-rescue/x86_64 mountfs=dev mountfs=rescue

Following these parameters, the bootchain wait local CDROM drive labeled as
"ALT_regular-rescue/x86_64", mount it, mount squash file "rescue" as a loop
from it, make final rootfs writable using overlayfs and will try to boot from it.
