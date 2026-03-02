# tests/test_split_fasta.py
from pathlib import Path

import pytest
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.SeqRecord import SeqRecord


def write_fasta(path: Path, records):
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        SeqIO.write(records, fh, "fasta")


def list_output_fastas(out_dir: Path):
    return sorted(out_dir.rglob("*.fa"))


def read_all_ids_from_fastas(out_dir: Path):
    ids = []
    for fa in list_output_fastas(out_dir):
        with open(fa, "r", encoding="utf-8") as fh:
            ids.extend([r.id for r in SeqIO.parse(fh, "fasta")])
    return ids


def parse_agp_lines(agp_path: Path):
    lines = [l.rstrip("\n") for l in agp_path.read_text(encoding="utf-8").splitlines()]
    lines = [l for l in lines if l and not l.startswith("#")]
    return [l.split("\t") for l in lines]


def test_no_agp_by_default(tmp_path: Path, split_fasta_module):
    inp = tmp_path / "in.fa"
    out = tmp_path / "out"
    write_fasta(inp, [SeqRecord(Seq("ACGT"), id="seq1", description="")])

    params = split_fasta_module.Params(
        fasta_file=inp,
        out_dir=out,
        write_agp=False,
    )
    split_fasta_module.split_fasta(params)

    assert not (out / "in.agp").exists()
    assert len(list_output_fastas(out)) >= 1


def test_split_by_max_seqs_per_file(tmp_path: Path, split_fasta_module):
    inp = tmp_path / "in.fa"
    out = tmp_path / "out"
    recs = [
        SeqRecord(Seq("A" * 10), id="s1", description=""),
        SeqRecord(Seq("C" * 10), id="s2", description=""),
        SeqRecord(Seq("G" * 10), id="s3", description=""),
    ]
    write_fasta(inp, recs)

    params = split_fasta_module.Params(
        fasta_file=inp,
        out_dir=out,
        max_seqs_per_file=2,
        write_agp=False,
    )
    split_fasta_module.split_fasta(params)

    fas = list_output_fastas(out)
    assert len(fas) == 2
    assert read_all_ids_from_fastas(out) == ["s1", "s2", "s3"]


def test_chunk_merge_final_small_chunk_and_agp(tmp_path: Path, split_fasta_module):
    """
    seq_len=2100, max=1000 -> chunks [1000, 1000, 100]
    min_chunk_length=200 -> final chunk merged -> [1000, 1100]
    """
    inp = tmp_path / "in.fa"
    out = tmp_path / "out"
    write_fasta(inp, [SeqRecord(Seq("A" * 2100), id="chr1", description="chr1")])

    params = split_fasta_module.Params(
        fasta_file=inp,
        out_dir=out,
        write_agp=True,
        force_max_seq_length=True,
        max_seq_length_per_file=1000,
        min_chunk_length=200,
        max_seqs_per_file=100000,  # avoid seq-count splitting interfering
    )
    split_fasta_module.split_fasta(params)

    # 2 chunks expected after merge
    assert read_all_ids_from_fastas(out) == [
        "chr1_chunk_start_0",
        "chr1_chunk_start_1000",
    ]

    agp = out / "in.agp"
    assert agp.exists()

    cols = parse_agp_lines(agp)
    assert len(cols) == 2

    # object, obj_beg, obj_end, part_no, type, comp_id, comp_beg, comp_end, orient
    assert cols[0][0] == "chr1"
    assert cols[0][1:4] == ["1", "1000", "1"]
    assert cols[0][4] == "W"
    assert cols[0][5] == "chr1_chunk_start_0"
    assert cols[0][6:9] == ["1", "1000", "+"]

    assert cols[1][0] == "chr1"
    assert cols[1][1:4] == ["1001", "2100", "2"]
    assert cols[1][4] == "W"
    assert cols[1][5] == "chr1_chunk_start_1000"
    assert cols[1][6:9] == ["1", "1100", "+"]


def test_agp_part_numbers_restart_per_object(tmp_path: Path, split_fasta_module):
    inp = tmp_path / "in.fa"
    out = tmp_path / "out"
    recs = [
        SeqRecord(Seq("A" * 1200), id="obj1", description=""),
        SeqRecord(Seq("C" * 1200), id="obj2", description=""),
    ]
    write_fasta(inp, recs)

    params = split_fasta_module.Params(
        fasta_file=inp,
        out_dir=out,
        write_agp=True,
        force_max_seq_length=True,
        max_seq_length_per_file=1000,
        min_chunk_length=100,  # => 2 chunks each, no merge
    )
    split_fasta_module.split_fasta(params)

    cols = parse_agp_lines(out / "in.agp")

    by_obj = {}
    for c in cols:
        by_obj.setdefault(c[0], []).append(int(c[3]))

    assert by_obj["obj1"] == [1, 2]
    assert by_obj["obj2"] == [1, 2]
