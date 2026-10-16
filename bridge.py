#!/usr/bin/env python3
"""Small stdin/stdout JSON bridge. Never replaces the live workspace or invokes a shell."""
import json
import os
from pathlib import Path
import sys
import tempfile
from urllib.parse import urlsplit, unquote
from interchange import detect_format, FORMATS, import_opml, export_opml, import_plaintext, export_plaintext

LIMIT = 2_000_000


def run(request):
    operation = request['operation']
    if operation in ('import', 'export', 'location'):
        raw_path = request['path']
        if raw_path.startswith('file:'):
            url = urlsplit(raw_path)
            if url.netloc not in ('', 'localhost'):
                raise ValueError('Choose a local file')
            raw_path = unquote(url.path)
        path = Path(raw_path).expanduser()
        if not path.is_absolute():
            raise ValueError('Use an absolute file path (or ~/...)')
        if operation == 'location' and path.exists():
            with path.open(encoding='utf-8') as stream:
                data = json.load(stream)
            if not isinstance(data, dict) or data.get('version') not in (1, 2):
                raise ValueError('The selected file is not a Flolinr workspace')
            return {'path': str(path)}
        if operation == 'import':
            with path.open(encoding='utf-8') as stream:
                text = stream.read(LIMIT + 1)
            if len(text) > LIMIT:
                raise ValueError('Import file exceeds 2 MB')
            format = detect_format(path, request.get('format', 'auto'))
            if format == 'opml':
                return {'format': format, **import_opml(text, path.stem)}
            if format == 'plaintext':
                return {'format': format, **import_plaintext(text, path.stem)}
            return {'format': format, 'text': text, 'name': path.stem}
        if operation == 'export':
            format = detect_format(path, request.get('format', 'auto'))
            if path.suffix.lower() not in FORMATS[format]:
                raise ValueError('The filename extension does not match the selected format')
            if request.get('protectedPath') and path.resolve() == Path(request['protectedPath']).expanduser().resolve():
                raise ValueError('Cannot export over the active workspace')
            text = export_opml(request['roll']) if format == 'opml' else export_plaintext(request['roll']) if format == 'plaintext' else request['text']
        else:
            text = request['text']
        path.parent.mkdir(parents=True, exist_ok=True)
        # FileDialog confirms replacements. Publish complete files atomically.
        fd, temporary = tempfile.mkstemp(prefix='.flolinr-export-', dir=path.parent)
        try:
            with os.fdopen(fd, 'w', encoding='utf-8') as stream:
                stream.write(text)
                stream.flush()
                os.fsync(stream.fileno())
            if operation == 'export' and request.get('overwrite') is True:
                os.replace(temporary, path)
            else:
                os.link(temporary, path)  # Exclusive publication, including new-location copies.
        finally:
            if os.path.exists(temporary):
                os.unlink(temporary)
        return {'path': str(path)}
    if operation.startswith('ai'):
        from ai_backend import run as run_ai
        # Preserve the documented custom-CLI bridge contract for older callers.
        if operation == 'ai' and 'connection' not in request and 'command' in request:
            request = dict(request, connection={'id': 'legacy-cli', 'name': 'Previous CLI',
                                               'provider': 'custom', 'command': request['command']})
        return run_ai(request)
    raise ValueError('Unknown operation')


def main():
    try:
        raw = sys.stdin.read(LIMIT + 1)
        if len(raw) > LIMIT:
            raise ValueError('Request exceeds 2 MB')
        print(json.dumps({'ok': True, **run(json.loads(raw))}, ensure_ascii=False))
    except Exception as error:
        print(json.dumps({'ok': False, 'error': str(error)}, ensure_ascii=False))
        sys.exit(1)


if __name__ == '__main__':
    main()
