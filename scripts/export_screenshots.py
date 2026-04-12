#!/usr/bin/env python3
"""
Reads manifest.json from xcresulttool export attachments output,
renames UUID files to their tag names, and copies to Screenshots/.
"""
import json
import os
import shutil
import sys

tmp_dir = sys.argv[1]
dest_dir = sys.argv[2]

manifest_path = os.path.join(tmp_dir, "manifest.json")
data = json.load(open(manifest_path))

groups = data if isinstance(data, list) else [data]
count = 0

for group in groups:
    for att in group.get("attachments", []):
        src = os.path.join(tmp_dir, att["exportedFileName"])
        name = att.get("suggestedHumanReadableName", att["exportedFileName"])
        # name is like "overview_0_<UUID>.png" — take the part before "_0_"
        tag = name.split("_0_")[0] if "_0_" in name else os.path.splitext(name)[0]
        dest = os.path.join(dest_dir, tag + ".png")
        shutil.copy(src, dest)
        count += 1
        print(f"  {tag}.png")

print(f"✓ Exported {count} screenshots to {dest_dir}/")
