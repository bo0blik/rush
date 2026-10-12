"""Install the single-threaded Web template from an official Godot release."""
import io
import json
import os
from pathlib import Path
import sys
import urllib.request
import zipfile

version = sys.argv[1] if len(sys.argv) > 1 else "4.7.2"
tag = version + "-stable"
request = urllib.request.Request(f"https://api.github.com/repos/godotengine/godot-builds/releases/tags/{tag}", headers={"User-Agent": "rush-web-build"})
with urllib.request.urlopen(request, timeout=60) as response:
    release = json.load(response)
asset = next(a for a in release["assets"] if a["name"] == f"Godot_v{tag}_export_templates.tpz")


class RemoteArchive(io.RawIOBase):
    def __init__(self):
        self.position = 0

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else asset["size"] + offset
        return self.position

    def read(self, count=-1):
        count = asset["size"] - self.position if count < 0 else min(count, asset["size"] - self.position)
        if count <= 0:
            return b""
        start = self.position
        request = urllib.request.Request(asset["browser_download_url"], headers={"User-Agent": "rush-web-build", "Range": f"bytes={start}-{start + count - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError("The download server must support range requests")
            data = response.read()
        if len(data) != count:
            raise RuntimeError("Incomplete template download")
        self.position += count
        return data


base = Path(os.environ["APPDATA"]) / "Godot" if os.name == "nt" else Path(os.environ.get("XDG_DATA_HOME", str(Path.home() / ".local/share"))) / "godot"
destination = base / "export_templates" / (version + ".stable")
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(RemoteArchive()) as archive:
    name = "web_nothreads_release.zip"
    data = archive.read("templates/" + name)
    (destination / name).write_bytes(data)
    print(f"Installed {name}: {len(data)} bytes")
