# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

FROM registry.fedoraproject.org/fedora:37

# The packages below are roughly grouped into build tooling and test tooling.
RUN dnf install -y --enablerepo=fedora-debuginfo,updates-debuginfo \
        --setopt=install_weak_deps=False \
        glibc-langpack-en glibc-locale-source clang clang-analyzer compiler-rt \
        cppcheck cppcheck-htmlreport gcc gettext git libabigail libasan \
        libtsan libubsan lld llvm meson \
        appstream desktop-file-utils dbus-daemon lcov python-dbusmock \
        xorg-x11-server-Xvfb && \
    dnf clean all && rm -rf /var/cache/dnf

COPY src/actuary.sh /usr/bin/actuary
RUN chmod a+x /usr/bin/actuary
