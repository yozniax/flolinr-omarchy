import base64
from pathlib import Path
import sys
import tempfile
import unittest
from urllib.parse import quote
import json
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import attachments
import bridge


class AttachmentTests(unittest.TestCase):
    def test_opml_and_plaintext_preserve_embedded_metadata_and_item_depth(self):
        attachment=dict(kind='code',name='a.json',mime='text/plain',language='json',content='  {\n    "x": 1\n  }\r\n')
        text='File title\n<!-- flolinr-attachment:'+quote(json.dumps(dict(attachment=attachment)),safe='')+' -->'
        roll=dict(name='Notes',nodes=[dict(text='Parent',depth=0),dict(text=text,depth=1),dict(text='After',depth=0)])
        with tempfile.TemporaryDirectory() as directory:
            for format,suffix in [('opml','.opml'),('plaintext','.txt')]:
                with self.subTest(format=format):
                    path=Path(directory)/('notes'+suffix)
                    bridge.run(dict(operation='export',path=str(path),format=format,roll=roll))
                    result=bridge.run(dict(operation='import',path=str(path),format=format))
                    self.assertEqual(result['items'],roll['nodes'])

    def test_text_code_and_images_are_copied_without_modifying_source(self):
        cases = [('.md', b'# Heading\r\n\n  - indented\n', 'text'),
                 ('.html', b'  <script>doNotRun()</script>\n\t<div/>\n', 'code'),
                 ('.json', b'{\n  "x": [1, 2]\n}\n', 'code'),
                 ('.png', base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNoOPD/PwAHQgM/vskMEgAAAABJRU5ErkJggg=='), 'image'),
                 ('.bin', b'\x00\xff\x01', 'file'), ('.bin', b'', 'file')]
        with tempfile.TemporaryDirectory() as directory:
            for suffix, content, kind in cases:
                with self.subTest(suffix=suffix, content_length=len(content)):
                    source = Path(directory) / ('日本語 #%' + suffix)
                    source.write_bytes(content)
                    response = bridge.run(dict(operation='attachment_import', path=source.as_uri()))
                    a = response['attachment']
                    self.assertEqual(a['kind'], kind)
                    self.assertEqual(attachments.attachment_bytes(a), content)
                    self.assertEqual(source.read_bytes(), content)
                    saved = Path(directory) / ('saved' + suffix)
                    bridge.run(dict(operation='attachment_export', path=saved.as_uri(), attachment=a))
                    self.assertEqual(saved.read_bytes(), content)

    def test_svg_is_source_text_and_binary_is_not_executed(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / 'untrusted.svg'
            source.write_text('<svg><image href="https://example.org/private"/></svg>')
            a = attachments.read_attachment(source)
            self.assertEqual(a['kind'], 'code')
            self.assertEqual(a['language'], 'xml')

    def test_bad_encoding_size_remote_url_and_workspace_overwrite_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'code.json'
            source.write_bytes(b'\xff')
            with self.assertRaisesRegex(ValueError, 'UTF-8'): attachments.read_attachment(source)
            source.write_bytes(b'x' * (attachments.MAX_BYTES + 1))
            with self.assertRaisesRegex(ValueError, '2 MB'): attachments.read_attachment(source)
            with self.assertRaises(ValueError): bridge.run(dict(operation='attachment_import', path='file://remote/share/a.txt'))
            with self.assertRaises(ValueError): attachments.read_attachment(root)
            workspace = root / 'outline.json'; workspace.write_text('do not replace')
            a = dict(kind='code', content='replacement')
            with self.assertRaisesRegex(ValueError, 'workspace'):
                bridge.run(dict(operation='attachment_export', path=str(workspace), protectedPath=str(workspace), attachment=a))
            self.assertEqual(workspace.read_text(), 'do not replace')


if __name__ == '__main__': unittest.main()
