import importlib.util
from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def split_fasta_module():
    """
    Load modules/ensembl/fasta/splitfasta/split_fasta.py as a Python module
    regardless of whether 'modules/' is a Python package.
    """
    repo_root = Path(__file__).resolve().parents[1]
    module_path = (
        repo_root / "modules" / "ensembl" / "fasta" / "splitfasta" / "split_fasta.py"
    )

    spec = importlib.util.spec_from_file_location("split_fasta", module_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not load module spec from {module_path}")

    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod
