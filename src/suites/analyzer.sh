# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_analyzer() {
    # GCC analyzer
    if [ "${CC}" = "gcc" ]; then
        export CFLAGS="${CFLAGS} -fanalyzer"

        # shellcheck disable=SC2086
        meson setup --buildtype=debug \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" && \
        meson compile -C "${ACTUARY_BUILDDIR}"

    # clang-analyzer
    elif [ "${CC}" = "clang" ]; then
        export SCANBUILD="@bindir@/actuary-scanbuild"

        # shellcheck disable=SC2086
        meson setup --buildtype=debug \
                    ${ACTUARY_SETUP_ARGS} \
                    "${ACTUARY_BUILDDIR}" && \
        ninja -C "${ACTUARY_BUILDDIR}" scan-build

        if [ "${GITHUB_ACTIONS}" = "true" ]; then
            echo "log=${ACTUARY_BUILDDIR}/meson-logs/scanbuild" >> "${GITHUB_OUTPUT}"
        fi
    fi
}
