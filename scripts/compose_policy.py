#!/usr/bin/env python3
import argparse
import pathlib
import sys
import yaml

def load_yaml(p):
    with open(p, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}

def merge(dst, src):
    for key, value in src.items():
        if key == "network_policies":
            dst.setdefault("network_policies", {})
            dst["network_policies"].update(value or {})
        elif isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value
    return dst

parser = argparse.ArgumentParser()
parser.add_argument("--base", required=True)
parser.add_argument("--preset", action="append", default=[])
parser.add_argument("--out", required=True)
args = parser.parse_args()

data = load_yaml(args.base)
for p in args.preset:
    data = merge(data, load_yaml(p))

with open(args.out, "w", encoding="utf-8") as f:
    yaml.safe_dump(data, f, sort_keys=False)
