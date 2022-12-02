# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

FROM registry.fedoraproject.org/fedora:37

# The packages below are roughly grouped into three groups: build tooling, test
# tooling and packages needed for GitHub Actions.
#
# See: https://github.com/andyholmes/copr/tree/main/glib2
RUN dnf install -y 'dnf-command(copr)' && \
    dnf copr -y enable andyholmes/main && \
    dnf install -y --enablerepo=fedora-debuginfo,updates-debuginfo \
        --setopt=install_weak_deps=False \
        clang clang-analyzer compiler-rt cppcheck cppcheck-htmlreport gcc \
        gettext git libabigail libasan libtsan libubsan lld llvm meson \
        appstream desktop-file-utils dbus-daemon lcov python-dbusmock \
        xorg-x11-server-Xvfb \
        glib2-devel glib2-debuginfo rsync && \
    dnf clean all && rm -rf /var/cache/dnf
    
# Install test runner
RUN git clone https://github.com/andyholmes/actuary.git \
              --branch main \
              --single-branch && \
    cd actuary && \
    meson setup --prefix=/usr \
                _build && \
    meson install -C _build
