#!/usr/bin/env python3
"""Validate and install runtime files; never copy notes or user settings."""
import argparse
import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

SOURCE = Path(__file__).resolve().parent.parent
FILES = [
    'AiSettings.js', 'ai_backend.py',
    'FileTransfer.qml', 'interchange.py', 'CompactDialog.qml', 'ActionLink.qml', 'BarWidget.qml', 'Keybindings.js', 'KeyboardSettings.qml',
    'FlolinrIcon.qml', 'flolinr.svg', 'AppSettings.qml', 'QuickCapture.qml', 'FeaturePanel.qml', 'FeatureController.qml', 'bridge.py',
    'Model.js', 'OutlineNode.qml', 'ShortcutsDialog.qml', 'WorkspaceStore.qml',
    'LICENSE', 'README.md', 'keybindings.example.json',
    'docs/DEVELOPMENT.md', 'docs/HISTORY.md', 'Outliner.qml', 'manifest.json',
]


def main():
    config = Path(os.environ.get('XDG_CONFIG_HOME') or Path.home() / '.config')
    state = Path(os.environ.get('XDG_STATE_HOME') or Path.home() / '.local/state') / 'flolinr'
    plugin_id = json.loads((SOURCE / 'manifest.json').read_text())['id']
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--destination', type=Path, default=config / 'omarchy/plugins' / plugin_id)
    args = parser.parse_args()
    destination = args.destination.expanduser().absolute()
    if destination.resolve() == SOURCE:
        parser.error('destination must differ from the source directory')
    destination.parent.mkdir(parents=True, exist_ok=True)
    # Keep the completed package off the watched plugin tree. Directory renames
    # then expose the whole package at once, rather than dozens of partial edits.
    staging_parent = destination.parent.parent if destination.parent.name == 'plugins' else destination.parent
    with tempfile.TemporaryDirectory(prefix='.flolinr-package-', dir=staging_parent) as temporary:
        package = Path(temporary) / 'package'
        if destination.exists():
            shutil.copytree(destination, package)
        else:
            package.mkdir()
        for name in FILES:
            (package / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(SOURCE / name, package / name)
        subprocess.run(['omarchy', 'plugin', 'validate', str(package)], check=True)
        previous = Path(temporary) / 'previous'
        if destination.exists():
            stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f')
            backup = state / 'plugin-backups' / stamp
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copytree(destination, backup)
            print(f'Plugin backup: {backup}')
            destination.rename(previous)
        try:
            package.rename(destination)
        except OSError:
            if previous.exists():
                previous.rename(destination)
            raise
    subprocess.run(['omarchy', 'plugin', 'validate', str(destination)], check=True)
    print(f'Installed: {destination}')
    print('Existing notes and keybinding settings were not modified.')


if __name__ == '__main__':
    main()
