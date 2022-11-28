#!/bin/sh -e

# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

#
# Top-Level Environment Variables
#
ACTUARY_SUITESDIR="${ACTUARY_SUITESDIR:=@datadir@/actuary/suites}"
ACTUARY_WORKSPACE="${GITHUB_ACTUARY_WORKSPACE:=$(git rev-parse --show-toplevel)}"
ACTUARY_BUILDDIR="${ACTUARY_BUILDDIR:=$ACTUARY_WORKSPACE/_build}"


#
# Suites
#
. "${ACTUARY_SUITESDIR}/test.sh"
. "${ACTUARY_SUITESDIR}/asan.sh"
. "${ACTUARY_SUITESDIR}/tsan.sh"
. "${ACTUARY_SUITESDIR}/analyzer.sh"

. "${ACTUARY_SUITESDIR}/lcov.sh"

. "${ACTUARY_SUITESDIR}/abidiff.sh"
. "${ACTUARY_SUITESDIR}/cppcheck.sh"


#
# main
#
actuary_main() {
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

    # Compiler Profiles
    if [ "${ACTUARY_SUITE}" = "test" ]; then
        actuary_suite_test "${@}";
    elif [ "${ACTUARY_SUITE}" = "asan" ]; then
        actuary_suite_asan "${@}";
    elif [ "${ACTUARY_SUITE}" = "tsan" ]; then
        actuary_suite_tsan "${@}";
    elif [ "${ACTUARY_SUITE}" = "analyzer" ]; then
        actuary_suite_analyzer;
    elif [ "${ACTUARY_SUITE}" = "coverage" ]; then
        actuary_suite_coverage "${@}";

    # Other tools
    elif [ "${ACTUARY_SUITE}" = "abidiff" ]; then
        actuary_suite_abidiff;
    elif [ "${ACTUARY_SUITE}" = "cppcheck" ]; then
        actuary_suite_cppcheck;
    else
        echo "Unknown suite";
        exit 1;
    fi
}

actuary_main "${@}";

