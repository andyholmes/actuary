// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>

import * as core from '@actions/core';
import * as exec from '@actions/exec';


function getInputArgs(input = '') {
    // We're going to pass these via environment variables, so rejoin the output
    // of the multiline-parsing function.
    return core.getMultilineInput(input).join(' ');
}


/**
 * Run the action
 */
async function run() {
    const suite = core.getInput('suite');
    const setupArgs = getInputArgs('setup-args');
    const testArgs = getInputArgs('test-args');

    core.info(`suite: ${suite}`);
    core.info(`setup-args: ${setupArgs}`);
    core.info(`testArgs: ${testArgs}`);

    const actuaryEnv = {
        ...process.env,
        'ACTUARY_SUITE': suite,
        'ACTUARY_SETUP_ARGS': setupArgs,
        'ACTUARY_TEST_ARGS': testArgs,
    };

    if (core.getInput('compiler'))
        actuaryEnv.ACTUARY_COMPILER = core.getInput('compiler');

    if (core.getBooleanInput('setup-coverage'))
        actuaryEnv.ACTUARY_SETUP_COVERAGE = 'true';

    if (suite === 'lcov') {
        actuaryEnv.ACTUARY_LCOV_INCLUDE = core.getInput('lcov-include');
        actuaryEnv.ACTUARY_LCOV_EXCLUDE = core.getInput('lcov-exclude');
    }

    if (suite === 'abidiff')
        actuaryEnv.ACTUARY_ABIDIFF_ARGS = core.getInput('abidiff-args');

    if (suite === 'cppcheck')
        actuaryEnv.ACTUARY_CPPCHECK_ARGS = core.getInput('cppcheck-args');

    await exec.exec('actuary', [], {env: actuaryEnv});
}

run();

export default run;
    
