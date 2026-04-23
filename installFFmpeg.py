#!/usr/bin/env python3
import os
import platform
import subprocess
import sys
import urllib.request
import zipfile
import tarfile

URLS = {
    "Windows": "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl-shared.zip",
    "Linux": "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl-shared.tar.xz",
}

LIB_PREFIXES = ("avcodec", "avformat", "avutil", "swscale", "swresample")

DEST_DIR = "dynlib"

system = platform.system()


def install_from_archive(url):
    archive_name = url.rsplit("/", 1)[1]

    print(f"Downloading FFmpeg shared libraries for {system}...")
    urllib.request.urlretrieve(url, archive_name)

    os.makedirs(DEST_DIR, exist_ok=True)

    print("Extracting...")
    if archive_name.endswith(".zip"):
        with zipfile.ZipFile(archive_name) as zf:
            for entry in zf.namelist():
                basename = os.path.basename(entry)
                if "/bin/" in entry and basename.endswith(".dll") and any(basename.startswith(p) for p in LIB_PREFIXES):
                    dest = os.path.join(DEST_DIR, basename)
                    with zf.open(entry) as src, open(dest, "wb") as dst:
                        dst.write(src.read())
                    print(f"  -> {dest}")
    elif archive_name.endswith(".tar.xz"):
        with tarfile.open(archive_name, "r:xz") as tf:
            for member in tf.getmembers():
                basename = os.path.basename(member.name)
                if "/lib/" in member.name and any(basename.startswith("lib" + p) for p in LIB_PREFIXES) and ".so" in basename:
                    dest = os.path.join(DEST_DIR, basename)
                    with tf.extractfile(member) as src, open(dest, "wb") as dst:
                        dst.write(src.read())
                    print(f"  -> {dest}")

    print("Cleaning up...")
    os.remove(archive_name)


def install_macos():
    print("Installing FFmpeg via Homebrew...")
    try:
        subprocess.run(["brew", "--version"], check=True, capture_output=True)
    except FileNotFoundError:
        print("Homebrew not found. Install it from https://brew.sh then re-run this script.")
        sys.exit(1)

    subprocess.run(["brew", "install", "ffmpeg"], check=True)

    os.makedirs(DEST_DIR, exist_ok=True)

    brew_prefix = subprocess.run(["brew", "--prefix", "ffmpeg"], capture_output=True, text=True, check=True).stdout.strip()
    lib_dir = os.path.join(brew_prefix, "lib")
    for f in os.listdir(lib_dir):
        if any(f.startswith("lib" + p) for p in LIB_PREFIXES) and f.endswith(".dylib") and not os.path.islink(os.path.join(lib_dir, f)):
            src = os.path.join(lib_dir, f)
            dest = os.path.join(DEST_DIR, f)
            with open(src, "rb") as s, open(dest, "wb") as d:
                d.write(s.read())
            print(f"  -> {dest}")


if system == "Darwin":
    install_macos()
elif system in URLS:
    install_from_archive(URLS[system])
else:
    print(f"Unsupported platform: {system}")
    sys.exit(1)

print(f"Done. FFmpeg shared libraries installed in {DEST_DIR}/.")
