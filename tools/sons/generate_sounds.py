"""Sons du jeu : lit recettes.json, ecrit des .wav dans res://audio/sfx/ (ou le dossier de la recette)
et une fiche SoundCue (.tres) par son dans res://content/sons/ (reglages du bloc "cue" de la recette).

Lancement depuis la racine du projet :  python -I tools/sons/generate_sounds.py [id ...]  (sans id : tout)
- « sample » : extrait d'un echantillon CC0 de tools/sons/sources/ (fetch_sources.py, puis ogg_capture.gd et
  split_capture.py pour les .ogg) ; « layers » : superpose d'autres recettes decalees dans le temps.
- « partition » : un arrangement de la musique ecrite dans partition.json, en boucle sans couture.
- "variantes" : liste de champs qui remplacent ceux de la recette, une prise par entree (<id>_1.wav, <id>_2.wav...) ;
  la fiche les liste toutes et le jeu en tire une differente a chaque fois.
Post-traitements communs : filtres, saturation, reverberation. Deterministe (graine fixe par son).
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
SOURCES = Path(__file__).with_name("sources")
NOTE_NAMES = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
_samples = {}
_tracks = {}


def load_sample(name):
    """Echantillon mono a RATE, en flottants. name : chemin relatif a tools/sons/sources/ (16 ou 24 bits, mono ou stereo)."""
    if name not in _samples:
        with wave.open(str(SOURCES / name)) as f:
            channels, width, rate = f.getnchannels(), f.getsampwidth(), f.getframerate()
            raw = f.readframes(f.getnframes())
        if width == 3:
            b = np.frombuffer(raw, np.uint8).reshape(-1, 3).astype(np.int32)
            data = (b[:, 0] | (b[:, 1] << 8) | (b[:, 2] << 16))
            data = np.where(data >= 1 << 23, data - (1 << 24), data) / float(1 << 23)
        else:
            data = np.frombuffer(raw, {2: "<i2", 4: "<i4"}[width]) / float(2 ** (8 * width - 1))
        data = data.reshape(-1, channels).mean(axis=1)
        _samples[name] = _resample(data, RATE / rate)
    return _samples[name]


def _trimmed(name):
    """Echantillon sans son silence d'entree, crete a 1 : l'attaque tombe pile sur la note."""
    data = load_sample(name)
    loud = np.nonzero(np.abs(data) > 0.02 * np.abs(data).max())[0]
    onset = max(0, loud[0] - int(0.002 * RATE)) if len(loud) else 0
    data = data[onset:]
    return data / max(np.abs(data).max(), 1e-9)


def _resample(signal, ratio):
    """ratio > 1 : plus d'echantillons (plus long, plus grave a la lecture)."""
    if abs(ratio - 1.0) < 1e-9:
        return signal.copy()
    n = int(len(signal) * ratio)
    return np.interp(np.arange(n) / ratio, np.arange(len(signal)), signal)


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


def _highpass(signal, cutoff):
    return signal - _lowpass(signal, cutoff)


def sample(r, rng):
    """Extrait d'un echantillon : debut et longueur en secondes, transposition en demi-tons, fondu de sortie."""
    data = _trimmed(r["file"])
    start = int(r.get("start", 0.0) * RATE)
    clip = data[start:start + int(r["length"] * RATE)] if "length" in r else data[start:]
    if r.get("reverse"):
        clip = clip[::-1]
    clip = _resample(clip, 2 ** (-r.get("pitch", 0.0) / 12))
    fade = min(len(clip), int(r.get("fade_out", 0.05) * RATE))
    clip[len(clip) - fade:] *= np.linspace(1.0, 0.0, fade) ** 2
    attack = int(r.get("fade_in", 0.0) * RATE)
    if attack > 0:
        clip[:attack] *= np.linspace(0.0, 1.0, attack)
    return clip


