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
        ninja -C "${ACTUARY_BUILDDIR}" scan-build > \
            "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" || ANALYZER_ERROR=$?

        if [ "${ANALYZER_ERROR:=0}" -ne 0 ]; then
            echo "log=${ACTUARY_BUILDDIR}/meson-logs/scanbuild" >> "${GITHUB_OUTPUT}"

            if [ "${GITHUB_ACTIONS}" = "true" ]; then
                echo "### LLVM Analyzer" >> "${GITHUB_STEP_SUMMARY}";
                echo "\`\`\`c" >> "${GITHUB_STEP_SUMMARY}";
                awk '/warning:/{print prev_line "\n" $0} {if ($0 ~ /^\[[0-9]+\/[0-9]+\]/) {prev_line = $0} else {prev_line = prev_line "\n" $0}}' \
                    "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log" >> \
                    "${GITHUB_STEP_SUMMARY}";
                echo "\`\`\`" >> "${GITHUB_STEP_SUMMARY}";
            fi

            cat "${ACTUARY_BUILDDIR}/meson-logs/analyzer.log"
            return "${ANALYZER_ERROR}";
        fi
    fi
}
