# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_test_lcov() {
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "coverage=${ACTUARY_BUILDDIR}/meson-logs/coverage.info" >> $GITHUB_OUTPUT
        echo "coverage-html=${ACTUARY_BUILDDIR}/meson-logs/coverage-html" >> $GITHUB_OUTPUT
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

    if [ "${ACTUARY_LCOV_INCLUDE}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --extract "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             "${ACTUARY_LCOV_INCLUDE}" \
             --rc lcov_branch_coverage=1 \
             --output-file "${ACTUARY_BUILDDIR}/meson-logs/coverage.info"
    fi

    if [ "${ACTUARY_LCOV_EXCLUDE}" != "" ]; then
        # shellcheck disable=SC2086
        lcov --remove "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" \
             "${ACTUARY_LCOV_EXCLUDE}" \
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

actuary_suite_test() {
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "log=${ACTUARY_BUILDDIR}/meson-logs/testlog.txt" >> $GITHUB_OUTPUT
    fi

    if [ ! -d "${ACTUARY_BUILDDIR}" ]; then
        # shellcheck disable=SC2086
        meson setup -Db_coverage="${ACTUARY_TEST_COVERAGE:=false}" \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}"
    fi

    # Build
    meson compile -C "${ACTUARY_BUILDDIR}"

    # shellcheck disable=SC2086
    dbus-run-session \
        xvfb-run -d \
            meson test -C "${ACTUARY_BUILDDIR}" \
                       --print-errorlogs \
                       --repeat="${ACTUARY_TEST_REPEAT:=1}" \
                       ${ACTUARY_TEST_ARGS} \
                       "${@}"

    # Coverage Generation
    if [ "${ACTUARY_TEST_COVERAGE}" = "true" ]; then
        actuary_suite_test_lcov;
    fi
}