def _room(rng, size, tone):
    """Reponse de salle synthetique : bruit qui decroit, assombri, d'energie 1."""
    n = int(size * RATE)
    ir = _lowpass(rng.uniform(-1, 1, n) * np.exp(-np.arange(n) / (size * RATE / 5.0)), tone)
    return ir / np.sqrt((ir ** 2).sum())


def reverb(signal, rng, size, mix, tone=6000.0):
    """Reverberation par convolution (FFT) ; le signal s'allonge de la queue de salle."""
    ir = _room(rng, size, tone)
    size_fft = 1 << int(np.ceil(np.log2(len(signal) + len(ir))))
    wet = np.fft.irfft(np.fft.rfft(signal, size_fft) * np.fft.rfft(ir, size_fft), size_fft)[:len(signal) + len(ir)]
    dry = np.concatenate([signal, np.zeros(len(ir))])
    wet *= np.abs(dry).max() / max(np.abs(wet).max(), 1e-9)
    return dry * (1.0 - mix) + wet * mix


def post(sound, r, rng):
    """Post-traitements optionnels de toute recette, dans l'ordre : passe-haut, passe-bas, saturation, reverb."""
    if "highpass" in r:
        sound = _highpass(sound, r["highpass"])
    if "lowpass" in r:
        sound = _lowpass(sound, r["lowpass"])
    if "drive" in r:
        sound = np.tanh(sound * r["drive"] / max(np.abs(sound).max(), 1e-9))
    if "reverb" in r:
        sound = reverb(sound, rng, r["reverb"]["size"], r["reverb"]["mix"], r["reverb"].get("tone", 6000.0))
        # La queue de reverb s'eteint en silence, sans coupure seche.
        tail = int(r["reverb"]["size"] * RATE)
        sound[-tail:] *= np.linspace(1.0, 0.0, tail) ** 2
    return sound


def layers(r, rng, recipes):
    """Superpose d'autres recettes : [{"use": id, "at": secondes, "gain": x}]."""
    parts = [(int(layer.get("at", 0.0) * RATE), layer.get("gain", 1.0), render(recipes[layer["use"]], recipes))
             for layer in r["layers"]]
    out = np.zeros(max(start + len(sound) for start, _, sound in parts))
    for start, gain, sound in parts:
        out[start:start + len(sound)] += gain * sound / max(np.abs(sound).max(), 1e-9)
    return out


# --- Musique : partition.json rendue piste par piste, en boucle (tout ce qui deborde revient au debut). ---

def midi(name):
    return 12 * (int(name[-1]) + 1) + NOTE_NAMES[name[:-1]]


def _place(out, clip, start):
    """Ajoute clip a out a partir de start, modulo la longueur de la boucle."""
    n = len(out)
    start %= n
    while len(clip) > 0:
        end = min(n, start + len(clip))
        out[start:end] += clip[:end - start]
        clip = clip[end - start:]
        start = 0


def _cithare(score, note, dur, vibrato):
    """Note de Dan Tranh : l'echantillon le plus proche, transpose ; vibrato qui s'installe sur les notes longues."""
    samples = score["echantillons"]
    notes = {int(k): v for k, v in samples["cithare_notes"].items()}
    base = min(notes, key=lambda m: abs(m - note))
    data = _trimmed(samples["cithare"].format(note=notes[base]))
    play = score["jeu"]
    length = int((dur + play["relache_s"]) * RATE)
    t = np.arange(length) / RATE
    speed = 2 ** ((note - base) / 12) * (1 + vibrato * np.sin(2 * np.pi * play["vibrato_hz"] * t) * np.clip(t / 0.4, 0, 1))
    pos = np.cumsum(speed)
    pos = pos[pos < len(data) - 1]
    clip = np.interp(pos, np.arange(len(data)), data)
    hold = int(dur * RATE)
    if len(clip) > hold:
        clip[hold:] *= np.linspace(1.0, 0.0, len(clip) - hold) ** 2
    return clip


