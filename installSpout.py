#!/usr/bin/env python3
import os
import platform
import sys
import urllib.request

if platform.system() != "Windows":
    print("Spout is Windows-only (DirectX texture sharing). Skipping.")
    sys.exit(0)

DLLS = {
    "SpoutLibrary.dll": "https://github.com/leadedge/Spout2/raw/refs/heads/master/SPOUTSDK/SpoutLibrary/SpoutLibraryExample/bin/SpoutLibrary.dll",
    "SpoutWrapper.dll": "https://github.com/merumerutho/SpoutWrapper/releases/download/1.1.0/SpoutWrapper.dll",
}

os.makedirs("dynlib", exist_ok=True)

for name, url in DLLS.items():
    dest = os.path.join("dynlib", name)
    print(f"Downloading {name}...")
    urllib.request.urlretrieve(url, dest)
    print(f"  -> {dest}")

print("Done. Spout DLLs installed in dynlib/.")
