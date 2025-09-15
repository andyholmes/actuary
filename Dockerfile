# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

FROM registry.fedoraproject.org/fedora:43

RUN dnf install -y \
        --enablerepo=fedora-debuginfo,updates-debuginfo \
        --disablerepo=updates-testing,updates-testing-debuginfo \
        --setopt=install_weak_deps=False \
        clang clang-analyzer clang-tools-extra compiler-rt cppcheck \
        cppcheck-htmlreport gcc gdb gettext git libabigail libasan libtsan \
        libubsan lld llvm meson mold appstream desktop-file-utils dbus-daemon \
        lcov gnome-desktop-testing python-dbusmock xwayland-run awk rsync && \
    dnf install -y 'dnf-command(builddep)' && \
    dnf builddep -y glib glib-networking && \
    dnf clean all && rm -rf /var/cache/dnf

# Instrument libraries for ThreadSanitizer
RUN git clone https://gitlab.gnome.org/GNOME/glib.git \
              --branch glib-2-86 \
              --single-branch && \
    cd glib && \
    meson setup --prefix=/usr/tsan \
                --libdir=lib64/ \
                -Db_sanitize=thread \
                -Dintrospection=disabled \
                -Dtests=false \
                -Dwerror=false \
                _build && \
    meson install -C _build

RUN git clone https://gitlab.gnome.org/GNOME/glib-networking.git \
              --branch master \
              --single-branch && \
    cd glib-networking && \
    meson setup --prefix=/usr/tsan \
                --libdir=lib64/ \
                -Db_sanitize=thread \
                -Dwerror=false \
                _build && \
    meson install -C _build
    
# Install test runner
RUN git clone https://github.com/andyholmes/actuary.git \
              --branch main \
              --single-branch && \
    cd actuary && \
    meson setup --prefix=/usr \
                _build && \
    meson install -C _build
