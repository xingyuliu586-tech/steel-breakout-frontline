"""Build the game's small Chinese font from text used by its scenes and scripts."""

from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont


ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets/fonts/NotoSansSC.ttf"
TARGET = ROOT / "assets/fonts/NotoSansSC-game.ttf"
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".json"}

characters = set(chr(code) for code in range(32, 127))
for path in [ROOT / "project.godot", *ROOT.joinpath("scenes").rglob("*"),
             *ROOT.joinpath("scripts").rglob("*"), *ROOT.joinpath("data").rglob("*")]:
    if path.name != "project.godot" and path.suffix not in TEXT_SUFFIXES:
        continue
    if path.is_file():
        characters.update(path.read_text(encoding="utf-8", errors="ignore"))

font = TTFont(SOURCE)
subsetter = subset.Subsetter()
subsetter.populate(unicodes={ord(char) for char in characters})
subsetter.subset(font)
font.save(TARGET)
print(f"{len(characters)} characters; {TARGET.stat().st_size:,} bytes")
