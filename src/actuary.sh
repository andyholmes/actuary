#!/bin/sh -e

# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

ACTUARY_SUITESDIR="${ACTUARY_SUITESDIR:=@datadir@/actuary/suites}"
ACTUARY_WORKSPACE="${GITHUB_WORKSPACE:=$(git rev-parse --show-toplevel)}"
ACTUARY_BUILDDIR="${ACTUARY_BUILDDIR:=$ACTUARY_WORKSPACE/_build}"


# Check that the requested suite exists
if [ ! -e "${ACTUARY_SUITESDIR}/${ACTUARY_SUITE}" ]; then
    echo "Failed to find suite '${ACTUARY_SUITE}'";
    exit 127;
fi

# Configure the compiler collection, if provided
if [ "${ACTUARY_COMPILER}" = "gcc" ]; then
    export CC=gcc
    export CC_LD=bfd
    export CXX=g++
    export CXX_LD=bfd
elif [ "${ACTUARY_COMPILER}" = "llvm" ]; then
    export CC=clang
    export CC_LD=lld
    export CXX=clang++
    export CXX_LD=lld
fi


# shellcheck source=/dev/null
. "${ACTUARY_SUITESDIR}/${ACTUARY_SUITE}"
"actuary_suite_${ACTUARY_SUITE}" "${@}"

