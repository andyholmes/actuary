// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>

import * as core from '@actions/core';
import * as exec from '@actions/exec';


function getInputArgs(input = '') {
    // We're going to pass these via environment variables, so rejoin the output
    // of the multiline-parsing function.
    return core.getMultilineInput(input).join(' ');
}


async function run() {
    const suite = core.getInput('suite');
    const setupArgs = getInputArgs('setup-args');
    const testArgs = getInputArgs('test-args');

    const actuaryEnv = {
        ...process.env,
        'ACTUARY_SUITE': suite,
        'ACTUARY_SETUP_ARGS': setupArgs,
        'ACTUARY_TEST_ARGS': testArgs,
    };

    if (core.getInput('compiler'))
        actuaryEnv.ACTUARY_COMPILER = core.getInput('compiler');

    if (core.getBooleanInput('test-coverage')) {
        actuaryEnv.ACTUARY_TEST_COVERAGE = 'true';
        actuaryEnv.ACTUARY_LCOV_INCLUDE = core.getInput('lcov-include');
        actuaryEnv.ACTUARY_LCOV_EXCLUDE = core.getInput('lcov-exclude');
    }

    if (suite === 'abidiff') {
        actuaryEnv.ACTUARY_ABIDIFF_ARGS = core.getInput('abidiff-args');
        actuaryEnv.ACTUARY_ABIDIFF_LIB = core.getInput('abidiff-lib');
    }

    if (suite === 'cppcheck') {
        actuaryEnv.ACTUARY_CPPCHECK_ARGS = core.getInput('cppcheck-args');
        actuaryEnv.ACTUARY_CPPCHECK_PATH = core.getInput('cppcheck-path');
    }

    try {
        await exec.exec('actuary-runner', [], {env: actuaryEnv});
    } catch {
        core.setFailed(`Actuary Suite "${suite}" failed`);
    }
}

run();

export default run;
    
