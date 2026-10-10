import json
import os
from pathlib import Path
import pwd
import grp
import shutil
import subprocess
import sys
import tempfile


def fetch(manifest, config_file, bws, directory):
    token_file = Path(os.environ["CREDENTIALS_DIRECTORY"]) / "access-token"
    environment = os.environ | {"BWS_ACCESS_TOKEN": token_file.read_text().strip()}
    response = subprocess.run(
        [bws, "--config-file", config_file, "secret", "list"],
        env=environment,
        check=True,
        capture_output=True,
        text=True,
    )
    secrets = json.loads(response.stdout)
    values = {}
    for name, secret in manifest.items():
        matches = [item for item in secrets if item["key"] == secret["key"]]
        if len(matches) != 1:
            raise ValueError(f"Expected exactly one Bitwarden secret named {secret['key']!r}")
        value = matches[0]["value"]
        if not isinstance(value, str) or not value:
            raise ValueError(f"Bitwarden secret {secret['key']!r} must be a non-empty string")
        values[name] = value

    directory = Path(directory)
    generation = Path(tempfile.mkdtemp(prefix="generation-", dir=directory))
    link = directory / "next"
    current = directory / "current"
    previous = current.resolve() if current.is_symlink() else None
    try:
        for name, secret in manifest.items():
            path = generation / name
            path.write_text(values[name])
            os.chown(path, pwd.getpwnam(secret["owner"]).pw_uid, grp.getgrnam(secret["group"]).gr_gid)
            path.chmod(0o400)
        generation.chmod(0o755)
        link.symlink_to(generation.name)
        link.replace(current)
    except BaseException:
        link.unlink(missing_ok=True)
        shutil.rmtree(generation)
        raise
    if previous is not None:
        shutil.rmtree(previous)


if __name__ == "__main__":
    os.umask(0o077)
    try:
        with open(sys.argv[1]) as manifest_file:
            fetch(json.load(manifest_file), *sys.argv[2:])
    except subprocess.CalledProcessError:
        sys.exit("Bitwarden secret retrieval failed")
    except (ValueError, OSError, KeyError) as error:
        sys.exit(str(error))