def _pad(score, notes, seconds):
    """Nappe chaude : dents de scie a bande limitee (additive), trois voix desaccordees, attaque et relache lentes.
    notes : numeros MIDI."""
    cfg = score["jeu"]["nappe"]
    length = int((seconds + cfg["relache_s"]) * RATE)
    t = np.arange(length) / RATE
    out = np.zeros(length)
    for note in notes:
        freq = 440.0 * 2 ** ((note - 69) / 12)
        for cents in (-cfg["desaccord_cents"], 0.0, cfg["desaccord_cents"]):
            f = freq * 2 ** (cents / 1200)
            for k in range(1, int(cfg["aigu_hz"] / f) + 1):
                out += np.sin(2 * np.pi * f * k * t + k) / k * (1 - f * k / cfg["aigu_hz"])
    env = np.clip(t / cfg["attaque_s"], 0, 1) * np.clip((length / RATE - t) / cfg["relache_s"], 0, 1)
    return out * env


def _render_tracks(score, rng):
    """Chaque piste de la partition dans sa propre boucle (meme longueur pour toutes les variantes)."""
    beat = 60.0 / score["bpm"]
    bar = beat * score["temps_par_mesure"]
    n = int(round(score["mesures"] * bar * RATE))
    play = score["jeu"]
    tracks = {}

    def at(bar_index, beats):
        # Swing : les croches du contretemps arrivent un peu en retard ; leger jeu humain.
        swing = score["swing"] * beat * 0.5 if abs(beats % 1 - 0.5) < 1e-6 else 0.0
        return int(((bar_index - 1) * bar + beats * beat + swing + rng.normal(0, play["humain_s"])) * RATE)

    def vel(value):
        return value * (1 + rng.uniform(-play["humain_velocite"], play["humain_velocite"]))

    def source(chord, kind):
        # Notes d'ou piochent arpeges et nappes : celles de l'accord, ou la basse et sa quinte.
        root = midi(chord["basse"])
        return [midi(note) for note in chord["notes"]] if kind == "accord" else [root, root + 7]

    chords = []
    for chord in score["accords"]:
        chords += [chord] * chord["mesures"]
    names = ["basse", "melodie", *score["arpeges"], *score["nappes"], *score["frappes"], *score["par_mesures"],
             *score["bruits"]]
    tracks = {name: np.zeros(n) for name in names}
    for b, chord in enumerate(chords, start=1):
        root = midi(chord["basse"])
        for beats, offset, v, dur in score["basse"]:
            clip = _cithare(score, root + offset, dur * beat, 0.0) * vel(v)
            freq = 440.0 * 2 ** ((root + offset - 69) / 12)
            t = np.arange(len(clip)) / RATE
            clip = clip + play["sous_basse"] * v * np.sin(2 * np.pi * freq * t) * np.exp(-t / (dur * beat))
            _place(tracks["basse"], clip, at(b, beats))
        for name, cfg in score["arpeges"].items():
            notes = source(chord, cfg["source"])
            for beats, index, v, dur in cfg["motif"]:
                note = notes[index % len(notes)] + cfg["octave"]
                _place(tracks[name], _cithare(score, note, dur * beat, 0.0) * vel(v), at(b, beats))
    start_bar = 1
    for chord in score["accords"]:
        for name, cfg in score["nappes"].items():
            # Nappe d'accord : toutes ses notes ; bourdon : intervalles au-dessus de la basse seule.
            base = source(chord, "accord") if cfg["source"] == "accord" else [midi(chord["basse"])]
            notes = [note + step for note in base for step in cfg["intervalles"]]
            _place(tracks[name], _pad(score, notes, chord["mesures"] * bar), at(start_bar, 0))
        start_bar += chord["mesures"]
    for b, beats, note, dur in score["melodie"]:
        vibrato = play["vibrato"] if dur >= play["vibrato_des"] else 0.0
        _place(tracks["melodie"], _cithare(score, midi(note), dur * beat, vibrato) * vel(0.8), at(b, beats))
    for name, hits in score["frappes"].items():
        clip = _trimmed(score["echantillons"][name])
        for b in range(1, score["mesures"] + 1):
            for beats, v in hits:
                _place(tracks[name], clip * vel(v), at(b, beats))
    for name, bars in score["par_mesures"].items():
        clip = _trimmed(score["echantillons"][name])
        for b in bars:
            _place(tracks[name], clip * vel(0.8), at(b, 0))
    for name, cfg in score["bruits"].items():
        # Bruit filtre en frequence (circulaire) qui respire un nombre entier de fois par boucle : sans couture.
        spectrum = np.fft.rfft(rng.normal(0, 1, n))
        freqs = np.fft.rfftfreq(n, 1.0 / RATE)
        spectrum[(freqs < cfg["passe_haut"]) | (freqs > cfg["passe_bas"])] = 0
        breath = 0.5 * (1 - np.cos(2 * np.pi * cfg["respirations"] * np.arange(n) / n))
        tracks[name] = np.fft.irfft(spectrum, n) * breath
    return tracks


