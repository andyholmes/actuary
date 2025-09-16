# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>


actuary_conf = configuration_data()
actuary_conf.set('bindir', bindir)
actuary_conf.set('datadir', datadir)

# LLVM scan-build wrapper (https://clang-analyzer.llvm.org/scan-build.html)
scanbuild_file = configure_file(
          input: '@0@-scanbuild.sh'.format(meson.project_name()),
         output: '@0@-scanbuild'.format(meson.project_name()),
  configuration: actuary_conf,
    install_dir: bindir,
        install: true,
)

# Runner
actuary_runner = configure_file(
          input: '@0@-runner.sh'.format(meson.project_name()),
         output: '@0@-runner'.format(meson.project_name()),
  configuration: actuary_conf,
    install_dir: bindir,
        install: true,
)

