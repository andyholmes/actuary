# Actuary

**An opinionated test runner for C projects**

Actuary is a test runner and GitHub Action, specifically for programs written in
C that use the `meson` build system, with an emphasis on GLib-based projects.

The basic idea is to define a number of abstract "suites" like *"run tests"* and
*"run tests while checking for leaks"* which can either be used in a GitHub
workflow (i.e. job matrix) or run locally during development.

To make local development easier, an `toolbox` image is provided with the same
setup as the CI image and `actuary` pre-installed. These image can be used as
base images for your own project, with additional dependencies and suites.

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

Actuary support passing raw arguments to the underlying tool:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `suite`                 | Test suite (default: `test`)                       |
| `setup-args`            | Options for `meson setup`                          |
| `test-args`             | Options for `meson test`                           |
| `abidiff-args`          | Options for `abidiff`                              |
| `cppcheck-args`         | Options for `cppcheck`                             |

The `setup-args` input is passed to `meson setup`, overriding any default
arguments or options.

The `test-args` input is passed to `meson test`, overriding any default
arguments or options.

The `abidiff-args` input is passed to `abidiff`, overriding any default
arguments or options. See [`abidiff`](#abidiff) for more information.

The `cppcheck-args` input is passed to `cppcheck`, overriding any default
arguments or options. See [`cppcheck`](#cppcheck) for more information.

## Outputs

There are currently no outputs

## Containers

Actuary provides containers with pre-installed packages for the included suites
and a companion `toolbox` image for local development:

| Image Name              | Version Tags              | Notes                  |
|-------------------------|---------------------------|------------------------|
| `actuary`               | `latest`, `f37`           |                        |
| `actuary-toolbox`       | `latest`, `f37`           | Includes `gdb`         |

Containers are referenced in the form `ghcr.io/andyholmes/actuary:<tag>`, such
as `ghcr.io/andyholmes/actuary:latest`:

```yml
name: Actuary

on:
  # Rebuild once a day
  schedule:
    - cron: "0 0 * * *"
  workflow_dispatch:

jobs:
  actuary:
    name: Actuary
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/andyholmes/actuary/gnome:43
      options: --privileged
```

## Suites

### test

Standard `meson test` runner.

This suite, and suites based on it, respect the following environment variables:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `setup-args`            | Options for `meson setup`                          |
| `test-args`             | Options for `meson test`                           |

### asan

Run tests with AddressSanitizer.

This suite is based on the [`test` suite](#test) and will respect any inputs it
accepts.

### tsan

Run tests with ThreadSanitizer.

This suite is based on the [`test` suite](#test) and will respect any inputs it
accepts.

### lcov

A custom lcov generator.

The `lcov` suite respects the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `lcov-include`          | Path glob of directories to include in coverage    |
| `lcov-exclude`          | Path glob of directories to exclude from coverage  |

This suite is based on the [`test` suite](#test) and will respect any inputs it
accepts.

If the `test` suite has not already been run, it will be run automatically to
generate coverage.

### analyzer

Run the compiler's static analysis tool (e.g. LLVM scan-build).

This suite is not based on the `test` suite, but will respect the `setup-args`
input.

### abidiff

Test for API breakage in changes.

This suite respects the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `abidiff-library`       | Shared Object (e.g. `libfoobar-1.0.so`)            |

This suite is will respect the `setup-args` input.

### cppcheck

Run cppcheck static analyzer

This suite respects the following inputs:

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `cppcheck-args`         | Options for `cppcheck`                             |

