# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuarysuite_analyzer() {
    # GCC analyzer
    if [ "${CC}" = "gcc" ]; then
        export CFLAGS="${CFLAGS} -fanalyzer"

        # shellcheck disable=SC2086
        meson setup --buildtype="${ACTUARY_SETUP_BUILDTYPE:=debug}" \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" &&
        meson compile -C "${ACTUARY_BUILDDIR}"

    # clang-analyzer
    elif [ "${CC}" = "clang" ]; then
        export SCANBUILD="actuary-scanbuild"

        # shellcheck disable=SC2086
        meson setup --buildtype="${ACTUARY_SETUP_BUILDTYPE:=debug}" \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" &&
        ninja -C "${ACTUARY_BUILDDIR}" scan-build
    fi
}
