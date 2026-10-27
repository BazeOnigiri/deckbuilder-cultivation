"""Telecharge les echantillons CC0 listes dans sources.json vers tools/sons/sources/ (ignore par git).

Lancement depuis la racine du projet :  python -I tools/sons/fetch_sources.py
Deja presents avec la bonne taille : pas retelecharges. Les sons du jeu se refont ensuite avec generate_sounds.py.
"""
import io
import json
import sys
import urllib.parse
import urllib.request
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEST = HERE / "sources"


def _get(url):
    with urllib.request.urlopen(url, timeout=60) as response:
        return response.read()


def _safe_target(root, name):
    """Refuse les chemins d'archive qui sortiraient du dossier (« ../ », chemin absolu)."""
    target = (root / name).resolve()
    if root.resolve() not in target.parents and target != root.resolve():
        raise ValueError("chemin d'archive refuse : %s" % name)
    return target


def fetch_archive(archive):
    root = DEST / archive["source"]
    if root.exists() and any(root.rglob("*.*")):
        print("deja la  %s" % archive["source"])
        return
    data = _get(archive["url"])
    with zipfile.ZipFile(io.BytesIO(data)) as zf:
        for info in zf.infolist():
            if info.is_dir():
                continue
            target = _safe_target(root, info.filename)
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(zf.read(info))
    print("extrait  %s (%d Ko)" % (archive["source"], len(data) // 1024))


def fetch_vcsl(vcsl):
    root = DEST / "vcsl"
    for entry in vcsl["files"]:
        target = _safe_target(root, entry["path"])
        if target.exists() and target.stat().st_size == entry["size"]:
            continue
        data = _get(vcsl["base"] + urllib.parse.quote(entry["path"]))
        if len(data) != entry["size"]:
            raise ValueError("%s : %d octets au lieu de %d" % (entry["path"], len(data), entry["size"]))
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print("vcsl     %s" % entry["path"])


def main():
    manifest = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))
    for archive in manifest["archives"]:
        fetch_archive(archive)
    fetch_vcsl(manifest["vcsl"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
