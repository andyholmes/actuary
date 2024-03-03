# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

FROM registry.fedoraproject.org/fedora:39

RUN dnf install -y \
        --enablerepo=fedora-debuginfo,updates-debuginfo \
        --disablerepo=updates-testing,updates-testing-debuginfo \
        --setopt=install_weak_deps=False \
        clang clang-analyzer clang-tools-extra compiler-rt cppcheck \
        cppcheck-htmlreport gcc gdb gettext git libabigail libasan libtsan \
        libubsan lld llvm meson mold appstream desktop-file-utils dbus-daemon \
        lcov gnome-desktop-testing python-dbusmock xorg-x11-server-Xvfb rsync && \
    dnf clean all && rm -rf /var/cache/dnf
    
# Install test runner
RUN git clone https://github.com/andyholmes/actuary.git \
              --branch main \
              --single-branch && \
    cd actuary && \
    meson setup --prefix=/usr \
                _build && \
    meson install -C _build
