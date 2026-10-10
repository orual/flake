import importlib.util
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location(
    "fetch_secrets", Path(__file__).parents[1] / "modules/nixos/profiles/secrets/fetch.py"
)
fetcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fetcher)


class FetchSecretsTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        credentials = self.directory / "credentials"
        credentials.mkdir()
        (credentials / "access-token").write_text("test-token\n")
        self.runtime = self.directory / "runtime"
        self.runtime.mkdir()
        self.addCleanup(patch.stopall)
        patch.dict(os.environ, {"CREDENTIALS_DIRECTORY": str(credentials)}).start()
        self.chown = patch.object(fetcher.os, "chown").start()
        self.manifest = {
            "env": {"key": "PDS environment", "owner": "root", "group": "root"},
            "api": {"key": "API key", "owner": "root", "group": "root"},
        }
        self.items = [
            {"key": "PDS environment", "value": "JWT_SECRET=abc\nMASTER_KEY=def\n"},
            {"key": "API key", "value": "abc"},
        ]

    def fetch(self, items):
        response = subprocess.CompletedProcess([], 0, json.dumps(items))
        with patch.object(fetcher.subprocess, "run", return_value=response) as command:
            fetcher.fetch(self.manifest, "config.toml", "bws", self.runtime)
        return command

    def test_values_permissions_and_token_transport(self):
        command = self.fetch(self.items)
        current = self.runtime / "current"
        self.assertEqual((current / "env").read_text(), self.items[0]["value"])
        self.assertEqual((current / "api").read_text(), "abc")
        self.assertEqual(stat.S_IMODE((current / "api").stat().st_mode), 0o400)
        self.assertEqual(self.chown.call_count, 2)
        self.assertEqual(command.call_args.args[0], ["bws", "--config-file", "config.toml", "secret", "list"])
        self.assertEqual(command.call_args.kwargs["env"]["BWS_ACCESS_TOKEN"], "test-token")

    def test_rotation_replaces_whole_generation(self):
        self.fetch(self.items)
        previous = (self.runtime / "current").resolve()
        updated = self.items + [{"key": "unused", "value": "do not publish"}]
        updated[1] = {"key": "API key", "value": "new"}
        self.fetch(updated)
        self.assertFalse(previous.exists())
        self.assertEqual((self.runtime / "current/api").read_text(), "new")
        self.assertEqual(sorted(p.name for p in (self.runtime / "current").iterdir()), ["api", "env"])

    def test_missing_duplicate_or_empty_values_preserve_current(self):
        self.fetch(self.items)
        previous = (self.runtime / "current").resolve()
        for items in [self.items[:1], self.items + [self.items[1]], [self.items[0], {"key": "API key", "value": ""}]]:
            with self.subTest(items=items), self.assertRaises(ValueError):
                self.fetch(items)
            self.assertEqual((self.runtime / "current").resolve(), previous)
            self.assertEqual((self.runtime / "current/api").read_text(), "abc")

    def test_fetch_failure_preserves_current(self):
        self.fetch(self.items)
        previous = (self.runtime / "current").resolve()
        with patch.object(fetcher.subprocess, "run", side_effect=subprocess.CalledProcessError(1, "bws")):
            with self.assertRaises(subprocess.CalledProcessError):
                fetcher.fetch(self.manifest, "config.toml", "bws", self.runtime)
        self.assertEqual((self.runtime / "current").resolve(), previous)

    def test_publish_failure_cleans_staging(self):
        self.fetch(self.items)
        previous = (self.runtime / "current").resolve()
        self.chown.side_effect = OSError("ownership failed")
        with self.assertRaises(OSError):
            self.fetch(self.items)
        self.assertEqual((self.runtime / "current").resolve(), previous)
        self.assertEqual(len(list(self.runtime.glob("generation-*"))), 1)
        self.assertFalse((self.runtime / "next").exists())


if __name__ == "__main__":
    unittest.main()
