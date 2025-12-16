#!/usr/bin/env -S uv run --script
# -*- coding: utf-8 -*-
# /// script
# ///

# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2025 dgelessus
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

"""
Pre-processor for CodyBASIC programs.
"""

import sys
import argparse


def _remove_comments(statements):
    return [st for st in statements if not st["statement"].startswith("REM")]


def _add_line_numbers(statements, **kwargs):
    keep_line_numbers = kwargs.get("keep_line_numbers", True)

    line_number = 0
    for st in statements:
        if not st["statement"]:
            continue  # ignore empty statements

        if keep_line_numbers and st["label"] and st["label"].isdigit():
            line_number_candidate = int(st["label"])
            if line_number_candidate > line_number:
                line_number = line_number_candidate
            else:
                raise ValueError(
                    f"[line {st['original_line_number']}] line numbers must be strictly ascending, but {line_number} is not less than {line_number_candidate}"
                )
        else:
            line_number += 10

        if line_number <= 0 or line_number >= 2**16:
            raise ValueError(
                f"[line {st['original_line_number']}] line number {line_number} out of bounds"
            )
        st["line_number"] = line_number
    return statements


def _resolve_labels(statements):
    def fix_jump_statement(stmt: str):
        if stmt.startswith("GOTO") or stmt.startswith("GOSUB"):
            cmd, target = stmt.split(maxsplit=1)
            for st in statements:
                if st["label"] == target:
                    target_line_number = st["line_number"]
                    return f"{cmd} {target_line_number}"
            raise ValueError(f"label {target} not found")
        elif stmt.startswith("IF"):
            prefix, suffix = stmt.split(sep="THEN", maxsplit=1)
            fixed_suffix = fix_jump_statement(suffix.lstrip())
            return f"{prefix}THEN {fixed_suffix}"
        return stmt

    for st in statements:
        st["statement"] = fix_jump_statement(st["statement"])
    return statements


def process(infile, outfile, **kwargs):
    remove_comments = kwargs.get("remove_comments", False)
    optimize_for_serial = kwargs.get("serial", True)

    statements = []
    original_line_number = 0  # keep track of physical line number for error messages
    for line in infile:
        original_line_number += 1
        line = line.strip()
        if optimize_for_serial and not line:
            continue

        # a statement can look like this:
        # <STMT>           (no label)
        # _ <STMT>         (no label)
        # <number> <STMT>  (line number as label)
        # <label>: <STMT>  (textual label)
        label = None
        label_split = line.split(maxsplit=1)
        if len(label_split) == 2 and label_split[0]:
            if label_split[0].endswith(":"):
                label = label_split[0][:-1]
                if not label:
                    raise ValueError(
                        f"[line {st['original_line_number']}] label cannot be empty"
                    )
                line = label_split[1]
            elif label_split[0].isdigit():
                label = label_split[0]
                line = label_split[1]
            elif label_split[0] == "_":
                label = None
                line = label_split[1]

        statements.append(
            {
                "statement": line,
                "label": label,
                "original_line_number": original_line_number,
            }
        )

    if remove_comments:
        statements = _remove_comments(statements)
    statements = _add_line_numbers(statements, **kwargs)
    statements = _resolve_labels(statements)

    for st in statements:
        line_number = st.get("line_number")
        stmt = st["statement"]
        if line_number:
            line = f"{line_number} {stmt}"
        else:
            line = stmt
        outfile.write(line)
        outfile.write("\n")

    if optimize_for_serial:
        outfile.write("\n")


def run(input_file, output_file=None):
    output_file = output_file or "-"
    with (
        sys.stdout
        if output_file == "-"
        else open(output_file, "w", newline="\n", encoding="ascii", errors="replace")
    ) as output_file:
        with (
            sys.stdin if input_file == "-" else open(input_file, "r", encoding="utf-8")
        ) as input_file:
            process(input_file, output_file)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", help="Input file")
    parser.add_argument("-o", "--out", help="Output file")

    args = parser.parse_args()
    run(args.file, args.out)


if __name__ == "__main__":
    sys.exit(main())
