#!/usr/bin/env python3

# See the NOTICE file distributed with this work for additional information
# regarding copyright ownership.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Compute longest, total, and count statistics for FASTA records."""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path

from ensembl.utils.argparse import ArgumentParser
from ensembl.utils.archive import open_gz_file


@dataclass(frozen=True)
class FastaStats:
    longest: int
    total: int
    n_seqs: int


def compute_fasta_stats(fasta: Path) -> FastaStats:
    """
    Compute FASTA stats in a single streaming pass.

    Args:
        fasta: Path to the input FASTA file.

    Returns:
        FastaStats: Longest sequence length, total sequence length, and record count.
    """
    longest = 0
    total = 0
    n_seqs = 0
    current = 0
    saw_record = False

    with open_gz_file(fasta) as fh:
        for raw_line in fh:
            line = raw_line.strip()
            if line.startswith(">"):
                if saw_record:
                    longest = max(longest, current)
                    total += current
                n_seqs += 1
                current = 0
                saw_record = True
                continue

            current += len(line.strip())

    if saw_record:
        longest = max(longest, current)
        total += current

    return FastaStats(longest=longest, total=total, n_seqs=n_seqs)


def write_fasta_stats(stats: FastaStats, output: Path) -> None:
    """
    Write FASTA statistics to the output file.

    Args:
        stats: FASTA statistics to write.
        output: Path to the output text file.
    """
    output.write_text(
        f"{stats.longest} {stats.total} {stats.n_seqs}\n",
        encoding="utf-8",
    )


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    """
    Parse command-line arguments.

    Args:
        argv: Optional command-line arguments. If None, argparse reads from sys.argv.

    Returns:
        argparse.Namespace: Parsed command-line arguments.
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument_src_path(
        "--fasta",
        required=True,
        help="Input FASTA, optionally gzipped.",
    )
    parser.add_argument_dst_path(
        "--output",
        required=True,
        help="Output stats text file.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    """
    Run the FASTA stats command-line interface.

    Args:
        argv: Optional command-line arguments. If None, argparse reads from sys.argv.

    Returns:
        int: Exit status code.
    """
    args = parse_args(argv)

    try:
        stats = compute_fasta_stats(args.fasta)
        write_fasta_stats(stats, args.output)
    except Exception as exc:
        print(exc, file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
