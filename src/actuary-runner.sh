#!/bin/sh -e

# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

ACTUARY_WORKSPACE="${GITHUB_WORKSPACE:-$(git rev-parse --show-toplevel)}"
ACTUARY_BUILDDIR="${ACTUARY_BUILDDIR:-$ACTUARY_WORKSPACE/_build}"

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

#
# LCOV Code Coverage
#
actuary_suite_test_lcov() {
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        {
            echo "coverage=${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
            echo "coverage-html=${ACTUARY_BUILDDIR}/meson-logs/coverage-html"
        } >> "${GITHUB_OUTPUT}"
    fi

    lcov --directory "${ACTUARY_BUILDDIR}" \
         --capture \
         --initial \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.p1" && \
    lcov --directory "${ACTUARY_BUILDDIR}" \
         --capture \
         --no-checksum \
         --rc branch_coverage=1 \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.p2" && \
    lcov --add-tracefile "${ACTUARY_BUILDDIR}/meson-logs/coverage.p1" \
         --add-tracefile "${ACTUARY_BUILDDIR}/meson-logs/coverage.p2" \
         --rc branch_coverage=1 \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"

    if [ "${ACTUARY_LCOV_INCLUDE}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --extract "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             ${ACTUARY_LCOV_INCLUDE} \
             --rc branch_coverage=1 \
             --ignore-errors unused \
             --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
    fi

    if [ "${ACTUARY_LCOV_EXCLUDE}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --remove "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             "${ACTUARY_LCOV_EXCLUDE}" \
             --rc branch_coverage=1 \
             --ignore-errors unused \
             --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
    fi

    genhtml --prefix "${ACTUARY_WORKSPACE}" \
            --output-directory "${ACTUARY_BUILDDIR}/meson-logs/coverage-html" \
            --title 'Code Coverage' \
            --legend \
            --show-details \
            --branch-coverage \
            "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"

    # Generate a coverage badge
    BADGE_PCT=$(lcov --summary "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" | \
            grep -oP '.*lines.*: \K[0-9\.]+' | xargs printf "%.*f\n" "0");

    if [ "$BADGE_PCT" -ge "90" ]; then
        BADGE_CLR="green"
    elif [ "$BADGE_PCT" -ge "75" ]; then
        BADGE_CLR="yellow"
    else
        BADGE_CLR="red"
    fi

    curl --output "${ACTUARY_BUILDDIR}/meson-logs/coverage-html/badge.svg" \
         "https://img.shields.io/badge/coverage-${BADGE_PCT}%25-${BADGE_CLR}.svg";
}

actuary_suite_test() {
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "log=${ACTUARY_BUILDDIR}/meson-logs/testlog.txt" >> "${GITHUB_OUTPUT}"
    fi

    if [ ! -d "${ACTUARY_BUILDDIR}" ]; then
        # shellcheck disable=SC2086
        meson setup -Db_coverage="${ACTUARY_TEST_COVERAGE:-false}" \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}"
    fi

    # Build
    meson compile -C "${ACTUARY_BUILDDIR}"

    if [ "${ACTUARY_TEST_SUITE}" = "tsan" ]; then
        OLD_LIBRARY_PATH="${LD_LIBRARY_PATH}"
        export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:/usr/tsan/lib64"
    fi

    # shellcheck disable=SC2086
    dbus-run-session \
        xvfb-run -d \
            meson test -C "${ACTUARY_BUILDDIR}" \
                       --print-errorlogs \
                       --repeat="${ACTUARY_TEST_REPEAT:-1}" \
                       ${ACTUARY_TEST_ARGS} \
                       "${@}" || TEST_ERROR=$?

    if [ "${ACTUARY_TEST_SUITE}" = "tsan" ]; then
        export LD_LIBRARY_PATH="${OLD_LIBRARY_PATH}:/usr/tsan/lib64"
    fi

    if [ "${TEST_ERROR:-0}" -ne 0 ]; then
        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            {
                echo "### Test Summary"
                echo "\`\`\`c"
                awk '/^(Summary of Failures:|Ok:)/ { flag = 1 } /Timeout:/ { flag = 0 } flag' \
                    "${ACTUARY_BUILDDIR}/meson-logs/testlog.txt"
                echo "\`\`\`"
            } >> "${GITHUB_STEP_SUMMARY}"
        fi

        return "${TEST_ERROR}";
    fi

    # Coverage Generation
    if [ "${ACTUARY_TEST_COVERAGE}" = "true" ]; then
        actuary_suite_test_lcov;
    fi
}

################################################################################
# Sanitizers                                                                   #
################################################################################

actuary_suite_asan() {
    ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_sanitize=address,undefined"
    ACTUARY_TEST_ARGS="${ACTUARY_TEST_ARGS} --timeout-multiplier=3"

    # Clang needs `-Db_lundef=false` to use sanitizers
    if [ "${CC}" = "clang" ]; then
        ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_lundef=false"
    fi

    # Chain-up to the test profile
    actuary_suite_test "${@}" || TEST_ERROR=$?

    if [ "${TEST_ERROR:-0}" -ne 0 ]; then
        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            {
                echo "### AddressSanitizer"
                echo "\`\`\`c"
                awk '/(Leak|Address)Sanitizer/,/SUMMARY/' \
                    "${ACTUARY_BUILDDIR}/meson-logs/testlog.txt"
                echo "\`\`\`"
            } >> "${GITHUB_STEP_SUMMARY}"
        fi

        return "${TEST_ERROR}";
    fi
}

actuary_suite_tsan() {
    ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_sanitize=thread"
    ACTUARY_TEST_ARGS="${ACTUARY_TEST_ARGS} --timeout-multiplier=3"

    # Clang needs `-Db_lundef=false` to use sanitizers
    if [ "${CC}" = "clang" ]; then
        ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_lundef=false"
    fi

    # Chain-up to the test profile
    actuary_suite_test "${@}" || TEST_ERROR=$?

    if [ "${TEST_ERROR:-0}" -ne 0 ]; then
        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            {
                echo "### ThreadSanitizer"
                echo "\`\`\`c"
                awk '/ThreadSanitizer/,/SUMMARY/' \
                    "${ACTUARY_BUILDDIR}/meson-logs/testlog.txt"
                echo "\`\`\`"
            } >> "${GITHUB_STEP_SUMMARY}"
        fi

        return "${TEST_ERROR}";
    fi
}

################################################################################
# Static Analysis                                                              #
################################################################################

actuary_suite_analyzer() {
    # GCC analyzer
    if [ "${CC}" = "gcc" ]; then
        export CFLAGS="${CFLAGS} -fanalyzer"

        # shellcheck disable=SC2086
        meson setup --buildtype=debug \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" && \
        meson compile -C "${ACTUARY_BUILDDIR}" > \
            "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" || TEST_ERROR=$?

        if [ "${TEST_ERROR:-0}" -ne 0 ]; then
            ANALYZER_OUTPUT=$(cat "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log")

            if [ "${GITHUB_ACTIONS}" = "true" ]; then
                {
                    echo "### GCC Analyzer"
                    echo "\`\`\`c"
                    echo "${ANALYZER_OUTPUT}"
                    echo "\`\`\`"
                } >> "${GITHUB_STEP_SUMMARY}"
                echo "log=${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" >> "${GITHUB_OUTPUT}"
            fi

            echo "${ANALYZER_OUTPUT}" && exit 1;
        fi

    # clang-analyzer
    elif [ "${CC}" = "clang" ]; then
        export SCANBUILD="@bindir@/actuary-scanbuild"

        # shellcheck disable=SC2086
        meson setup --buildtype=debug \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" && \
        ninja -C "${ACTUARY_BUILDDIR}" scan-build > \
            "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" || TEST_ERROR=$?

        if [ "${TEST_ERROR:-0}" -ne 0 ]; then
            if [ "${GITHUB_ACTIONS}" = "true" ]; then
                {
                    echo "### LLVM Analyzer"
                    echo "\`\`\`c"
                    awk '/warning:/{print prev_line "\n" $0} {if ($0 ~ /^\[[0-9]+\/[0-9]+\]/) {prev_line = $0} else {prev_line = prev_line "\n" $0}}' \
                        "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log"
                    echo "\`\`\`"
                } >> "${GITHUB_STEP_SUMMARY}"
                echo "log=${ACTUARY_BUILDDIR}/meson-logs/scanbuild" >> "${GITHUB_OUTPUT}"
            fi

            cat "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log"
            return "${TEST_ERROR}";
        fi
    fi
}

actuary_suite_cppcheck() {
    # Ensure a log directory exists where it is expected
    mkdir -p "${ACTUARY_BUILDDIR}/meson-logs"

    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        # shellcheck disable=SC2086
        cppcheck --error-exitcode=1 \
                 --library=gtk \
                 --quiet \
                 --template="::{severity} file={file},line={line},col={column}::{message}" \
                 ${ACTUARY_CPPCHECK_ARGS} \
                 ${ACTUARY_CPPCHECK_PATH};
    else
        # shellcheck disable=SC2086
        cppcheck --error-exitcode=1 \
                 --library=gtk \
                 --quiet \
                 --xml \
                 ${ACTUARY_CPPCHECK_ARGS} \
                 ${ACTUARY_CPPCHECK_PATH} 2> "${ACTUARY_BUILDDIR}/meson-logs/cppcheck.xml" || \
        (cppcheck-htmlreport --file "${ACTUARY_BUILDDIR}/meson-logs/cppcheck.xml" \
                             --report-dir "${ACTUARY_BUILDDIR}/meson-logs/cppcheck-html" \
                             --source-dir "${ACTUARY_WORKSPACE}" && exit 1);
    fi
}

################################################################################
# Static Analysis                                                              #
################################################################################

actuary_suite_abidiff_build() {
    TARGET_REF="${1}"
    TARGET_DIR="${2}"

    git fetch origin "${TARGET_REF}" && \
    git checkout "${TARGET_REF}"

    BUILDSUBDIR="${ACTUARY_BUILDDIR}/$(git rev-parse "${TARGET_REF}")"

    if [ ! -d "${BUILDSUBDIR}" ]; then
        # shellcheck disable=SC2086
        meson setup --buildtype="${ACTUARY_SETUP_BUILDTYPE:-release}" \
                    --prefix=/usr \
                    --libdir=lib \
                    ${ACTUARY_SETUP_ARGS} \
                    "${BUILDSUBDIR}"
    fi

    meson compile -C "${BUILDSUBDIR}" && \
    DESTDIR="${TARGET_DIR}" meson install -C "${BUILDSUBDIR}"
}

actuary_suite_abidiff() {
    # See: CVE-2022-24765
    git config --global --add safe.directory "${ACTUARY_WORKSPACE}"

    # Ensure a log directory exists where it is expected
    mkdir -p "${ACTUARY_BUILDDIR}/meson-logs"

    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "log=${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" >> "${GITHUB_OUTPUT}"

        BASE_REF="${GITHUB_BASE_REF}"
        HEAD_REF="${GITHUB_HEAD_REF}"
    else
        BASE_REF="main"
        HEAD_REF=$(git rev-parse HEAD)
    fi

    BASE_DIR="${ACTUARY_BUILDDIR}/_base"
    HEAD_DIR="${ACTUARY_BUILDDIR}/_head"

    actuary_suite_abidiff_build "${BASE_REF}" "${BASE_DIR}" > /dev/null 2>&1
    actuary_suite_abidiff_build "${HEAD_REF}" "${HEAD_DIR}" > /dev/null 2>&1

    # Run `abidiff`
    abidiff --drop-private-types \
            --fail-no-debug-info \
            --headers-dir1 "${BASE_DIR}/usr/include" \
            --headers-dir2 "${HEAD_DIR}/usr/include" \
            "${BASE_DIR}/usr/lib/${ACTUARY_ABIDIFF_LIB}" \
            "${HEAD_DIR}/usr/lib/${ACTUARY_ABIDIFF_LIB}" > \
            "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" || TEST_ERROR=$?

    if [ "${TEST_ERROR:-0}" -ne 0 ]; then
        ABIDIFF_OUTPUT=$(cat "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log")

        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            {
                echo "### ABI Compliance"
                echo "\`\`\`"
                echo "${ABIDIFF_OUTPUT}"
                echo "\`\`\`"
            } >> "${GITHUB_STEP_SUMMARY}"
        fi

        echo "${ABIDIFF_OUTPUT}" && exit 1;
    fi
}

#
# Runner
#
case "${ACTUARY_SUITE}" in
    "test")
        actuary_suite_test "${@}"
    ;;

    "asan")
        actuary_suite_asan "${@}"
    ;;

    "tsan")
        actuary_suite_tsan "${@}"
    ;;

    "analyzer")
        actuary_suite_analyzer "${@}"
    ;;

    "cppcheck")
        actuary_suite_cppcheck "${@}"
    ;;

    "abidiff")
        actuary_suite_abidiff "${@}"
    ;;

    --)
        echo "Unknown suite '${ACTUARY_SUITE}'"
        exit 1
    ;;
esac
