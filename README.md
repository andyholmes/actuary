# Actuary

**An opinionated test runner for C projects**

Actuary is a test runner and GitHub Action, specifically for programs written in
C that use the `meson` build system, with an emphasis on GLib-based projects.

It's common, and wise, to run tests under various conditions (e.g. [sanitizers])
and employ static analysis tools (e.g. [cppcheck]). Actuary is really just a
series of shell scripts that makes it simpler to run a set of suites, both in a
GitHub [job matrix] and on your local workstation.

Actuary includes a CI image and a `toolbox` image, with all required tools
pre-installed, intended to be used as base images for a project.

[sanitizers]: https://github.com/google/sanitizers
[cppcheck]: https://cppcheck.sourceforge.io/
[job matrix]: https://docs.github.com/actions/using-jobs/using-a-matrix-for-your-jobs

## Complete Example

```yml
name: Actuary

on:
  pull_request:
  workflow_dispatch:

jobs:
  actuary:
    name: Actuary
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/andyholmes/actuary/gnome:43
      options: --privileged

    strategy:
      matrix:
        arch: [x86_64, aarch64]
      fail-fast: false
      # Only one job at a time can use the shared repository cache
      max-parallel: 1

    steps:
      # Checkout a repository with Flatpak manifests
      - name: Checkout
        uses: actions/checkout@v3
```

## Inputs

Actuary is really intended to be used in a job matrix, so the two driving inputs
are `suite` and `compiler`.

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `suite`                 | Test suite (default: `test`)                       |
| `compiler`              | Compiler (default: system)                         |

The `suite` input determines which test suite will be run. Additional suites can
be added to `/usr/share/actuary/suites/`.

The `compiler` input determines which compiler to use. Actuary includes two
presets (`gcc` and `llvm`), but will fallback to the system default if not set.

### test

Standard `meson test` runner.

This suite, and suites based on it, respect the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `setup-args`            | Options for `meson setup`                          |
| `test-args`             | Options for `meson test`                           |
| `test-coverage`         | Enable or disable coverage generation              |
| `lcov-include`          | Path glob of directories to include in coverage    |
| `lcov-exclude`          | Path glob of directories to exclude from coverage  |

The `setup-args` input is passed to `meson setup`, overriding any default
arguments or options.

The `test-args` input is passed to `meson test`, overriding any default
arguments or options.

The `test-coverage` input enables coverage generation with [LCOV], and will
result in an LCOV `.info` file and an HTML report.

This suite, and suites based on it, generate the following outputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `log`                   | Path to `testlog.txt` file (`meson test`)          |
| `coverage`              | Path to `coverage.info` file (LCOV)                |
| `coverage-html`         | Path to `coverage-html` directory (HTML)           |

[lcov]: https://github.com/linux-test-project/lcov

### asan

Run tests with AddressSanitizer.

This suite is based on the [`test` suite](#test) and will respect any inputs it
accepts.

### tsan

Run tests with ThreadSanitizer.

This suite is based on the [`test` suite](#test) and will respect any inputs it
accepts.

### analyzer

Run the compiler's static analysis tool (e.g. LLVM scan-build).

This suite is not based on the `test` suite, but will respect the `setup-args`
input.

### abidiff

Test for API breakage in changes.

This suite respects the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `abidiff-args`          | Options for `abidiff`                              |
| `abidiff-lib`           | Shared Object (e.g. `libfoobar-1.0.so`)            |

This suite is will respect the `setup-args` input.

### cppcheck

Run cppcheck static analyzer

This suite respects the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `cppcheck-args`         | Options for `cppcheck`                             |
| `cppcheck-path`         | Path to the source directory                       |

## Outputs

There are currently no outputs

## Containers

Actuary provides containers with pre-installed packages for the included suites
and a companion `toolbox` image for local development.

| Image Name              | Notes                                              |
|-------------------------|----------------------------------------------------|
| `actuary`               |                                                    |
| `actuary-toolbox`       | Includes `gdb`                                     |

Most projects will want to include additional build dependencies, which can be
done by adding a stage on top of Actuary's base images:

```dockerfile
FROM ghcr.io/andyholmes/actuary:latest

RUN dnf install -y --enablerepo=fedora-debuginfo,updates-debuginfo \
        gi-docgen graphviz \
        glib2-devel      glib2-debuginfo \
        gtk4-devel       gtk4-debuginfo \
        libadwaita-devel libadwaita-debuginfo && \
    dnf clean all && rm -rf /var/cache/dnf
```

You can copy-paste the [`cr.yml`][cr] workflow from Actuary to build and push
the image to your project's container registry. Then use your project's CI image
with Actuary:

```yml
name: Continuous Integration
on:
  pull_request:

jobs:
  actuary:
    name: Actuary
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/username/project:latest

    steps:
      - name: Test
        uses: andyholmes/actuary@main
        with:
          suite: test
          setup-args: -Dtests=true
```

[cr]: https://github.com/andyholmes/actuary/blob/main/.github/workflows/cr.yml
