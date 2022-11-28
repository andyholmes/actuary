# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved
# ACTUARY-Type: suite
# ACTUARY-Depends: test

. "${ACTUARY_SUITESDIR}/test.sh"


actuary_suite_asan() {
    ACTUARY_SETUP_SANITIZE="address,undefined"
    ACTUARY_TEST_TIMEOUT_MULTIPLIER="${ACTUARY_TEST_TIMEOUT_MULTIPLIER:=3}"

    # Clang needs `-Db_lundef=false` to use sanitizers
    if [ "${CC}" = "clang" ]; then
        ACTUARY_SETUP_ARGS="${ACTUARY_SETUP_ARGS} -Db_lundef=false"
    fi

    # Chain-up to the test profile
    actuary_suite_test "${@}"
}
