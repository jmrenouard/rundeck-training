# Configure Rundeck ACLs and MinIO S3 Jobs

This procedure validates `.aclpolicy` YAML documents, uploads a job template, and stores a MinIO secret key.

## Prerequisites

- Rundeck is accessible on `http://localhost:4440`.
- Python 3 with `PyYAML` exists on the host.
- The MinIO client `mc` exists on the target execution node.

## Procedure

1. Open `aclpolicy/index.html` in a browser and build your project policy rules.

2. Ensure a `---` separator divides multiple `context` and `for` blocks inside one `.aclpolicy` file.

3. Validate all local YAML template files with Python before import.

```bash
python3 -c "import yaml, pathlib; [list(yaml.safe_load_all(p.read_text())) for p in sorted(pathlib.Path('templates').rglob('*.y*ml'))]"
```

4. Copy the validated `.aclpolicy` file to `/etc/rundeck/` on the Rundeck host.

5. Open **Project Settings -> Key Storage** in Rundeck and save your MinIO password at `keys/minio/secret_key`.

6. Import `templates/rundeck/minio/transfert-s3.yml` through **Jobs -> Upload Definition**.

## Verification

1. Run a syntax check on `templates/rundeck/minio/transfert-s3.yml`.

```bash
python3 -c "import yaml, pathlib; print(yaml.safe_load(pathlib.Path('templates/rundeck/minio/transfert-s3.yml').read_text())[0]['name'])"
```

2. Run the MinIO transfer job with a small test file and verify the object in your bucket.

## Rollback

WARNING: Do not keep plaintext S3 secrets in `.yaml` files or script arguments.

If an invalid `.aclpolicy` blocks project access, remove the faulty file from `/etc/rundeck/` and restore the prior policy:

```bash
sudo rm -f /etc/rundeck/project_webapp_custom.aclpolicy
```
