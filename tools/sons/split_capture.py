"""Decoupe l'enregistrement de ogg_capture.gd en un .wav par son : tools/sons/sources/wav/<source>/<nom>.wav.

python -I tools/sons/split_capture.py <chemin du f.wav enregistre par --write-movie>
"""
import json
import sys
import wave
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
SOURCES = HERE / "sources"
## Seuil de debut du son (pleine echelle) et marge gardee avant l'attaque.
ONSET = 0.002
PRE_ROLL = 0.005


def read_capture(path):
    with wave.open(str(path)) as f:
        channels, width, rate = f.getnchannels(), f.getsampwidth(), f.getframerate()
        raw = f.readframes(f.getnframes())
    dtype = {2: "<i2", 4: "<i4"}[width]
    data = np.frombuffer(raw, dtype).reshape(-1, channels).astype(np.float64).mean(axis=1)
    return data / float(2 ** (8 * width - 1)), rate


def main(capture_wav):
    plan = json.loads((SOURCES / "capture.json").read_text(encoding="utf-8"))
    audio, rate = read_capture(capture_wav)
    for sound in plan["sons"]:
        start = int(sound["frame"] / plan["fps"] * rate)
        window = audio[start:start + int((sound["length"] + 0.3) * rate)]
        loud = np.nonzero(np.abs(window) > ONSET)[0]
        assert len(loud) > 0, "silence pour %s" % sound["path"]
        begin = max(0, loud[0] - int(PRE_ROLL * rate))
        clip = window[begin:begin + int(sound["length"] * rate)]
        source = Path(sound["path"])
        out = SOURCES / "wav" / source.parent.relative_to(SOURCES).parts[0] / (source.stem + ".wav")
        out.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(out), "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(rate)
            f.writeframes((np.clip(clip, -1, 1) * 32767).astype("<i2").tobytes())
    print("%d sons decoupes" % len(plan["sons"]))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
