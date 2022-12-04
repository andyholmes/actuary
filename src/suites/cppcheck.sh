# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


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
