%define parent make-initrd
%define child  bootchain

Name: %parent-%child
Version: 0.1.0
Release: alt1

Summary: %child module for %parent
License: GPL-3.0
Group: System/Base
BuildArch: noarch

Packager: Leonid Krivoshein <klark@altlinux.org>

Requires: %parent >= 2.9
Requires: cifs-utils
Requires: console-vt-tools
Requires: curl
Requires: dialog
Requires: e2fsprogs
Requires: hostinfo
Requires: iproute2
Requires: less
Requires: losetup
Requires: nfs-utils
Requires: pv
Requires: sfdisk
Requires: termutils
Requires: util-linux

AutoReq: noshell, noshebang

Source: %name-%version.tar

%description
%child module for %parent

%prep
%setup -q

%install
mkdir -pm755 %buildroot%_datadir/%parent/features
cp -av %child %buildroot%_datadir/%parent/features/

%files
%_datadir/%parent/features/%child

%changelog
* Wed May 12 2021 Leonid Krivoshein <klark@altlinux.org> 0.1.0-alt1
- Experimental build for Sisyphus: WiP!

