#!/bin/sh -e

# SPDX-License-Identifier: CC0-1.0
# SPDX-FileCopyrightText: No rights reserved

# deadcode.DeadStores: allows assigning a value to an auto-cleanup
scan-build --status-bugs \
           -disable-checker deadcode.DeadStores \
           "$@"

