# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_test() {
    if [ ! -d "${ACTUARY_BUILDDIR}" ]; then
        # shellcheck disable=SC2086
        meson setup -Db_coverage="${ACTUARY_SETUP_COVERAGE:=false}" \
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
                       --timeout-multiplier="${ACTUARY_TEST_TIMEOUT_MULTIPLIER:=1}" \
                       ${ACTUARY_TEST_ARGS} \
                       "${@}"
}
