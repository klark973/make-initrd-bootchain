# Feature: bootchain-core

`bootchain-core` - it's a fork and further development the original
feature of `pipeline`. This feature allow us to consistently setup
steps-scripts one by one. For details about `pipeline` you can see
in ../features/pipeline/README.md.

In fork process `pipeline` was divided by three parts:

- `bootchain-core` - the main functional of feature `pipeline`, common
  API and daemon.
- `bootchain-getimage` - method to networking boot from ISO-image with
  the wget utility.
- `bootchain-waitdev` - method to boot from specified local media.

The future work with `bootchain` allowed us to create a few modules.
They are expected to be upstream soon. This divide on modules allow
us to optimize fill in `initramfs` only which we are need.

## Main components of bootchain-core

- `/bin/bootchain-sh-functions` - common API and evolution
  of `pipeline-sh-functions`.
- `/sbin/bootchained` - daemon, evolution of `pipelined`.
- `/sbin/bootchain-logvt` - script which allow to control sub terminal.
- `/etc/rc.d/init.d/bootchain` - sysvinit start script.

## Reasons of making fork and rename pipeline

- A set of `bootchain` modules was developed in order to create a
  replacement in stage1 programs `propagator`, fully integrated into
  the run-time `make-initrd`. In the original version, the `pipeline`
  feature did not satisfy this need. At an early stage of development,
  it was not yet known what functionality `bootchain` would eventually
  have, how far it would go from the fork and be able to whether to be
  fully compatible with it.
- For some time, the development of `bootchain` was carried out independently
  of the main project `make-initrd`. To build and test bootable disks with
  `make-initrd` and `bootchain` so that `bootchain` does not depend on
  `make-initrd` versions, so that not intersect with the `pipeline` features
  built into the `make-initrd` and so as not to interfere the author of
  `make-initrd`, the `pipeline` feature had to be copied under a different
  name, giving it a more appropriate name at the same time.
- The result of the completed step is not always used next. Steps-scripts
  they can use the results not only of the previous one, but also of any
  earlier one the completed step. So it's not a pipeline in its purest
  form, but rather a chain loading steps, the sequence of actions performed.

## Defference from the original pipeline

- Modularity: loading methods are initially separated from the common
  code and daemon.
- The main loop of the `bootchain-loop` daemon is separated from the
  `bootchained` daemon code, which provides the ability to bring the daemon
  to the foreground at any time. In fact, this restarts the `bootchain-loop`
  process on a specific terminal, although initially the daemon runs this
  process in the background.
- Some steps (actions) are built directly into the code of the main loop
  of the `bootchain-loop` daemon, external scripts are not called to execute
  them. Such pseudo-steps allow you to control, basically, the internal state
  of the daemon and should not be taken into account in the boot chain, as if
  they are hidden.
- Optionally, the daemon can work in conjunction with the `bootchain-interactive`
  feature, can move to the foreground and continue working on a specific terminal,
  by default, tty2. Jointly features `bootchain-core` and `bootchain-interactive`
  they lay the foundation for building simple text installers in stage1.
- The `bootchianed` daemon allows you to overload the chain with a new set of
  steps, thanks to this, you can change the logic of work "on the fly", support
  loops and conditional jumps, in text dialogs it is an opportunity to go back.
- Keeps records of the steps taken at least once and allows you to prevent their
  re-launch.
- `bootchain-sh-functions` extends the API of the original `pipeline-sh-functions`,
  see the details in the corresponding section.
- Via resolve_target() supports not only forward, but also reverse addressing,
  relative to the current step. For example, a record like `step-3/dir1/dev`
  will process the result of `dir1/dev`, made in the third step from the current
  one. Together with the overload of the chain of steps, direct addressing is safe
  only when storing the numbers of the completed steps in files, whereas reverse
  relative addressing it is safe in any case and can often be more convenient.
- Allows you to work with shorter and more familiar paths to special files
  devices thanks to the use of `DEVNAME` along with `dev`.
- Provides the ability to associate the <IN> of a step with the <OUT>
  of the previous step through symbolic links to mount points inside initramfs,
  outside the tree the results of the steps, which provides, if necessary, the
  overlap mounting mechanism inherent in the program `propagator`.
- Along with the NATIVE mode of operation, the `bootchianed` daemon can work
  in COMPATIBILITY WITH `pipeline`. In the NATIVE mode of operation, the daemon
  imposes another an approach to processing the status code of the completed
  step and the method of premature completion of the boot chain, see the details
  in the corresponding section.
