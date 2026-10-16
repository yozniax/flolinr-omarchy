import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

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

    def test_opml_roundtrip_preserves_unicode_multiline_and_hierarchy(self):
        with tempfile.TemporaryDirectory() as directory:
            roll = {'name': '仕事 & ideas', 'nodes': [
                {'text': 'Root <tag> "quoted"', 'depth': 0},
                {'text': '子項目\nsecond line', 'depth': 1},
                {'text': 'Next', 'depth': 0}]}
            path = str(Path(directory) / 'outline.opml')
            bridge.run(dict(operation='export', path=path, format='opml', roll=roll))
            result = bridge.run(dict(operation='import', path=path, format='auto'))
            self.assertEqual(result['name'], roll['name'])
            self.assertEqual(result['items'], roll['nodes'])

    def test_plaintext_roundtrip_and_file_url_with_spaces(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / '日本語 notes.txt'
            roll = {'name': 'Notes', 'nodes': [
                {'text': 'Root', 'depth': 0}, {'text': 'Child', 'depth': 1},
                {'text': 'Sibling', 'depth': 0}]}
            bridge.run(dict(operation='export', path=path.as_uri(), format='plaintext', roll=roll))
            result = bridge.run(dict(operation='import', path=path.as_uri(), format='auto'))
            self.assertEqual(result['items'], roll['nodes'])
            self.assertEqual(path.read_text(), 'Root\n  Child\nSibling\n')

    def test_confirmed_replacement_is_atomic_and_leaves_no_temporary_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'notes.md'
            path.write_text('old')
            bridge.run(dict(operation='export', path=str(path), text='new', overwrite=True))
            self.assertEqual(path.read_text(), 'new')
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_opml_rejects_entities_and_malformed_xml(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'bad.opml'
            path.write_text('<!DOCTYPE opml [<!ENTITY x "test">]><opml><body/></opml>')
            with self.assertRaises(ValueError):
                bridge.run(dict(operation='import', path=str(path), format='opml'))
            path = Path(directory) / 'malformed.opml'
            path.write_text('<opml><body><outline></body>')
            with self.assertRaises(ET.ParseError):
                bridge.run(dict(operation='import', path=str(path), format='opml'))

    def test_export_rejects_extension_mismatch_before_modifying_file(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'workspace.json'
            path.write_text('preserve')
            with self.assertRaises(ValueError):
                bridge.run(dict(operation='export', path=str(path), format='opml', overwrite=True,
                                roll={'name': 'Notes', 'nodes': []}))
            self.assertEqual(path.read_text(), 'preserve')

    def test_plaintext_accepts_common_indentation_widths_and_tabs(self):
        from interchange import import_plaintext
        result = import_plaintext('Root\n    Four spaces\n\tTab\nNext\n', 'Notes')
        self.assertEqual([item['depth'] for item in result['items']], [0, 1, 1, 0])

    def test_invalid_export_does_not_truncate_confirmed_destination(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'keep.opml'
            path.write_text('original')
            with self.assertRaises(ValueError):
                bridge.run(dict(operation='export', path=str(path), format='opml', overwrite=True,
                                roll={'name': 'Notes', 'nodes': [{'text': 'bad\x00text', 'depth': 0}]}))
            self.assertEqual(path.read_text(), 'original')

    def test_workflowy_opml_with_backspace_imports_with_a_warning(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'workflowy.opml'
            original = '<opml version="2.0"><head><title>Test</title></head><body><outline text="Parent"><outline text="before\x08after"/></outline></body></opml>'
            path.write_text(original)
            result = bridge.run(dict(operation='import', path=path.as_uri(), format='auto'))
            self.assertEqual(result['items'], [{'text': 'Parent', 'depth': 0}, {'text': 'beforeafter', 'depth': 1}])
            self.assertEqual(len(result['warnings']), 1)
            self.assertEqual(path.read_text(), original)

    def test_invalid_numeric_xml_controls_are_removed_but_valid_whitespace_survives(self):
        from interchange import import_opml
        result = import_opml('<opml><body><outline text="a&#8;b&#x00;c&#10;d&#9;e"/></body></opml>', 'Test')
        self.assertEqual(result['items'][0]['text'], 'abc\nd\te')
        self.assertIn('2 XML-invalid', result['warnings'][0])

    def test_repair_does_not_allow_obfuscated_entity_declarations(self):
        from interchange import import_opml
        with self.assertRaises(ValueError):
            import_opml('<!DOC\x08TYPE opml [<!ENTITY x "test">]><opml><body/></opml>', 'Test')


if __name__ == '__main__':
    unittest.main()
