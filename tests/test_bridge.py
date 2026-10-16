import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('bridge', Path(__file__).resolve().parents[1] / 'bridge.py')
bridge = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bridge)


class BridgeTests(unittest.TestCase):
    def test_markdown_export_import_and_no_clobber(self):
        with tempfile.TemporaryDirectory() as directory:
            path = str(Path(directory) / '日本語.md')
            bridge.run(dict(operation='export', path=path, text='# Notes\n- one\n'))
            self.assertEqual(bridge.run(dict(operation='import', path=path))['text'], '# Notes\n- one\n')
            with self.assertRaises(FileExistsError):
                bridge.run(dict(operation='export', path=path, text='replace'))
            self.assertEqual(Path(path).read_text(), '# Notes\n- one\n')

    def test_new_location_copies_and_existing_workspace_is_preserved(self):
        with tempfile.TemporaryDirectory() as directory:
            path = str(Path(directory) / 'sync' / 'outline.json')
            text = json.dumps(dict(version=2, rolls=[], activeRollId='test'))
            bridge.run(dict(operation='location', path=path, text=text))
            bridge.run(dict(operation='location', path=path, text='must not overwrite'))
            self.assertEqual(Path(path).read_text(), text)
            Path(path).write_text('broken')
            with self.assertRaises(ValueError):
                bridge.run(dict(operation='location', path=path, text=text))

    def test_ai_receives_only_stdin_and_runs_in_an_empty_directory(self):
        command = [sys.executable, '-c',
                   'import sys,os; s=sys.stdin.read(); assert "private branch" in s; assert not os.listdir("."); print("- Summary")']
        result = bridge.run(dict(operation='ai', command=command, task='summarize', text='- private branch'))
        self.assertEqual(result['text'], '- Summary')

    def test_ai_nonzero_and_empty_output_are_errors(self):
        for code in ['raise SystemExit(3)', 'print("")']:
            with self.assertRaises(ValueError):
                bridge.run(dict(operation='ai', command=[sys.executable, '-c', code], task='reorder', text='- notes'))

    def test_request_rejects_relative_paths_and_bad_ai_commands(self):
        with self.assertRaises(ValueError):
            bridge.run(dict(operation='export', path='relative.md', text='notes'))
        with self.assertRaises(ValueError):
            bridge.run(dict(operation='ai', command='sh -c unsafe', task='expand', text='notes'))


if __name__ == '__main__':
    unittest.main()
