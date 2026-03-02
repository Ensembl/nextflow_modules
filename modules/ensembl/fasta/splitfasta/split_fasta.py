#!/usr/bin/env python3

"""Split a FASTA file (possibly gzipped) into multiple smaller FASTA files."""

import inspect
import logging
import shutil
from pathlib import Path
from typing import Optional, List, Set, Tuple

from Bio import SeqIO
from Bio.SeqRecord import SeqRecord

try:
    from ensembl.utils.archive import open_gz_file  # type: ignore
except ImportError:
    import gzip

    def open_gz_file(path):
        p = str(path)
        return gzip.open(p, "rt") if p.endswith(".gz") else open(p, "rt")


try:
    from ensembl.utils.argparse import ArgumentParser  # type: ignore
except ImportError:
    from argparse import ArgumentParser

try:
    from ensembl.utils.logging import init_logging_with_args  # type: ignore
except ImportError:
    import logging

    def init_logging_with_args(args):
        level = getattr(args, "log_level", "INFO")
        logging.basicConfig(level=level)


class Params:
    """Class to hold parameters for splitting FASTA files."""

    def __init__(
        self,
        fasta_file: Path,
        out_dir: Optional[Path] = None,
        write_agp: bool = False,
        max_seqs_per_file: Optional[int] = None,
        max_seq_length_per_file: Optional[int] = None,
        min_chunk_length: Optional[int] = None,
        max_files_per_directory: Optional[int] = None,
        max_dirs_per_directory: Optional[int] = None,
        delete_existing_files: bool = False,
        unique_file_names: bool = False,
        delete_original_file: bool = False,
        force_max_seq_length: bool = False,
    ):
        self.fasta_file = fasta_file
        self.out_dir = out_dir if out_dir is not None else fasta_file.parent
        self.write_agp = write_agp
        self.max_seqs_per_file = max_seqs_per_file
        self.max_seq_length_per_file = max_seq_length_per_file
        self.min_chunk_length = min_chunk_length
        self.max_files_per_directory = max_files_per_directory
        self.max_dirs_per_directory = max_dirs_per_directory
        self.delete_existing_files = delete_existing_files
        self.unique_file_names = unique_file_names
        self.delete_original_file = delete_original_file
        self.force_max_seq_length = force_max_seq_length

        self._validate_params()

    def _validate_params(self) -> None:
        if self.max_dirs_per_directory is not None and self.max_dirs_per_directory <= 0:
            raise ValueError("--max-dirs-per-directory must be > 0 or None")
        if (
            self.max_files_per_directory is not None
            and self.max_files_per_directory <= 0
        ):
            raise ValueError("--max-files-per-directory must be > 0 or None")
        if self.max_seqs_per_file is not None and self.max_seqs_per_file <= 0:
            raise ValueError("--max-seqs-per-file must be > 0 or None")
        if (
            self.max_seq_length_per_file is not None
            and self.max_seq_length_per_file <= 0
        ):
            raise ValueError("--max-seq-length-per-file must be > 0 or None")
        if self.min_chunk_length is not None:
            if self.max_seq_length_per_file is None:
                raise ValueError(
                    "--min-chunk-length requires --max-seq-length-per-file"
                )
            if self.min_chunk_length <= 0:
                raise ValueError("--min-chunk-length must be > 0")


