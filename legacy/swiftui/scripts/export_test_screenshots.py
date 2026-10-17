#!/usr/bin/env python3
"""Copy deliberately named XCTest PNG attachments into docs/screenshots."""
import json
import re
import shutil
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = Path(sys.argv[1]) if len(sys.argv) > 1 else root / 'build/FinalScreenshots'
destination = root / 'docs/screenshots'
destination.mkdir(parents=True, exist_ok=True)
manifest = json.loads((source / 'manifest.json').read_text())

def visit(value):
    if isinstance(value, dict):
        name = value.get('suggestedHumanReadableName', '') or value.get('suggestedName', '')
        filename = value.get('exportedFileName', '') or value.get('filename', '')
        match = re.match(r'(\d{2}-[a-z-]+)(?:_|\.png)', name)
        if match and filename and (source / filename).exists():
            target = destination / (match.group(1) + '.png')
            shutil.copy2(source / filename, target)
            print(target.relative_to(root))
        for child in value.values(): visit(child)
    elif isinstance(value, list):
        for child in value: visit(child)

visit(manifest)
