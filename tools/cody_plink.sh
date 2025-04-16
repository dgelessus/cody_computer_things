#!/bin/sh
# SPDX-License-Identifier: 0BSD

exec plink -serial -sercfg "19200,8,n,1,N" "$@"
