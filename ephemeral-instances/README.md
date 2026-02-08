# Ephemeral Instances

This folder contains `instance-mgmt.py`, a small CLI tool to manage ESS instance definitions stored in a JSON payload file.

## Requirements

- Python 3.8+
- `curl` available on PATH for dispatch calls

## Commands

### Add an instance

Adds or updates an instance entry under `client_payload.essdev_instances` and writes the JSON back to the file.

```
python instance-mgmt.py add --instance test01 --file data.json
```

With custom values:

```
python instance-mgmt.py add --instance app01 --type m5.large --os rhel9 --volume-size 500 --file data.json
```

### Delete an instance

Removes an instance entry from `client_payload.essdev_instances` and writes the JSON back to the file.

```
python instance-mgmt.py del --instance test01 --file data.json
```

### List instances

Prints the instance names stored in `client_payload.essdev_instances`.

```
python instance-mgmt.py list --file data.json
```

## Dry-run mode

Use `--dry-run` to write changes to a temporary file, print the resulting JSON, and print the curl command instead of executing it. By default, the temp file is deleted; use `--keep-temp` to retain it (useful for tests).

```
python instance-mgmt.py add --dry-run --keep-temp --instance test01 --file data.json
```

## GitHub dispatch

For real (non-dry-run) operations, the tool posts the JSON to a GitHub dispatch endpoint.

Required environment variables:

- `GITHUB_WORKFLOW_TOKEN`
- `GITHUB_WORKFLOW_URL`

## File locking

All operations acquire a lock (`.lock` file) to prevent concurrent modifications.
