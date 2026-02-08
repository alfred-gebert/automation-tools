#!/usr/bin/env python3
"""Manage ESS instance definitions in a JSON payload file."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from typing import List, Optional
from pathlib import Path
import os
import subprocess
import tempfile
import time
from contextlib import contextmanager


@dataclass
class Args:
    command: str
    file: str
    dry_run: bool
    instance: Optional[str]
    type: Optional[str]
    os: Optional[str]
    volume_size: Optional[int]


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Manage ESS instance definitions in a JSON payload file "
            "(add, del, list)."
        )
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    add_parser = subparsers.add_parser("add", help="Add instance payload")
    add_parser.add_argument("--file", required=True, help="JSON file path")
    add_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Write changes to a temporary copy and print the curl command",
    )
    add_parser.add_argument("--instance", required=True, help="Instance name")
    add_parser.add_argument("--type", default="t3a.large", help="Instance type")
    add_parser.add_argument("--os", default="rhel10", help="Operating system")
    add_parser.add_argument(
        "--volume-size",
        type=int,
        default=200,
        help="Volume size in GB",
    )

    del_parser = subparsers.add_parser("del", help="Delete instance payload")
    del_parser.add_argument("--file", required=True, help="JSON file path")
    del_parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Write changes to a temporary copy and print the curl command",
    )
    del_parser.add_argument("--instance", required=True, help="Instance name")

    list_parser = subparsers.add_parser(
        "list", help="List instance names from essdev_instances"
    )
    list_parser.add_argument("--file", required=True, help="JSON file path")
    return parser


def parse_args(argv: Optional[List[str]] = None) -> Args:
    parser = build_parser()
    ns = parser.parse_args(argv)
    return Args(
        command=ns.command,
        file=ns.file,
        dry_run=getattr(ns, "dry_run", False),
        instance=getattr(ns, "instance", None),
        type=getattr(ns, "type", None),
        os=getattr(ns, "os", None),
        volume_size=getattr(ns, "volume_size", None),
    )


def _default_struct() -> dict:
    return {
        "event_type": "ephemeraless",
        "client_payload": {
            "essdev_instances": {},
            "assdk_instances": {},
            "ess_custom_ports_egress": {},
            "ess_custom_ports_ingress": {},
            "region": "eu-central-1",
        },
    }


def _ensure_structure(data: dict) -> dict:
    base = _default_struct()
    if not isinstance(data, dict):
        return base
    data.setdefault("event_type", base["event_type"])
    client_payload = data.setdefault("client_payload", {})
    if not isinstance(client_payload, dict):
        client_payload = {}
        data["client_payload"] = client_payload
    for key, value in base["client_payload"].items():
        client_payload.setdefault(key, value)
    return data


def _load_or_init(path: Path) -> dict:
    if path.exists():
        with path.open("r", encoding="utf-8-sig") as handle:
            raw = handle.read()
        if not raw.strip():
            return _default_struct()
        try:
            return _ensure_structure(json.loads(raw))
        except json.JSONDecodeError as exc:
            raise SystemExit(
                f"Invalid JSON in {path}. Fix the file or delete it to reinitialize."
            ) from exc
    return _default_struct()


def _write_json(path: Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")


@contextmanager
def _file_lock(path: Path, timeout_seconds: int = 30) -> None:
    lock_path = path.with_suffix(path.suffix + ".lock")
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    start = time.time()
    with lock_path.open("a+") as lock_handle:
        if os.name == "nt":
            import msvcrt

            while True:
                try:
                    msvcrt.locking(lock_handle.fileno(), msvcrt.LK_NBLCK, 1)
                    break
                except OSError:
                    if time.time() - start > timeout_seconds:
                        raise SystemExit(f"Timeout waiting for lock: {lock_path}")
                    time.sleep(0.1)
            try:
                yield
            finally:
                lock_handle.seek(0)
                msvcrt.locking(lock_handle.fileno(), msvcrt.LK_UNLCK, 1)
        else:
            import fcntl

            while True:
                try:
                    fcntl.flock(lock_handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    break
                except OSError:
                    if time.time() - start > timeout_seconds:
                        raise SystemExit(f"Timeout waiting for lock: {lock_path}")
                    time.sleep(0.1)
            try:
                yield
            finally:
                fcntl.flock(lock_handle, fcntl.LOCK_UN)


def _resolve_ami(os_name: Optional[str]) -> Optional[str]:
    if not os_name:
        return None

    mapping = {
        "rhel9": "RHEL-9.5.0_HVM-*",
        "rhel10": "RHEL-10.1.0_HVM-*",
    }
    return mapping.get(os_name, os_name)


def _dispatch_payload(path: Path) -> None:
    cmd = _build_curl_cmd(path)
    subprocess.run(cmd, check=True)


def _build_curl_cmd(path: Path, *, dry_run: bool = False) -> list[str]:
    token = os.getenv("GITHUB_WORKFLOW_TOKEN")
    url = os.getenv("GITHUB_WORKFLOW_URL")
    if not token or not url:
        if dry_run:
            token = token or "DRY_RUN_TOKEN"
            url = url or "https://api.github.com/repos/ORG/repo-name/dispatches"
        else:
            raise SystemExit(
                "Missing GITHUB_WORKFLOW_TOKEN or GITHUB_WORKFLOW_URL environment variable."
            )
    return [
        "curl",
        "-isL",
        "-X",
        "POST",
        "-H",
        "Accept: application/vnd.github+json",
        "-H",
        f"Authorization: Bearer {token}",
        "-H",
        "X-GitHub-Api-Version: 2022-11-28",
        url,
        "-d",
        f"@{path}",
    ]


def main() -> int:
    args = parse_args()
    file_path = Path(args.file)
    with _file_lock(file_path):
        data = _load_or_init(file_path)
        client_payload = data["client_payload"]
        output_path = file_path
        if args.command == "add":
            ami = _resolve_ami(args.os)
            client_payload["essdev_instances"][args.instance] = {
                "instance_type": args.type,
                "volume_size1": str(args.volume_size),
                "ami": ami,
            }
            if args.dry_run:
                with tempfile.NamedTemporaryFile(
                    mode="w", suffix=file_path.suffix or ".json", delete=False
                ) as handle:
                    output_path = Path(handle.name)
                _write_json(output_path, data)
                print(json.dumps(data, indent=2))
                print(" ".join(_build_curl_cmd(output_path, dry_run=True)))
            else:
                _write_json(file_path, data)
                _dispatch_payload(file_path)
                print(json.dumps(data, indent=2))
            return 0
        if args.command == "del":
            client_payload["essdev_instances"].pop(args.instance, None)
            client_payload["ess_custom_ports_egress"].pop(args.instance, None)
            client_payload["ess_custom_ports_ingress"].pop(args.instance, None)
            if args.dry_run:
                with tempfile.NamedTemporaryFile(
                    mode="w", suffix=file_path.suffix or ".json", delete=False
                ) as handle:
                    output_path = Path(handle.name)
                _write_json(output_path, data)
                print(json.dumps(data, indent=2))
                print(" ".join(_build_curl_cmd(output_path, dry_run=True)))
            else:
                _write_json(file_path, data)
                _dispatch_payload(file_path)
                print(json.dumps(data, indent=2))
            return 0
        if args.command == "list":
            instances = sorted(client_payload["essdev_instances"].keys())
            print(json.dumps(instances, indent=2))
            return 0
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
