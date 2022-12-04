# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: 2021 Andy Holmes <andrew.g.r.holmes@gmail.com>

project('actuary', 'c',
          license: 'GPL-2.0-or-later',
          version: '0.1.0',
    meson_version: '>= 0.59.0',
)


prefix = get_option('prefix')
bindir = join_paths(prefix, get_option('bindir'))
datadir = join_paths(prefix, get_option('datadir'))


subdir('src')

