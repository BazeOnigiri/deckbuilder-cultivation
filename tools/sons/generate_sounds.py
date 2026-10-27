"""Synthese des sons du jeu : lit recettes.json, ecrit des .wav dans res://audio/sfx/.

Lancement depuis la racine du projet :  python -I tools/sons/generate_sounds.py
Chaque recette est un son ; une recette « couches » superpose d'autres recettes decalees dans le temps.
Le resultat est deterministe (graine fixe par son) : relancer le script redonne les memes fichiers.
"""
import json
import sys
import wave
import zlib
from pathlib import Path

import numpy as np

RATE = 44100
ROOT = Path(__file__).resolve().parents[2]
RECIPES = Path(__file__).with_name("recettes.json")


def _time(duration):
    return np.arange(int(duration * RATE)) / RATE


def _envelope(n, attack, decay):
    """Attaque lineaire puis decroissance exponentielle (decay = temps pour perdre ~63 %)."""
    t = np.arange(n) / RATE
    env = np.exp(-t / max(decay, 1e-4))
    a = int(attack * RATE)
    if a > 0:
        env[:a] *= np.linspace(0.0, 1.0, a)
    return env


def _lowpass(signal, cutoff):
    """Passe-bas d'ordre 1, cutoff en Hz (scalaire ou tableau de la meme longueur que le signal)."""
    cutoff = np.broadcast_to(np.asarray(cutoff, dtype=float), signal.shape)
    alpha = 1.0 - np.exp(-2.0 * np.pi * cutoff / RATE)
    out = np.empty_like(signal)
    y = 0.0
    for i, x in enumerate(signal):
        y += alpha[i] * (x - y)
        out[i] = y
    return out


def pluck(r, rng):
    """Corde pincee (Karplus-Strong) : deux cordes un peu desaccordees, facon guzheng."""
    n = int(r["duration"] * RATE)
    out = np.zeros(n)
    for detune in (0.0, r.get("detune", 3.0)):
        period = int(RATE / (r["freq"] * 2 ** (detune / 1200)))
        buf = rng.uniform(-1, 1, period)
        buf = _lowpass(buf, r.get("brightness", 6000))
        blend = r.get("damping", 0.996)
        string = np.empty(n)
        for i in range(n):
            j = i % period
            string[i] = buf[j]
            buf[j] = blend * 0.5 * (buf[j] + buf[(j + 1) % period])
        out += string
    return out * _envelope(n, 0.0, r.get("decay", 1.0))


def partials(r, rng):
    """Gong ou cloche : partiels inharmoniques, chacun sa decroissance ; glide = montee de hauteur (gong)."""
    t = _time(r["duration"])
    out = np.zeros_like(t)
    glide = 1.0 + r.get("glide", 0.0) * (1.0 - np.exp(-t / 0.3))
    for k, ratio in enumerate(r["ratios"]):
        phase = 2 * np.pi * np.cumsum(r["freq"] * ratio * glide) / RATE
        decay = r["decay"] / (1.0 + k * r.get("decay_spread", 0.5))
        out += np.sin(phase + rng.uniform(0, 2 * np.pi)) * _envelope(len(t), r.get("attack", 0.002), decay) / (k + 1) ** 0.6
    if r.get("strike", 0.0) > 0:
        noise = _lowpass(rng.uniform(-1, 1, len(t)), r.get("strike_cutoff", 3000))
        out += r["strike"] * noise * _envelope(len(t), 0.0, 0.02)
    return out


def breath(r, rng):
    """Souffle : bruit filtre dont la coupure glisse de cutoff_from a cutoff_to (encre, papier, orbe)."""
    t = _time(r["duration"])
    cutoff = np.geomspace(r["cutoff_from"], r["cutoff_to"], len(t))
    noise = rng.uniform(-1, 1, len(t))
    # Plusieurs poles : pente plus raide, le souffle reste doux au lieu de siffler.
    for _ in range(r.get("poles", 4)):
        noise = _lowpass(noise, cutoff)
    # Enveloppe en cloche : monte jusqu'a peak (fraction de la duree) puis retombe.
    x = t / r["duration"]
    peak = r.get("peak", 0.3)
    env = np.where(x < peak, x / peak, (1 - x) / (1 - peak)) ** r.get("curve", 1.5)
    return noise * env


def knock(r, rng):
    """Coup sourd ou clic de bois : sinus dont la hauteur chute vite, plus un claquement de bruit."""
    t = _time(r["duration"])
    freq = r["freq_to"] + (r["freq"] - r["freq_to"]) * np.exp(-t / r.get("sweep", 0.02))
    body = np.sin(2 * np.pi * np.cumsum(freq) / RATE) * _envelope(len(t), 0.001, r["decay"])
    click = _lowpass(rng.uniform(-1, 1, len(t)), r.get("click_cutoff", 4000)) * _envelope(len(t), 0.0, 0.004)
    return body + r.get("click", 0.3) * click


def sparkle(r, rng):
    """Cristaux : petites cloches aigues egrenees, hauteurs tirees dans une gamme."""
    n = int(r["duration"] * RATE)
    out = np.zeros(n)
    for i in range(r["count"]):
        freq = r["freq"] * 2 ** (rng.choice(r["scale"]) / 12)
        tone = partials({"freq": freq, "ratios": [1.0, 2.76, 5.4], "duration": r["ring"], "decay": r["ring"] / 3}, rng)
        start = int(i * r["spacing"] * RATE)
        end = min(n, start + len(tone))
        out[start:end] += tone[: end - start] * (1.0 - 0.5 * i / r["count"])
    return out


def layers(r, rng, recipes):
    """Superpose d'autres recettes : [{"use": id, "at": secondes, "gain": x}]."""
    parts = [(int(layer.get("at", 0.0) * RATE), layer.get("gain", 1.0), render(recipes[layer["use"]], recipes))
             for layer in r["layers"]]
    out = np.zeros(max(start + len(sound) for start, _, sound in parts))
    for start, gain, sound in parts:
        out[start:start + len(sound)] += gain * sound / max(np.abs(sound).max(), 1e-9)
    return out


KINDS = {"pluck": pluck, "partials": partials, "breath": breath, "knock": knock, "sparkle": sparkle}


def render(r, recipes):
    rng = np.random.default_rng(zlib.crc32(r["id"].encode()))
    sound = layers(r, rng, recipes) if r["kind"] == "layers" else KINDS[r["kind"]](r, rng)
    fade = min(len(sound), int(0.01 * RATE))
    sound[-fade:] *= np.linspace(1.0, 0.0, fade)
    return sound


def normalize(sound, gain):
    return sound * gain / max(np.abs(sound).max(), 1e-9)


def write_wav(path, sound):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (np.clip(sound, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())


def check(sound, r):
    """Garde-fous : pas de saturation, pas de silence, duree attendue."""
    peak = np.abs(sound).max()
    assert peak <= 1.0, "%s sature" % r["id"]
    assert peak > 0.1, "%s quasi silencieux" % r["id"]
    assert len(sound) >= int(0.02 * RATE), "%s trop court" % r["id"]


def main():
    data = json.loads(RECIPES.read_text(encoding="utf-8"))
    recipes = {r["id"]: r for r in data["recettes"]}
    out_dir = ROOT / data["dossier"]
    for r in data["recettes"]:
        if not r.get("export", True):
            continue
        sound = normalize(render(r, recipes), r.get("gain", 0.8))
        check(sound, r)
        write_wav(out_dir / (r["id"] + ".wav"), sound)
        print("%-20s %.2f s" % (r["id"], len(sound) / RATE))
    return 0


if __name__ == "__main__":
    sys.exit(main())
