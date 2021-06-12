# Bootchain sub-module: getimage

## Chain elements

- `getimage` receives and mounts the remote image.

## Boot parameters

- `getimage` specifies an URL to fetch and mount.

This parameter can be specified more than once depending on how many times
a corresponding element is mentioned in the `bootchain`.

## Example

Cmdline: root=bootchain bootchain=getimage,mountfs,overlayfs,rootfs getimage=http://ftp.altlinux.org/pub/people/mike/iso/misc/vi-20140918-i586.iso mountfs=rescue

Following these parameters, the bootchain downloads the vi-20140918-i586.iso
image, mount it as a loop, make it writable using overlayfs and will try to
boot from it.
