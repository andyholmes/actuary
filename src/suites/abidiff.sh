# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved
# ACTUARY-Type: suite
# ACTUARY-Depends: actuary


actuarysuite_abidiff_build() {
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

#
# SUITE: abidiff
#
# Run the compiler's static analysis tool.
#
# The setup phase respects the following environment variables:
#
# | Variable                           | meson setup                         |
# |------------------------------------|-------------------------------------|
# | ACTUARY_SETUP_BUILDTYPE            | --buildtype                         |
# | ACTUARY_SETUP_ARGS                 | additional command-line arguments   |
#
actuarysuite_abidiff() {
    # Ensure a log directory exists where it is expected
    mkdir -p "${ACTUARY_BUILDDIR}/meson-logs"

    if [ "${GITHUB_ACTIONS}" = "true" ]; then
        BASE_REF="${GITHUB_BASE_REF}"
        HEAD_REF="${GITHUB_HEAD_REF}"
    else
        BASE_REF="main"
        HEAD_REF=$(git rev-parse HEAD)
    fi

    # See: CVE-2022-24765
    git config --global --add safe.directory "${ACTUARY_WORKSPACE}"

    BASE_DIR="${ACTUARY_BUILDDIR}/_base"
    HEAD_DIR="${ACTUARY_BUILDDIR}/_head"

    actuarysuite_abidiff_build "${BASE_REF}" "${BASE_DIR}" > /dev/null 2>&1
    actuarysuite_abidiff_build "${HEAD_REF}" "${HEAD_DIR}" > /dev/null 2>&1

    # Run `abidiff`
    abidiff --drop-private-types \
            --fail-no-debug-info \
            --no-added-syms \
            --headers-dir1 "${BASE_DIR}/usr/include" \
            --headers-dir2 "${HEAD_DIR}/usr/include" \
            "${BASE_DIR}/usr/lib/libvalent.so" \
            "${HEAD_DIR}/usr/lib/libvalent.so" > \
            "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" || \
    (cat "${ACTUARY_BUILDDIR}/meson-logs/abidiff.log" && exit 1);
}
