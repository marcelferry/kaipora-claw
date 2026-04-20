#!/usr/bin/env python3
import argparse
import sys
from pathlib import Path
import yaml

def deep_merge(base, extra):
    for key, value in extra.items():
        if key in base and isinstance(base[key], dict) and isinstance(value, dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base

def load_yaml(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f) or {}
    return data

def main():
    parser = argparse.ArgumentParser(description="Compose an OpenShell policy from base + presets.")
    parser.add_argument('--base', default='policy/base-policy.yaml', help='Base policy YAML')
    parser.add_argument('--preset-dir', default='policy/presets', help='Directory containing preset YAML files')
    parser.add_argument('--presets', nargs='*', default=[], help='Preset names without .yaml, e.g. npm pypi azure')
    parser.add_argument('--output', required=True, help='Output YAML path')
    args = parser.parse_args()

    merged = load_yaml(args.base)
    preset_dir = Path(args.preset_dir)

    for preset in args.presets:
        preset_file = preset_dir / f'{preset}.yaml'
        if not preset_file.exists():
            print(f'Preset not found: {preset_file}', file=sys.stderr)
            sys.exit(2)
        merged = deep_merge(merged, load_yaml(preset_file))

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with open(output, 'w', encoding='utf-8') as f:
        yaml.safe_dump(merged, f, sort_keys=False)

if __name__ == '__main__':
    main()
