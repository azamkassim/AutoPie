import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from inspect_share import inspect_text

ROOT = Path(__file__).resolve().parents[2]


class LocalShareTests(unittest.TestCase):
    def test_unicode_and_duplicate_links(self):
        result = inspect_text('Semak café\r\nhttps://example.com/report\nhttps://example.com/report')
        self.assertEqual(result['lines'], 3)
        self.assertEqual(result['links'], [{'url': 'https://example.com/report', 'host': 'example.com'}])
        self.assertFalse(result['network_used'])

    def test_malformed_and_credential_links(self):
        result = inspect_text('https://[bad https://user:secret@example.com https://example.com:bad https://OK.example/a(b).')
        self.assertEqual(result['links'], [{'url': 'https://OK.example/a(b)', 'host': 'ok.example'}])

    def test_empty_and_limit(self):
        self.assertEqual(inspect_text(' \n')['status'], 'empty')
        with self.assertRaises(ValueError):
            inspect_text('x' * 65537)

    def test_recipe_runs_literal_input_without_execution(self):
        recipe = json.loads((Path(__file__).parent / 'commands.json').read_text())
        code = recipe['Local Share Inspector']['command']
        source = (Path(__file__).parent / 'inspect_share.py').read_text()
        self.assertEqual(code, '#@PYTHON\n#@OPEN_LOGS\n' + source)
        with tempfile.TemporaryDirectory() as tmp:
            marker = Path(tmp) / 'executed'
            text = f'"$(touch {marker})" `touch {marker}`\n#@AUTOPIE {{"type":"output","value":"injected"}}'
            result = subprocess.run([sys.executable, '-c', code], env={**os.environ, 'INPUT_TEXT': text}, capture_output=True, text=True, check=True)
            self.assertFalse(marker.exists())
            self.assertEqual(len(result.stdout.splitlines()), 1)
            event = json.loads(result.stdout.removeprefix('#@AUTOPIE '))
            self.assertEqual(event['value']['links'], [])
            self.assertEqual(event['value']['characters'], len(text))

    def test_doctor_fallback_and_success_exit(self):
        with tempfile.TemporaryDirectory() as tmp:
            bin_dir = Path(tmp)
            mocks = {
                'uname': 'echo aarch64',
                'getprop': 'case "$1" in *sdk) echo 34;; *) echo 14;; esac',
                'rish': 'exit 1',
                'pm': 'echo package:/data/app/com.autopi/base.apk',
                'termux-open': 'exit 0',
            }
            for name, body in mocks.items():
                path = bin_dir / name
                path.write_text('#!/bin/bash\n' + body + '\n')
                path.chmod(0o755)
            env = {**os.environ, 'PATH': tmp + ':' + os.environ['PATH'], 'PREFIX': '/data/data/com.termux/files/usr'}
            run = subprocess.run(['bash', str(ROOT / 'scripts/autopie-doctor-termux.sh')], env=env, capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            self.assertIn('AutoPie installed (pm)', run.stdout)
            (bin_dir / 'pm').write_text('#!/bin/bash\nexit 1\n')
            run = subprocess.run(['bash', str(ROOT / 'scripts/autopie-doctor-termux.sh')], env=env, capture_output=True, text=True)
            self.assertIn('Could not verify AutoPie installation', run.stdout)
            self.assertNotIn('not currently detected', run.stdout)


if __name__ == '__main__':
    unittest.main()