class OutputWriter:
    """
    Manages output file creation and counters, writing in a single pass.
    Creates/cleans directories lazily as required.
    """

    def __init__(self, params: Params):
        self.params = params
        self.basename = (
            params.fasta_file.name.removesuffix(".gz")
            .removesuffix(".fa")
            .removesuffix(".fasta")
        )
        self.agp_file = (
            self.params.out_dir.joinpath(self.basename + ".agp")
            if params.write_agp
            else None
        )
        self.file_count = 0
        self.record_count = 0
        self.file_len = 0
        self._fh = None
        self._agp_fh = None
        self._cleaned_dirs: Set[Path] = set()

        self.open_new_file()

    def _create_or_clean_dir(self, dir_path: Path) -> None:
        try:
            dir_path.mkdir(parents=True, exist_ok=True)
            if self.params.delete_existing_files and dir_path not in self._cleaned_dirs:
                for child in dir_path.iterdir():
                    if child.is_dir():
                        shutil.rmtree(child)
                    else:
                        child.unlink()
                self._cleaned_dirs.add(dir_path)
        except Exception:
            logging.exception("Failed to prepare output directory '%s'", dir_path)
            raise

    def _get_subdir_path(self, dir_index: int) -> Path:
        """Computes subdirectory path based on dir_index and max_dirs_per_directory."""
        parts = []
        max_dirs = self.params.max_dirs_per_directory
        if max_dirs is None:
            parts.append("1")
        else:
            current_index = dir_index
            while current_index >= 0:
                parts.append(f"{current_index % max_dirs}")
                current_index = current_index // max_dirs - 1

        parts.reverse()
        return self.params.out_dir.joinpath(*parts)

    def _get_file_and_dir_index(self) -> Tuple[int, int]:
        """
        Determines index of file and directory based on file count and max files per directory.
        Returns (file_index, dir_index).
        """
        max_files = self.params.max_files_per_directory
        if max_files is None:
            return self.file_count, 0
        adjusted_count = self.file_count - 1
        return (adjusted_count % max_files + 1, adjusted_count // max_files)

    def _get_path_for_next_file(self) -> Path:
        """Computes path for the next output file."""
        self.file_count += 1
        file_index, dir_index = self._get_file_and_dir_index()
        subdir_path = self._get_subdir_path(dir_index)
        self._create_or_clean_dir(subdir_path)

        if self.params.unique_file_names:
            file_name = f"{self.basename}.{dir_index}.{file_index}.fa"
        else:
            file_name = f"{self.basename}.{file_index}.fa"
        return subdir_path.joinpath(file_name)

    def add_agp_entry(
        self,
        object_id: str,
        start: int,
        end: int,
        part_nr: int,
        part_id: str,
        part_length: int,
    ) -> None:
        """Adds an entry to the AGP file."""
        # AGP columns for WGS contig component type:
        # object, object_beg, object_end, part_number, component_type,
        # component_id, component_beg, component_end, orientation
        if self._agp_fh is None:
            return
        try:
            line = f"{object_id}\t{start}\t{end}\t{part_nr}\tW\t{part_id}\t1\t{part_length}\t+\n"
            self._agp_fh.write(line)
        except Exception:
            logging.exception("Failed to write AGP entry for part '%s'", part_id)
            raise

    def create_agp_file(self) -> None:
        """Creates the AGP file for recording sequence chunking."""
        if self.agp_file is None:
            return
        try:
            self.params.out_dir.mkdir(parents=True, exist_ok=True)
            self._agp_fh = open(self.agp_file, "w")
            self._agp_fh.write("# AGP-version 2.0\n")
            logging.info("Created AGP file '%s'", self.agp_file)
        except Exception:
            logging.exception("Failed to open AGP file '%s'", self.agp_file)
            raise

    def open_new_file(self) -> None:
        """Closes current file (if any) and opens a new output file."""
        if self._fh is not None:
            self._fh.close()

        path = self._get_path_for_next_file()
        try:
            self._fh = open(path, "w")
            logging.debug("Opened output file '%s'", path)
        except Exception:
            logging.exception("Failed to open output file '%s'", path)
            raise
        self.record_count = 0
        self.file_len = 0

    def write_record(self, record: SeqRecord) -> None:
        """Writes a SeqRecord to the current output file."""
        try:
            SeqIO.write(record, self._fh, "fasta")
            self.record_count += 1
            self.file_len += len(record.seq)
        except Exception:
            logging.exception("Failed to write record '%s' to output file", record.id)
            raise

    def close(self) -> None:
        if self._fh is not None:
            self._fh.close()
            self._fh = None
        if self._agp_fh is not None:
            self._agp_fh.close()
            self._agp_fh = None


def _get_param_defaults() -> dict:
    """Retrieve default values for Params class attributes."""
    signature = inspect.signature(Params.__init__)
    defaults = {}
    for name, param in signature.parameters.items():
        if name != "self" and param.default is not inspect.Parameter.empty:
            defaults[name] = param.default
    return defaults


def split_fasta(params: Params) -> None:
    """Splits the input FASTA file into multiple smaller FASTA files, chunking long sequences if required."""
    if not params.fasta_file.exists():
        logging.error(
            "DEBUG: fasta_file=%r resolved=%r cwd=%r",
            str(params.fasta_file),
            str(Path(params.fasta_file).resolve()),
            str(Path.cwd()),
        )
        raise FileNotFoundError(f"Fasta file '{params.fasta_file}' does not exist")

    # Do nothing if file size is 0
    if params.fasta_file.stat().st_size == 0:
        logging.info("Input FASTA '%s' is empty; nothing to do", params.fasta_file)
        return

    params.out_dir.mkdir(parents=True, exist_ok=True)

    writer = OutputWriter(params)

    try:
        if params.write_agp:
            writer.create_agp_file()

        with open_gz_file(params.fasta_file) as fh:
            for record in SeqIO.parse(fh, "fasta"):
                seq_len = len(record.seq)
                max_seq_len = params.max_seq_length_per_file
                max_seqs = params.max_seqs_per_file

                if max_seqs is not None and writer.record_count >= max_seqs:
                    writer.open_new_file()

                if max_seq_len is None or writer.file_len + seq_len <= max_seq_len:
                    writer.write_record(record)
                    if params.write_agp:
                        writer.add_agp_entry(
                            record.id, 1, seq_len, 1, record.id, seq_len
                        )
                    continue

                if params.force_max_seq_length and seq_len > max_seq_len:
                    starts = list(range(0, seq_len, max_seq_len))
                    ends = [min(s + max_seq_len, seq_len) for s in starts]

                    if params.min_chunk_length is not None and len(starts) > 1:
                        last_chunk_len = ends[-1] - starts[-1]
                        if last_chunk_len < params.min_chunk_length:
                            logging.warning(
                                "Length of last chunk of record '%s' is %d, lower than min_chunk_length: %d;"
                                + "merging with previous chunk",
                                record.id,
                                last_chunk_len,
                                params.min_chunk_length,
                            )
                            ends[-2] = seq_len
                            starts.pop()
                            ends.pop()

                    for i, (start, end) in enumerate(zip(starts, ends), start=1):
                        chunk_seq = record.seq[start:end]
                        chunk_record = SeqRecord(
                            chunk_seq,
                            id=f"{record.id}_chunk_start_{start}",
                            description=f"{record.description} (part {i})",
                        )
                        if writer.record_count > 0:
                            writer.open_new_file()
                        writer.write_record(chunk_record)

                        if params.write_agp:
                            writer.add_agp_entry(
                                record.id,
                                start + 1,
                                end,
                                i,
                                chunk_record.id,
                                len(chunk_seq),
                            )
                else:
                    logging.warning(
                        "Record '%s' length %d exceeds max_seq_length_per_file %d but chunking not enabled",
                        record.id,
                        seq_len,
                        max_seq_len,
                    )
                    if writer.record_count > 0:
                        writer.open_new_file()
                    writer.write_record(record)
                    if params.write_agp:
                        writer.add_agp_entry(
                            record.id, 1, seq_len, 1, record.id, seq_len
                        )
    except Exception:
        logging.exception("Error processing FASTA file '%s'", params.fasta_file)
        raise
    finally:
        writer.close()

    if params.delete_original_file:
        try:
            params.fasta_file.unlink(missing_ok=True)
        except Exception:
            logging.warning(
                "Failed to delete original FASTA file '%s'",
                params.fasta_file,
                exc_info=True,
            )


def parse_args(argv: Optional[List[str]] = None) -> Params:
    defaults = _get_param_defaults()
    parser = ArgumentParser(
        description="Split a FASTA file into multiple FASTA files, optionally chunking long sequences."
    )
    parser.add_argument(
        "--fasta-file",
        type=Path,
        required=True,
        help="Input raw or compressed FASTA file containing sequences to split",
    )
    parser.add_argument(
        "--out-dir",
        type=Path,
        help="Top-level output directory (default: input FASTA directory)",
    )
    parser.add_argument(
        "--write-agp",
        action="store_true",
        help=f"Write AGP file describing the splits (default: {defaults['write_agp']})",
    )
    parser.add_argument(
        "--max-seqs-per-file",
        type=int,
        help=f"Max records per output file (default: {defaults['max_seqs_per_file']})",
    )
    parser.add_argument(
        "--max-seq-length-per-file",
        type=int,
        help=f"Max cumulative sequence length per output file (default: {defaults['max_seq_length_per_file']})",
    )
    parser.add_argument(
        "--min-chunk-length",
        type=int,
        help=f"Minimum length of a chunk allowed as a remainder (default: {defaults['min_chunk_length']})",
    )
    parser.add_argument(
        "--max-files-per-directory",
        type=int,
        help=f"Max files per directory before moving to next computed dir (default: {defaults['max_files_per_directory']})",
    )
    parser.add_argument(
        "--max-dirs-per-directory",
        type=int,
        help=f"Max subdirectories per directory level (default: {defaults['max_dirs_per_directory']})",
    )
    parser.add_argument(
        "--delete-existing-files",
        action="store_true",
        help=f"Delete existing files within computed output dirs (default: {defaults['delete_existing_files']})",
    )
    parser.add_argument(
        "--unique-file-names",
        action="store_true",
        help=f"Make output file names unique across dirs by including dir_index (default: {defaults['unique_file_names']})",
    )
    parser.add_argument(
        "--delete-original-file",
        action="store_true",
        help=f"Delete original input FASTA after splitting (default: {defaults['delete_original_file']})",
    )
    parser.add_argument(
        "--force-max-seq-length",
        action="store_true",
        help=f"Chunk single sequences longer than max-seq-length-per-file (default: {defaults['force_max_seq_length']})",
    )

    args = parser.parse_args(argv)
    init_logging_with_args(args)

    params = Params(
        fasta_file=args.fasta_file,
        out_dir=args.out_dir,
        write_agp=args.write_agp,
        max_seqs_per_file=args.max_seqs_per_file,
        max_seq_length_per_file=args.max_seq_length_per_file,
        min_chunk_length=args.min_chunk_length,
        max_files_per_directory=args.max_files_per_directory,
        max_dirs_per_directory=args.max_dirs_per_directory,
        delete_existing_files=args.delete_existing_files,
        unique_file_names=args.unique_file_names,
        delete_original_file=args.delete_original_file,
        force_max_seq_length=args.force_max_seq_length,
    )
    return params


def main(argv: Optional[List[str]] = None) -> None:
    try:
        params = parse_args(argv)
        split_fasta(params)
    except Exception:
        logging.exception("Error processing FASTA file '%s'", params.fasta_file)
        raise


if __name__ == "__main__":
    main()
