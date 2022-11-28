// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2022 Andy Holmes <andrew.g.r.holmes@gmail.com>

import * as artifact from '@actions/artifact';
import * as core from '@actions/core';

import * as fs from 'fs';
import * as path from 'path';


/**
 * Run the action
 */
async function run() {
    const suite = core.getInput('suite');
    const dir = fs.promises.opendir('suites');

    await fs.promises.access(`suites/${suite}`, fs.constants.X_OK);
}

run();

export default run;
    
