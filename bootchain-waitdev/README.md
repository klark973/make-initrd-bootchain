# Bootchain sub-module: waitdev

## Chain elements

- `waitdev` waits for the local device to appear.

## Boot parameters

- `waitdev` describes the local device to wait. The format of this parameter is
   the same as `root=`, but with optional `CDROM:` prefix.

This parameter can be specified more than once depending on how many times
a corresponding element is mentioned in the `bootchain`.

## Example

Cmdline: root=bootchain bootchain=waitdev,mountfs,mountfs,overlayfs,rootfs waitdev=CDROM:LABEL=ALT_regular-rescue/x86_64 mountfs=dev mountfs=rescue

Following these parameters, the bootchain wait local CDROM drive labeled as
`ALT_regular-rescue/x86_64`, mount it, mount squash file `rescue` as a loop
from it, make final rootfs writable using overlayfs and will try to boot from it.
