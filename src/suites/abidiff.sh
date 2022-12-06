# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved


actuary_suite_abidiff_build() {
    TARGET_REF="${1}"
    TARGET_DIR="${2}"

    git fetch origin "${TARGET_REF}" && \
    git checkout "${TARGET_REF}"

    BUILDSUBDIR="${ACTUARY_BUILDDIR}/$(git rev-parse "${TARGET_REF}")"

    if [ ! -d "${BUILDSUBDIR}" ]; then
        # shellcheck disable=SC2086
        meson setup --buildtype="${ACTUARY_SETUP_BUILDTYPE:=release}" \
                    --prefix=/usr \
                    --libdir=lib \
                    ${ACTUARY_SETUP_ARGS} \
                    "${BUILDSUBDIR}"
    fi

    meson compile -C "${BUILDSUBDIR}" && \
    DESTDIR="${TARGET_DIR}" meson install -C "${BUILDSUBDIR}"
}

actuary_suite_abidiff() {
    # See: CVE-2022-24765
    git config --global --add safe.directory "${ACTUARY_WORKSPACE}"
    
    # Ensure a log directory exists where it is expected
    mkdir -p "${ACTUARY_BUILDDIR}/meson-logs"

    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        echo "log=${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" >> "${GITHUB_OUTPUT}"

        BASE_REF="${GITHUB_BASE_REF}"
        HEAD_REF="${GITHUB_HEAD_REF}"
    else
        BASE_REF="main"
        HEAD_REF=$(git rev-parse HEAD)
    fi

    BASE_DIR="${ACTUARY_BUILDDIR}/_base"
    HEAD_DIR="${ACTUARY_BUILDDIR}/_head"

    actuary_suite_abidiff_build "${BASE_REF}" "${BASE_DIR}" > /dev/null 2>&1
    actuary_suite_abidiff_build "${HEAD_REF}" "${HEAD_DIR}" > /dev/null 2>&1

    # Run `abidiff`
    abidiff --drop-private-types \
            --fail-no-debug-info \
            --no-added-syms \
            --headers-dir1 "${BASE_DIR}/usr/include" \
            --headers-dir2 "${HEAD_DIR}/usr/include" \
            "${BASE_DIR}/usr/lib/${ACTUARY_ABIDIFF_LIB}" \
            "${HEAD_DIR}/usr/lib/${ACTUARY_ABIDIFF_LIB}" > \
            "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" || \
    (cat "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" && exit 1);
}
