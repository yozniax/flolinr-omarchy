"""OPML 2.0 and indentation-based plaintext outline exchange."""
import re
import xml.etree.ElementTree as ET

FORMATS = {'markdown': {'.md', '.markdown'}, 'opml': {'.opml'}, 'plaintext': {'.txt', '.text'}}


def detect_format(path, requested='auto'):
    if requested != 'auto':
        if requested not in FORMATS:
            raise ValueError('Choose OPML, Markdown or Plaintext')
        return requested
    for name, suffixes in FORMATS.items():
        if path.suffix.lower() in suffixes:
            return name
    raise ValueError('Unknown file extension. Select a format in the file dialog.')


def validate_items(items):
    if not isinstance(items, list) or len(items) > 50000:
        raise ValueError('Invalid or oversized outline')
    previous = -1
    for item in items:
        depth = item.get('depth')
        if type(depth) is not int or depth < 0 or depth > 256 or depth > previous + 1 or not isinstance(item.get('text'), str):
            raise ValueError('Invalid outline nesting or text')
        previous = depth
    return items


def import_opml(text, fallback):
    # Some outliners export literal XML-forbidden controls inside text attributes.
    # Repair only those unrepresentable characters, never surrounding user text.
    text, removed = re.subn(r'[\x00-\x08\x0b\x0c\x0e-\x1f\ud800-\udfff\ufffe\uffff]', '', text)
    def numeric_reference(match):
        nonlocal removed
        value = int(match.group(1)[1:], 16) if match.group(1).lower().startswith('x') else int(match.group(1))
        valid = value in (9, 10, 13) or 0x20 <= value <= 0xD7FF or 0xE000 <= value <= 0xFFFD or 0x10000 <= value <= 0x10FFFF
        if valid:
            return match.group(0)
        removed += 1
        return ''
    text = re.sub(r'&#(x[0-9a-fA-F]+|[0-9]+);', numeric_reference, text, flags=re.IGNORECASE)
    if re.search(r'<!\s*(DOCTYPE|ENTITY)\b', text, re.IGNORECASE):
        raise ValueError('OPML with DTD/entity declarations is not supported')
    root = ET.fromstring(text)
    tag = lambda element: element.tag.rsplit('}', 1)[-1]
    if tag(root) != 'opml':
        raise ValueError('Not an OPML document')
    body = next((e for e in root if tag(e) == 'body'), None)
    if body is None:
        raise ValueError('OPML body is missing')
    name = fallback
    for head in root:
        if tag(head) == 'head':
            for element in head:
                if tag(element) == 'title' and element.text and element.text.strip():
                    name = element.text.strip()
    items, stack = [], [(e, 0) for e in reversed(list(body)) if tag(e) == 'outline']
    while stack:
        element, depth = stack.pop()
        if depth > 256 or len(items) >= 50000:
            raise ValueError('OPML outline exceeds size/depth limits')
        items.append({'text': element.get('text', element.get('title', '')), 'depth': depth})
        stack.extend((e, depth + 1) for e in reversed(list(element)) if tag(e) == 'outline')
    result = {'name': name, 'items': validate_items(items)}
    if removed:
        result['warnings'] = [f'Removed {removed} XML-invalid control character(s). The original OPML file was not modified.']
    return result


def export_opml(roll):
    items = validate_items(roll['nodes'])
    for value in [roll['name']] + [item['text'] for item in items]:
        if re.search(r'[\x00-\x08\x0b\x0c\x0e-\x1f\ud800-\udfff\ufffe\uffff]', value):
            raise ValueError('Text contains characters that XML cannot represent')
    root = ET.Element('opml', version='2.0')
    ET.SubElement(ET.SubElement(root, 'head'), 'title').text = roll['name']
    body = ET.SubElement(root, 'body')
    parents = [body]
    for item in items:
        depth = item['depth']
        parents = parents[:depth + 1]
        parents.append(ET.SubElement(parents[depth], 'outline', text=item['text']))
    return ET.tostring(root, encoding='unicode', xml_declaration=True) + '\n'


def import_plaintext(text, fallback):
    lines = text.removeprefix('\ufeff').replace('\r\n', '\n').replace('\r', '\n').split('\n')
    if lines and lines[-1] == '':
        lines.pop()
    widths = [len(re.match(r'^[ \t]*', line).group().expandtabs(2)) for line in lines]
    baseline = min((width for width, line in zip(widths, lines) if line.strip()), default=0)
    items, levels = [], [0]
    for line, width in zip(lines, widths):
        indentation = re.match(r'^[ \t]*', line).group()
        width = max(0, width - baseline)
        while len(levels) > 1 and width < levels[-1]:
            levels.pop()
        if width > levels[-1]:
            levels.append(width)
        items.append({'text': line[len(indentation):], 'depth': len(levels) - 1})
    return {'name': fallback, 'items': validate_items(items)}


def export_plaintext(roll):
    items = validate_items(roll['nodes'])
    lines = []
    for item in items:
        # Plaintext has one item per line; multiline items become separate lines.
        lines.extend('  ' * item['depth'] + line for line in item['text'].split('\n'))
    return '\n'.join(lines) + ('\n' if lines else '')
