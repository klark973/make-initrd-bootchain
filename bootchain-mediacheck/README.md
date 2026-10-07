# Feature: bootchain-mediacheck

This is not a standalone feature. This is an add-on to the `bootchain-altboot`
feature. It allows to check boot ISO-image by the `checkisomd5` utility before
it will be mounted. It works only in the propagator-compatibity mode.

## Boot parameters

- `mediacheck` just enables this check for the whole ISO-image and at the
   same time it disables other kinds of checking of image hashes.

## Example

Cmdline: root=bootchain bootchain=fg,altboot mediacheck automatic=...
