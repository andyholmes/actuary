# SPDX-License-Identifier: GPL-2.0-or-later
# SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>


actuary_conf = configuration_data()
actuary_conf.set('bindir', bindir)
actuary_conf.set('datadir', datadir)


# Suites
suites = [
  'test',
  'asan',
  'tsan',
  'analyzer',
  'abidiff',
  'cppcheck',
]

foreach suite : suites
  configure_file(
            input: 'suites/@0@.sh'.format(suite),
           output: suite,
    configuration: actuary_conf,
      install_dir: join_paths(datadir, meson.project_name(), 'suites'),
          install: true,
  )
endforeach


# LLVM scan-build wrapper (https://clang-analyzer.llvm.org/scan-build.html)
scanbuild_file = configure_file(
          input: '@0@-scanbuild.sh'.format(meson.project_name()),
         output: '@0@-scanbuild'.format(meson.project_name()),
  configuration: actuary_conf,
    install_dir: bindir,
        install: true,
)


# Executable
actuary = configure_file(
          input: '@0@.sh'.format(meson.project_name()),
         output: meson.project_name(),
  configuration: actuary_conf,
    install_dir: bindir,
        install: true,
)

