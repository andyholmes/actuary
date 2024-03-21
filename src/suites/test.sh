# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_test_lcov() {
    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "coverage=${ACTUARY_BUILDDIR}/meson-logs/coverage.info" >> "${GITHUB_OUTPUT}"
        echo "coverage-html=${ACTUARY_BUILDDIR}/meson-logs/coverage-html" >> "${GITHUB_OUTPUT}"
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
    BADGE_CLR="red"
    BADGE_PCT=$(lcov --summary "${ACTUARY_BUILDDIR}/meson-logs/coverage.info" | \
            grep -oP '.*lines.*: \K[0-9\.]+' | xargs printf "%.*f\n" "0");

    if [ "$BADGE_PCT" -ge "90" ]; then
        BADGE_CLR="green"
    elif [ "$BADGE_PCT" -ge "75" ]; then
        BADGE_CLR="yellow"
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
                       "${@}" || TEST_ERROR=$?

    if [ "${TEST_ERROR:=0}" -ne 0 ]; then
        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            echo "### Test Summary" >> "${GITHUB_STEP_SUMMARY}";
            echo "\`\`\`c" >> "${GITHUB_STEP_SUMMARY}";
            awk '/^(Summary of Failures:|Ok:)/ { flag = 1 } /Timeout:/ { flag = 0 } flag' \
                "${ACTUARY_BUILDDIR}/meson-logs/testlog.txt" >> \
                "${GITHUB_STEP_SUMMARY}";
            echo "\`\`\`" >> "${GITHUB_STEP_SUMMARY}";
        fi

        return "${TEST_ERROR}";
    fi

    # Coverage Generation
    if [ "${ACTUARY_TEST_COVERAGE}" = "true" ]; then
        actuary_suite_test_lcov;
    fi
}
