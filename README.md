# Actuary

**An opinionated test runner for C projects**

Actuary is a test runner and GitHub Action, specifically for programs written in
C that use the `meson` build system, with an emphasis on GLib-based projects.

The general idea is to create abstract tasks like "run tests", "run tests while
checking for leaks", "run static analyis for unsafe memory use" and so on. These
can then be used in a GitHub workflow (i.e. job matrix) or run independently.


## Table of Contents

* [Complete Example](#complete-example)
* [Inputs](#inputs)
  * [Deployment Options](#deployment-options)
  * [Advanced Options](#advanced-options)
* [Outputs](#outputs)
* [Containers](#containers)
* [GPG Signing](#gpg-signing)
* [Deployment](#deployment)
  * [Flatpak Bundles](#flatpak-bundles)
  * [GitHub Pages](#github-pages)
  * [Custom Deploy](#custom-deploy)
* [Multiple Architectures](#multiple-architectures)

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

The only required input is `files`, which should be a list of paths to Flatpak
manifests (JSON or YAML) to build.

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `setup-args`            | Options for `meson setup`                          |
| `setup-args`            | Options for `meson test`                           |
| `test-args`             | The architecture to build for                      |
| `gpg-sign`              | A GPG Key fingerprint                              |
| `cache-key`             | A cache key, or `''` to disable                    |

The `files` input may be either a single-line or multi-line string value:

```yml
# One manifest
files: one.manifestFile.json

# One or more manifests
files: |
  one.manifest.File.json
  two.manifest.File.yml
```

The `arch` input must be set if building for a non-`x86-64` architecture, like
`aarch64`. See [Multiple Architectures](#multiple-architectures) for more
information.

The `gpg-sign` input corresponds to the `--gpg-sign` command-line option and
should be a GPG key fingerprint. See [GPG Signing](#gpg-signing) for more
information.

The `cache-key` input is used as a base to generate cache keys for the
repository and build directories. The key can be rotated if the repository
becomes too large or needs to be reset for some other reason.

## Outputs

The only output is `repository`, currently.

| Name                    | Description                                        |
|-------------------------|----------------------------------------------------|
| `repository`            | Absolute path to the Flatpak repository            |

The `repository` output is an absolute path to the repository directory,
corresponding to the `--repo` command-line option.

## Containers

Actuary provides containers with pre-installed packages for the included suites
and a companion `toolbox` image for local development:

| Image Name            | Version Tags              | Notes                    |
|-----------------------|---------------------------|--------------------------|
| `actuary`             | `latest`, `f37`           |                          |
| `actuary-toolbox`     | `latest`, `f37`           | Includes `gdb`           |

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

