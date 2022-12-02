# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: 2021 Andy Holmes <andrew.g.r.holmes@gmail.com>

project('actuary', 'c',
          license: 'GPL-2.0-or-later',
          version: '0.1.0',
    meson_version: '>= 0.59.0',
)


#
# Versioning
#
version_split = meson.project_version().split('.')
MAJOR_VERSION = version_split[0].to_int()
MINOR_VERSION = version_split[1].to_int()
MICRO_VERSION = version_split[2].to_int()

actuary_version = '@0@.@1@.@2@'.format(MAJOR_VERSION, MINOR_VERSION, MICRO_VERSION)
actuary_api_version = '@0@.@1@'.format(MAJOR_VERSION, MINOR_VERSION)
actuary_api_name = 'actuary-@0@'.format(actuary_api_version)


#
# Paths
#
prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))
libdir = join_paths(prefix, get_option('libdir'))
libexecdir = join_paths(prefix, get_option('libexecdir'))

pkgdatadir = join_paths(datadir, meson.project_name())
pkglibdir = join_paths(libdir, meson.project_name())
pkglibexecdir = join_paths(libexecdir, meson.project_name())


#
# Build
#
subdir('src')

