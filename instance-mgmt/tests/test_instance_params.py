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


def _parse_first_json(output: str) -> dict:
    start = output.find("{")
    if start == -1:
        raise AssertionError("No JSON object found in output")
    depth = 0
    for idx, ch in enumerate(output[start:], start=start):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return json.loads(output[start : idx + 1])
    raise AssertionError("Unterminated JSON object in output")


def test_sequence_variants(tmp_path: Path) -> None:
    file_path = tmp_path / "payload.json"

    params_add_defaults = [
        "add",
        "--instance",
        "test01",
        "--dry-run",
        "--file",
        str(file_path),
    ]
    print("\n[test_sequence_variants:add_defaults] params:\n" + " ".join(params_add_defaults))
    output = _run(params_add_defaults)
    data = _parse_first_json(output)
    print("\n[test_sequence_variants:add_defaults] file content:\n" + json.dumps(data, indent=2))
    assert data["client_payload"]["essdev_instances"]["test01"] == {
        "instance_type": "t3a.large",
        "volume_size1": "200",
        "ami": "RHEL-10.1.0_HVM-*",
    }

    params_add_custom = [
        "add",
        "--instance",
        "app01",
        "--type",
        "m5.large",
        "--os",
        "rhel9",
        "--volume-size",
        "500",
        "--dry-run",
        "--file",
        str(file_path),
    ]
    print("\n[test_sequence_variants:add_custom_values] params:\n" + " ".join(params_add_custom))
    _run(params_add_custom)
    data = _load(file_path)
    print("\n[test_sequence_variants:add_custom_values] file content:\n" + json.dumps(data, indent=2))
    assert data["client_payload"]["essdev_instances"]["app01"] == {
        "instance_type": "m5.large",
        "volume_size1": "500",
        "ami": "RHEL-9.5.0_HVM-*",
    }

    params_del = ["del", "--instance", "test01", "--dry-run", "--file", str(file_path)]
    print("\n[test_sequence_variants:del_instance] params:\n" + " ".join(params_del))
    _run(params_del)
    data = _load(file_path)
    print("\n[test_sequence_variants:del_instance] file content:\n" + json.dumps(data, indent=2))
    assert "test01" not in data["client_payload"]["essdev_instances"]
