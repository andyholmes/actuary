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
        meson compile -C "${ACTUARY_BUILDDIR}" > \
            "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" || ANALYZER_ERROR=true

        if [ "${ANALYZER_ERROR}" = "true" ]; then
            ANALYZER_OUTPUT=$(cat "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log")

            if [ "${GITHUB_ACTIONS}" = "true" ]; then
                echo "### GCC Analyzer" >> "${GITHUB_STEP_SUMMARY}";
                echo "\`\`\`c" >> "${GITHUB_STEP_SUMMARY}";
                echo "${ANALYZER_OUTPUT}" >> "${GITHUB_STEP_SUMMARY}";
                echo "\`\`\`" >> "${GITHUB_STEP_SUMMARY}";

                echo "log=${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" >> "${GITHUB_OUTPUT}"
            fi

            echo "${ANALYZER_OUTPUT}" && exit 1;
        fi

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
