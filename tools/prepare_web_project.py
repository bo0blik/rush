"""Disable editor integrations in the disposable CI checkout before Web export."""
from pathlib import Path
import re
import shutil

root = Path(__file__).resolve().parents[1]
project = root / "project.godot"
config = project.read_text(encoding="utf-8")
for section in ("autoload", "editor_plugins"):
    config = re.sub(r"(?ms)^\[" + section + r"\]\n.*?(?=^\[|\Z)", "", config)
project.write_text(config, encoding="utf-8")
for directory in ("addons", "road_demos", "ref"):
    target = root / directory
    if target.is_dir():
        shutil.rmtree(target)
