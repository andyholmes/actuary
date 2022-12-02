# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

. "${ACTUARY_SUITESDIR}/test.sh"


actuary_suite_lcov() {
    if [ ! -d "${ACTUARY_BUILDDIR}" ]; then
        ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_coverage=true"
        actuary_suite_test "${@}"
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