def _fft_lowpass(signal, cutoff):
    """Passe-bas d'ordre 2 dans le domaine frequentiel : circulaire, donc sans couture pour une boucle."""
    spectrum = np.fft.rfft(signal)
    freqs = np.fft.rfftfreq(len(signal), 1.0 / RATE)
    return np.fft.irfft(spectrum / np.sqrt(1 + (freqs / cutoff) ** 4), len(signal))


def _score(r):
    """Partition de la recette et ses pistes rendues, en cache : les arrangements partagent les memes pistes."""
    path = Path(__file__).with_name(r["file"])
    if path not in _tracks:
        score = json.loads(path.read_text(encoding="utf-8"))
        _tracks[path] = (score, _render_tracks(score, np.random.default_rng(zlib.crc32(r["file"].encode()))))
    return _tracks[path]


def output_rate(r):
    """La musique est filtree sous 10 kHz : 22 kHz suffisent et divisent sa taille par deux."""
    return _score(r)[0]["frequence"] if r["kind"] in LOOPS else RATE


def partition(r, rng):
    """Un arrangement de la musique : ses pistes a leurs volumes, puis le grain cassette (passe-bas, pleurage,
    saturation douce) et une reverb circulaire. La boucle se raccorde exactement."""
    score, tracks = _score(r)
    variant = score["arrangements"][r["variante"]]
    mix = sum(gain * tracks[name] / max(np.abs(tracks[name]).max(), 1e-9) for name, gain in variant["pistes"].items())
    n = len(mix)
    mix = _fft_lowpass(mix, variant["passe_bas"])
    play = score["jeu"]
    # Pleurage : la lecture accelere et ralentit un peu, comme une bande ; nombre entier de cycles sur la boucle.
    cycles = max(1, round(n / RATE * play["pleurage_hz"]))
    delay = play["pleurage_s"] * RATE * 0.5 * (1 + np.sin(2 * np.pi * cycles * np.arange(n) / n))
    mix = np.interp((np.arange(n) - delay) % n, np.arange(n + 1), np.concatenate([mix, mix[:1]]))
    mix = np.tanh(mix * play["saturation"] / max(np.abs(mix).max(), 1e-9))
    room = _room(rng, 1.8, 5000.0)
    wet = np.fft.irfft(np.fft.rfft(mix) * np.fft.rfft(room, n), n)
    wet *= np.abs(mix).max() / max(np.abs(wet).max(), 1e-9)
    mix = mix * (1 - variant["reverb"]) + wet * variant["reverb"]
    # Reechantillonnage par FFT : circulaire lui aussi, la boucle reste sans couture.
    size = int(round(n * output_rate(r) / RATE))
    return np.fft.irfft(np.fft.rfft(mix)[:size // 2 + 1], size) * size / n


KINDS = {"sample": sample}
LOOPS = {"partition": partition}


def render(r, recipes):
    rng = np.random.default_rng(zlib.crc32(r["id"].encode()))
    if r["kind"] in LOOPS:
        return LOOPS[r["kind"]](r, rng)
    sound = layers(r, rng, recipes) if r["kind"] == "layers" else KINDS[r["kind"]](r, rng)
    sound = post(sound, r, rng)
    fade = min(len(sound), int(0.01 * RATE))
    sound[-fade:] *= np.linspace(1.0, 0.0, fade)
    return sound


def normalize(sound, gain):
    return sound * gain / max(np.abs(sound).max(), 1e-9)


def write_wav(path, sound, rate):
    path.parent.mkdir(parents=True, exist_ok=True)
    data = (np.clip(sound, -1.0, 1.0) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(data.tobytes())


CUE_TEMPLATE = """[gd_resource type="Resource" script_class="SoundCue" format=3]

[ext_resource type="Script" path="res://ui/audio/sound_cue.gd" id="1_cue"]
{streams}
[resource]
script = ExtResource("1_cue")
id = &"{id}"
streams = Array[AudioStream]([{refs}])
volume_db = {volume_db}
bus = &"{bus}"
pitch_variance = {pitch_variance}
volume_variance = {volume_variance}
scale = PackedInt32Array({scale})
"""
CUE_DEFAULTS = {"volume_db": 0.0, "bus": "Effets", "pitch_variance": 0.03, "volume_variance": 0.0, "scale": []}


def take_names(r):
    """Noms des fichiers d'une recette : <id> seul, ou <id>_1, <id>_2... avec des variantes."""
    count = len(r.get("variantes", []))
    return ["%s_%d" % (r["id"], i) for i in range(1, count + 1)] if count else [r["id"]]


def write_cue(path, folder, r):
    """Pas d'uid dans la fiche : Godot l'ajoute lui-meme (en inventer un casserait les references)."""
    cue = dict(CUE_DEFAULTS, **r.get("cue", {}))
    names = take_names(r)
    streams = "".join('[ext_resource type="AudioStream" path="res://%s/%s.wav" id="%d_son"]\n' % (folder, name, i + 2)
                      for i, name in enumerate(names))
    text = CUE_TEMPLATE.format(id=r["id"], streams=streams, refs=", ".join('ExtResource("%d_son")' % (i + 2) for i in range(len(names))),
                               volume_db=float(cue["volume_db"]), bus=cue["bus"], pitch_variance=float(cue["pitch_variance"]),
                               volume_variance=float(cue["volume_variance"]), scale=", ".join(str(int(x)) for x in cue["scale"]))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def check(sound, r):
    """Garde-fous : pas de saturation, pas de silence, duree attendue, raccord de boucle."""
    peak = np.abs(sound).max()
    assert peak <= 1.0, "%s sature" % r["id"]
    assert peak > 0.1, "%s quasi silencieux" % r["id"]
    assert len(sound) >= int(0.02 * RATE), "%s trop court" % r["id"]
    if r["kind"] in LOOPS:
        step = np.abs(np.diff(sound)).max()
        assert abs(sound[-1] - sound[0]) <= 2 * step, "%s : raccord de boucle" % r["id"]


def main():
    data = json.loads(RECIPES.read_text(encoding="utf-8"))
    recipes = {r["id"]: r for r in data["recettes"]}
    only = set(sys.argv[1:])
    for r in data["recettes"]:
        if not r.get("export", True) or (only and r["id"] not in only):
            continue
        folder = r.get("dossier", data["dossier"])
        for name, overrides in zip(take_names(r), r.get("variantes", [{}])):
            take = dict(r, **overrides, id=name)
            sound = normalize(render(take, recipes), take.get("gain", 0.8))
            check(sound, take)
            rate = output_rate(take)
            write_wav(ROOT / folder / (name + ".wav"), sound, rate)
            print("%-22s %.2f s" % (name, len(sound) / rate))
        write_cue(ROOT / data["fiches"] / (r["id"] + ".tres"), folder, r)
    return 0


if __name__ == "__main__":
    sys.exit(main())
