# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_cppcheck() {
    # Ensure a log directory exists where it is expected
    mkdir -p "${ACTUARY_BUILDDIR}/meson-logs"

    if [ "${ACTUARY_CPPCHECK_LIBRARY}" != "" ]; then
        ACTUARY_CPPCHECK_ARGS="${ACTUARY_CPPCHECK_ARGS} --library=${ACTUARY_CPPCHECK_LIBRARY}"
    fi

    if [ "${ACTUARY_CPPCHECK_SUPPRESSIONS}" != "" ]; then
        ACTUARY_CPPCHECK_ARGS="${ACTUARY_CPPCHECK_ARGS} --suppressions-list=${ACTUARY_CPPCHECK_SUPPRESSIONS}"
    fi

    # shellcheck disable=SC2086
    cppcheck --error-exitcode=1 \
             --library=gtk \
             --quiet \
             --xml \
             ${ACTUARY_CPPCHECK_ARGS} \
             src 2> "${ACTUARY_BUILDDIR}/meson-logs/cppcheck.xml" || \
    (cppcheck-htmlreport --file "${ACTUARY_BUILDDIR}/meson-logs/cppcheck.xml" \
                         --report-dir "${ACTUARY_BUILDDIR}/meson-logs/cppcheck-html" \
                         --source-dir "${ACTUARY_WORKSPACE}" && exit 1);
}
