# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>


# Suites
install_subdir('suites',
  install_dir: pkgdatadir,
)


# LLVM scan-build wrapper:
# See: https://clang-analyzer.llvm.org/scan-build.html
scanbuild_conf = configuration_data()
scanbuild_conf.set('datadir', datadir)
scanbuild_file = configure_file(
          input: '@0@-scanbuild.sh'.format(meson.project_name()),
         output: '@0@-scanbuild'.format(meson.project_name()),
  configuration: scanbuild_conf,
    install_dir: bindir,
        install: true,
)


# Exectuable
exec_conf = configuration_data()
exec_conf.set('datadir', datadir)
exec_file = configure_file(
          input: '@0@.sh'.format(meson.project_name()),
         output: meson.project_name(),
  configuration: exec_conf,
    install_dir: bindir,
        install: true,
)