- The daemon can be configured when building initramfs via the included file
  configurations of `/etc/sysconfig/bootchain`, and not only through boot
  parameters, see the details in the corresponding section.
- The `bootchianed` daemon offers visual and advanced debugging. By default,
  the log is kept in `/var/log/bootchained.log` and is available on tty3,
  and when enabled advanced debugging or self-testing functions are also copied
  to stage2. Service step-the `debug` script in advanced debugging mode is run
  before by launching any other step-script and allows you to visually track
  the received values at each <IN>.

Despite the differences, `bootchained` is backward compatible with previously
written steps for the `pipelined` daemon and does not require changes for
configurations with `root=pipeline`.

## Features of the pipelined work

If the step-script will be finished with code of status 2, the original daemon
`pipelined` will understand it like a must to stop chains and finish work.
(meaning that system is ready to go stage2). If the step-script does not
process this code from an external command, and stage2 is not ready to work
yet, a situation with premature termination of the daemon will arise.

If the step-script will be finished with non-null code of status (different
from 2), daemon `pipelined` will understand it like a fail and will repeat this
failure-step with pause in one second in infinity cycle (until common timeout
rootdelay=180). But, sometimes repeat steps are unnecessary because the
situation is incorrigible and repeating will just waste of time and make a
system log is filling up. But the daemon `pipelined` don't know how to work
with this situations.

## New approach in bootchained daemon

For steps-scripts are suggested before finish work with code of status 0 call
break_bc_loop() for tell to the daemon about ready stage2 and needed finish
work this daemon after the current step.In case of a failure in the step-by-step
scenario, the daemon can repeat it, but no more than four times with a pause of
two seconds. In order for a failure in the step-by-step scenario to lead to an
immediate shutdown of the daemon, it is necessary to use the internal step
`noretry`.

## Daemon operation mode

### NATIVE mode of operation

NATIVE mode is activated by the `root=bootchain` parameter. In this mode, the
daemon will perceive the status code 2 from the step script in the same way as
any other non-zero code and then act according to the internal state: if
repetitions are allowed, the step script will be called again with a pause
of 2 seconds, but no more than four times. If repetitions are prohibited,
the daemon itself will immediately terminate.

### Pipeline COMPATIBILITY mode

Compatibility mode is activated by the `root=pipeline` parameter. In this mode,
the daemon behaves the same as the original `pipelined`, except that it limits
the number of re-runs of the failed step. He perceives the status code 2 not as
a failure, but as a command to end the main daemon cycle.

## Configuration

The configuration is defined in the file `/etc/sysconfig/bootchain` when
building the image initramfs, optional and may contain the following parameters:

- `BC_LOG_VT` is the number of the virtual terminal to which the debug log
  should be output in the background. By default, the value is 3, respectively,
  the log is output to tty3. An empty value allows you to disable log output
  to any terminal.
- `BC_FGVT_ACTIVATE` - delay in seconds before activating the interactive
  terminal, by default tty2 is activated after 2 seconds in debug mode
  or after 8 seconds in normal mode. An empty value instructs to activate
  the interactive terminal immediately. This configuration option only works
  together with the `bootchain-interactive` features included in initramfs.
- `BC_LOGFILE` - the full path to the log file or the name of a special device,
  to which debugging messages will be output. In NATIVE mode, the default value
  is the default value is `/var/log/bootchained.log`, in compatibility mode with
  `pipeline` the default value is `/var/log/pipelined.log`.
- `mntdir` - where to create subdirectories of the boot chain steps. In NATIVE
  mode the default value is `/dev/bootchain`, in COMPATIBILITY mode with
  `pipeline`, the default value is `/dev/pipeline`.

Other `bootchain-*` modules can also use this configuration file for their
own needs.

## In-app pseudo-steps

All the steps listed below are an extension of the `pipeline`. They are
embedded in the code of the main loop of the `boot chain-loop` daemon, do
not need additional parameters and should not be taken into account when
addressing, as if they are hidden.

- `fg` - provides the transfer of the daemon to interactive mode when building
  initramfs with `bootchain-interactive` features. The `bootchain-core` itself
  is not interactivity required, but some other steps may need it, such as
  `altboot`.
- `noop` - does not perform any actions and is designed to pull off the results
  on the <OUT> of the previous step from the <IN> of the next step, which can
  be useful, for example, when we don`t want the results of the `waitdev` step
  to be used in the next step, `localdev`, which primarily looks at them.
- `noretry` - prohibits the following steps from ending with a non-zero return
  code, what will lead to the immediate shutdown of the daemon in case of a
  script failure any next step. By default, the steps are allowed to fail,
  the daemon will try to restart them again four times with a pause of two
  seconds.
- `retry` - allows all subsequent steps to be completed with a non-zero return
  code, which will lead to their starting five times, in total. This mode of
  operation of the daemon operates by default.

## External elements of the bootchain (steps-scripts)

- `mountfs` - mounts a file or device from the result of the previous or other
  specified step.
- `overlayfs` - combines one or more elements of the boot chain using overlayfs.
- `rootfs` - forces the daemon to use the result of the previous element as the
  found root of stage 2.

## Boot parameters

- `bootchain=name1[,name2][,name3]` - defines the initial state of the boot
  chains, i.e. the steps that the daemon must go through one by one. These can
  be both built-in pseudo-steps and real scripts of the actions performed. The
  names these steps are listed separated by commas.
- `pipeline=name1[,name2][,name3]` - alias for `bootchain=...`.
- `mountfs=target` - specifies the file or device to be mounted.
- `overlayfs=list` - defines the list of elements to combine.
- `bc_debug` - a boolean parameter that enables advanced debugging and forces
  if the daemon completes successfully, copy the download log to stage2.
- `bc_test=name` - defines the name of the current test case in the process of
  fully automated self-testing, forcing in case of successful after completing
  the daemon, copy the download log to stage2 and next to it create a
  `BC-TEST.passed` file with the specified name of the test case.

## bootchain-sh-functions extended API

- check_parameter() - checks that the required parameter is not empty, otherwise
  it exits via fatal().
- get_parameter() - outputs the value of the parameter of the current step by
  the index $callnum.
- resolve_target() - output the path to a file, directory or device, depending
  on from the parameter.
- resolve_devname() - output the path to a special device file at the specified
  directory. Usually the step directory contains a DEVNAME or dev file if the
  device was the result of a step, then the function will return a readable
  `/dev/node`.
- debug() - text message output during extended debugging.
- enter() - tracing during extended debugging: entering the specified function.
- leave() - tracing during extended debugging: exit from the specified function.
- run() - run an external command. With extended debugging, the executed command
  will be logged.
- fdump() - output of the contents of the specified file during extended
  debugging.
- assign() - assignment of the specified value to a variable that gets into
  the log with advanced debugging. The left-hand expression is also computable.
- next_bootchain() - command to the daemon to change the sequence of the
  following steps.
- is_step_passed() - returns 0 if the current step has been passed at
  least once.
- launch_step_once() - if the current step has already been completed,
  it completes the work through the fatal() call.
- break_bc_loop() - informs the daemon that the current step is the last and
  after after its successful completion, you can switch to stage2. The script
  of this step, however, must work to the end and end with a zero status code
  in order for the daemon to process the received signal.
- bc_reboot() - performs a logged restart of the computer.
- bypass_results() - asks the daemon to associate the <OUT> of the previous
  step with the <IN> the next step. It is also used to inform the daemon about
  the result (mounted directory) inside the current initramfs root, outside the
  $mntdir tree.
- initrd_version() - output of the current version of make-initrd. It is proposed
  to move to make-initrd/data/bin/initrd-sh-functions after has_module().

## Examples

Cmdline: root=bootchain bootchain=waitdev,mountfs,mountfs,overlayfs,rootfs waitdev=CDROM:LABEL=ALT_regular-rescue/x86_64 mountfs=DEVNANE mountfs=rescue

Following these parameters, the daemon waits for a local device with the
ISO-9660 file system and the volume label "ALT_regular-rescue/x86_64", mounts
this media, mounts the "rescue" file from it as squashfs of the root system,
makes it writable using overlayfs and tries to boot from it.

Cmdline: root=pipeline pipeline=getimage,mountfs,overlayfs,rootfs getimage=http://ftp.altlinux.org/pub/people/mike/iso/misc/vi-20140918-i586.iso mountfs=rescue

Following these parameters, the daemon loads the image "vi-20140918-i586.iso",
mounts it via the loop device, mounts the "rescue" file from it as squashfs of
the root system, makes it writable using overlayfs and tries to boot from it.
