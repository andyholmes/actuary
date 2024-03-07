# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

# shellcheck source=/dev/null
. "${ACTUARY_SUITESDIR}/test"


actuary_suite_asan() {
    ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_sanitize=address,undefined"
    ACTUARY_TEST_ARGS="${ACTUARY_TEST_ARGS} --timeout-multiplier=3"

    # Clang needs `-Db_lundef=false` to use sanitizers
    if [ "${CC}" = "clang" ]; then
        ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_lundef=false"
    fi

    # Chain-up to the test profile
    actuary_suite_test "${@}" || SANITIZER_ERROR=$?

    if [ "${SANITIZER_ERROR:=0}" -ne 0 ]; then
        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            echo "### AddressSanitizer" >> "${GITHUB_STEP_SUMMARY}";
            echo "\`\`\`c" >> "${GITHUB_STEP_SUMMARY}";
            awk '/(Leak|Address)Sanitizer/,/SUMMARY/' \
                "${ACTUARY_BUILDDIR}/meson-logs/testlog.txt" >> \
                "${GITHUB_STEP_SUMMARY}";
            echo "\`\`\`" >> "${GITHUB_STEP_SUMMARY}";
        fi

        return "${SANITIZER_ERROR}";
    fi
}
