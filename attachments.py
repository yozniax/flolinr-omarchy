"""Read embedded files without executing or modifying their source."""
import base64
import mimetypes
from pathlib import Path

MAX_BYTES = 2_000_000
LANGUAGES = {'.html':'html', '.htm':'html', '.css':'css', '.json':'json', '.js':'javascript', '.mjs':'javascript', '.ts':'typescript', '.tsx':'tsx', '.jsx':'jsx', '.py':'python', '.sh':'sh', '.bash':'bash', '.yaml':'yaml', '.yml':'yaml', '.xml':'xml', '.svg':'xml', '.toml':'toml', '.sql':'sql', '.c':'c', '.h':'c', '.cpp':'cpp', '.rs':'rust', '.go':'go', '.java':'java', '.rb':'ruby', '.qml':'qml', '.md':'markdown', '.markdown':'markdown', '.txt':'text', '.text':'text', '.csv':'csv', '.log':'text'}


def read_attachment(path):
    path = Path(path)
    if not path.is_file():
        raise ValueError('Choose a regular file')
    with path.open('rb') as stream:
        raw = stream.read(MAX_BYTES + 1)
    if len(raw) > MAX_BYTES:
        raise ValueError('Inserted files must be 2 MB or smaller')
    name = path.name
    if not name or len(name) > 255 or '\n' in name or '\r' in name:
        raise ValueError('Invalid attachment filename')
    mime = ('image/png' if raw.startswith(b'\x89PNG\r\n\x1a\n') else
            'image/jpeg' if raw.startswith(b'\xff\xd8\xff') else
            'image/gif' if raw[:6] in (b'GIF87a', b'GIF89a') else
            'image/webp' if raw[:4] == b'RIFF' and raw[8:12] == b'WEBP' else
            'image/bmp' if raw.startswith(b'BM') else '')
    if mime:
        return dict(kind='image', name=name, mime=mime, language='', content=base64.b64encode(raw).decode('ascii'))
    suffix = path.suffix.lower()
    if suffix in LANGUAGES:
        try:
            content = raw.decode('utf-8')
        except UnicodeDecodeError:
            raise ValueError('Text and code files must use UTF-8 encoding') from None
        return dict(kind='text' if LANGUAGES[suffix] in ('text', 'markdown') else 'code', name=name,
                    mime='text/plain', language=LANGUAGES[suffix], content=content)
    # Other formats remain downloadable files; never launch an external handler.
    return dict(kind='file', name=name, mime=mimetypes.guess_type(name)[0] or 'application/octet-stream',
                language='', content=base64.b64encode(raw).decode('ascii'))


def attachment_bytes(attachment):
    if attachment.get('kind') in ('image', 'file'):
        raw = base64.b64decode(attachment['content'], validate=True)
    elif attachment.get('kind') in ('text', 'code'):
        raw = attachment['content'].encode('utf-8')
    else:
        raise ValueError('Invalid attachment')
    if len(raw) > MAX_BYTES:
        raise ValueError('Inserted files must be 2 MB or smaller')
    return raw
