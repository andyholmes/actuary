# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved
# ACTUARY-Type: suite
# ACTUARY-Depends: test

#
# SUITE: coverage
#
# A custom lcov generator.
#
# If $ACTUARY_BUILDDIR does not exist, `actuarysuite_test()` will be called and relayed
# any arguments passed to the function.
#
# The coverage phase respects the following environment variables:
#
# | Variable                           | lcov                                |
# |------------------------------------|-------------------------------------|
# | ACTUARY_LCOV_INCLUDE_PATH               | path glob to include                |
# | ACTUARY_LCOV_EXCLUDE_PATH               | path glob to exclude                |
#
actuarysuite_coverage() {
    if [ ! -d "${ACTUARY_BUILDDIR}" ]; then
        ACTUARY_SETUP_COVERAGE=true
        actuarysuite_test "${@}"
    fi

    lcov --directory "${ACTUARY_BUILDDIR}" \
         --capture \
         --initial \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.p1" && \
    lcov --directory "${ACTUARY_BUILDDIR}" \
         --capture \
         --no-checksum \
         --rc lcov_branch_coverage=1 \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.p2" && \
    lcov --add-tracefile "${ACTUARY_BUILDDIR}/meson-logs/coverage.p1" \
         --add-tracefile "${ACTUARY_BUILDDIR}/meson-logs/coverage.p2" \
         --rc lcov_branch_coverage=1 \
         --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"

    if [ "${ACTUARY_LCOV_INCLUDE_PATH}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --extract "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             "${ACTUARY_LCOV_INCLUDE_PATH}" \
             --rc lcov_branch_coverage=1 \
             --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
    fi

    if [ "${ACTUARY_LCOV_EXCLUDE_PATH}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --remove "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             "${ACTUARY_LCOV_EXCLUDE_PATH}" \
             --rc lcov_branch_coverage=1 \
             --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
    fi

    genhtml --prefix "${ACTUARY_WORKSPACE}" \
            --output-directory "${ACTUARY_BUILDDIR}/meson-logs/coverage-html" \
            --title 'Code Coverage' \
            --legend \
            --show-details \
            --branch-coverage \
            "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
}
