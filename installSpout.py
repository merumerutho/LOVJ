#!/usr/bin/env python3
import os
import platform
import sys
import urllib.request
import zipfile

if platform.system() != "Windows":
    print("Spout is Windows-only (DirectX texture sharing). Skipping.")
    sys.exit(0)

SPOUT_URL = "https://github.com/leadedge/Spout2/releases/download/2.007.017/Spout-SDK-binaries_2-007-017_1.zip"
SPOUT_ZIP = "spout-sdk.zip"
SPOUT_BIN_DIR = "Spout-SDK-binaries/Libs_2-007-017/MD/bin"
DEST_DIR = "dynlib"

os.makedirs(DEST_DIR, exist_ok=True)

print("Downloading Spout SDK...")
urllib.request.urlretrieve(SPOUT_URL, SPOUT_ZIP)

print("Extracting SpoutLibrary.dll...")
with zipfile.ZipFile(SPOUT_ZIP) as zf:
    for entry in zf.namelist():
        basename = os.path.basename(entry)
        if entry.startswith(SPOUT_BIN_DIR) and basename == "SpoutLibrary.dll":
            dest = os.path.join(DEST_DIR, basename)
            with zf.open(entry) as src, open(dest, "wb") as dst:
                dst.write(src.read())
            print(f"  -> {dest}")

os.remove(SPOUT_ZIP)

print("Done. SpoutLibrary.dll installed in dynlib/.")
