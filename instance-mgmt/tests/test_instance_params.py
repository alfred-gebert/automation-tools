from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from instance_params import main


def _run(argv: list[str]) -> str:
    # Capture stdout from main by running through a subprocess-like pattern
    # but without spawning a new process.
    import io
    import sys

    stdout = io.StringIO()
    old_stdout = sys.stdout
    try:
        sys.stdout = stdout
        # Monkeypatch argv for argparse
        import instance_params

        old_argv = sys.argv
        sys.argv = ["instance_params.py", *argv]
        try:
            main()
        finally:
            sys.argv = old_argv
    finally:
        sys.stdout = old_stdout
    return stdout.getvalue().strip()


def _load(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_sequence_variants(tmp_path: Path) -> None:
    file_path = tmp_path / "payload.json"

    output = _run(["add", "--file", str(file_path), "--instance", "test01"])
    data = json.loads(output)
    print("\n[test_sequence_variants:add_defaults] file content:\n" + json.dumps(data, indent=2))
    assert data["client_payload"]["essdev_instances"]["test01"] == {
        "instance_type": "t3a.large",
        "volume_size1": "200",
        "ami": "RHEL-10.1.0_HVM-*",
    }

    _run(
        [
            "add",
            "--file",
            str(file_path),
            "--instance",
            "app01",
            "--type",
            "m5.large",
            "--os",
            "rhel9",
            "--volume-size",
            "500",
        ]
    )
    data = _load(file_path)
    print("\n[test_sequence_variants:add_custom_values] file content:\n" + json.dumps(data, indent=2))
    assert data["client_payload"]["essdev_instances"]["app01"] == {
        "instance_type": "m5.large",
        "volume_size1": "500",
        "ami": "RHEL-9.5.0_HVM-*",
    }

    _run(["del", "--file", str(file_path), "--instance", "test01"])
    data = _load(file_path)
    print("\n[test_sequence_variants:del_instance] file content:\n" + json.dumps(data, indent=2))
    assert "test01" not in data["client_payload"]["essdev_instances"]
