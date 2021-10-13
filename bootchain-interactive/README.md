# Feature: interactive

Feature adds the ability to use dialogs in the initramfs scripts.

## Boot parameters

- `console=...` - Disable to switch TTY's, it useful for netconsole.
- `noaskuser` - Disable all input dialogs, it useful for console without user.
- `nolines` - Disable pseudo-graphics line drawing, it useful if not supported.

## Synopsis
```
. interactive-sh-functions
```

## Global variables

- `$IM_BACKTITLE` - Back title for all input and output dialogs.
- `$IM_WIDGET_ARGS` - Additional arguments for `dialog` command.
- `$CONSOLE` - Non-empty value, if switching TTY's are disabled.
- `$NOASKUSER` - Non-empty value, if input dialogs are disabled.
- `$NOLINES` - Non-empty value, if pseudo-graphics line drawing are disabled.

## Briefly API

- `IM_is_active()` - Returns 0, if interactive mode already activated.
- `IM_exec()` - Re-execute specified process on the foreground (tty2, by default).
- `IM_activate()` - Request to immediately or delayed activation of the interactive mode.
- `IM_load_widgets()` - Load specified widgets from the library.
- `IM_load_all()` - Load all available widgets from the library.
- `IM_start_output()` - Notify `interactive` feature about starting output.
- `IM_start_input()` - Notify `interactive` feature about starting intput.
- `IM_show_bootsplash()` - Show bootsplash, such as plymoth, and start progress bar.
- `IM_hide_bootsplash()` - Hide bootsplash, such as plymoth, and stop progress bar.
- `IM_update_bootsplash()` - Notify bootsplash, such as plymoth, about boot stage changes.

## Widgets library

Library is a scripts set, located in /lib/IM-widgets directory inside intitramfs iamge.
The base set can be extended. Before use input widgets, `IM_start_input()` must be called,
and `IM_start_output()` in otherwise.

### choice (input)

Display menu with one or more items, labels before items not displayed. On success returns 0
and write choosen label to specified variable. Based on `dialog --menu`.

Syntax:
```
IM_choice <varname> <text> <label1> <item1> [<label2> <item2>…]
```

Example:
```
text="Please choose the installation method."

while ! IM_choice method "$text" \
    nfs   "NFS server"      \
    ftp   "FTP server"      \
    http  "HTTP server"     \
    cifs  "SAMBA server"    \
    cdrom "CD-ROM Drive"    \
    disk  "Hard Disk Drive" \
    #
do
    sleep 0.5
done

case "$method" in
nfs)
…
esac
```

### dlgmsg (input)

Display text message. Always returns 0. Based on `dialog --msgbox`.

Syntax:
```
IM_dlgmsg <title> <text>
```

Example:
```
IM_dlgmsg "Live is success!" "$text"
```

### errmsg (input)

Display error message. Always returns 0. Based on `dialog --msgbox`.

Syntax:
```
IM_errmsg <text>
```

Example:
```
IM_errmsg "Disk read error, try again!"
```

### form (input)

Display mixed data form. Input one or more text fields and store values
to specified varibales. Some variables associated with private data,
such as password, this input field characters outputs as asterics (`*`).
On success returns 0 and fill all variables by the entered values.
Based on `dialog --mixedform`.

Syntax:
```
IM_form <title> <text> <text-height> \
    <varname1> <fldlen1> <caption1>  \
    [<varname2> <fldlen2> <caption2>…]
```

Example:
```
IM_form "$title" "$text" 5      \
    server     64 "HTTP-server" \
    directory 128 "Directory"   \
    ||
    continue
[ -n "$server" ] && [ -n "$directory" ] ||
    continue
```

### gauge (output)

Display gauge (progress bar). Integer value from 0 to 100 must be sent
via stdin to specify displayed percent of the process passed. This is work
in conjuction with pv command. Always returns 0. Based on `dialog --gauge`.

Note for `netconsole` usage: after process will finish, don't forget reset
the terminal, otherwise keyboard input will be lost.

Syntax:
```
echo <integer> | IM_gauge <title> [<text>]
```

Example:
```
( for i in $(seq 1 10); do
    echo "${i}0"
    sleep 1
  done
) | IM_gauge "[ Loading... ]"

[ -z "$CONSOLE" ] ||
    reset
```

### ponder (output)

Displays the <waiting…> widget, which displays the undefined time of the
ongoing process, works independently of the main program code. The parameters
<delay> and <step> at startup determine by how many percent the thermometer
will automatically advance after a given time, i.e. set the frequency and
speed of the widget refresh. Always returns 0. Based on the `gauge` widget.

Syntax:
```
IM_ponder_start <title> [[[<text>] <delay>] <step>]
…
IM_ponder_stop
```

Example:
```
IM_ponder_start "[ Scanning disk... ]" \
    "Searching random bits on the disk for fill CRNG entropy..."
find / -type f -print0 |
    xargs -0 grep "Linus Torvalds" >/tmp/Linus.txt 2>/dev/null
rm -f /tmp/Linus.txt
IM_ponder_stop
```
