# Couverture itch.io 630x500, palette « lavis de nuit » du jeu. Usage : python -I couverture.py <racine projet>
import math, random, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(sys.argv[1])
S = 3  # supersampling
W, H = 630 * S, 500 * S
NUIT, NUIT2 = (12, 20, 28), (23, 33, 44)
OR, JADE, PAPIER = (201, 166, 90), (94, 156, 138), (232, 225, 208)
ELEMENTS = [(127, 191, 122), (240, 122, 90), (217, 169, 74), (195, 203, 208), (111, 166, 224)]  # bois feu terre metal eau
rng = random.Random(5)

# Fond : dégradé vertical + taches de lavis floues.
img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
for y in range(H):
    t = y / H
    d.line([(0, y), (W, y)], fill=tuple(int(NUIT2[i] * (1 - t) + NUIT[i] * t) for i in range(3)))
lavis = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ld = ImageDraw.Draw(lavis)
for _ in range(14):
    x, y, r = rng.uniform(0, W), rng.uniform(0, H), rng.uniform(80, 260) * S
    c = rng.choice([JADE, (40, 60, 80), (60, 80, 100)])
    ld.ellipse([x - r, y - r * 0.5, x + r, y + r * 0.5], fill=c + (rng.randint(18, 40),))
img.paste(lavis.filter(ImageFilter.GaussianBlur(40 * S)), (0, 0), lavis.filter(ImageFilter.GaussianBlur(40 * S)))

# Montagnes à l'encre en bas.
mont = Image.new("RGBA", (W, H), (0, 0, 0, 0))
md = ImageDraw.Draw(mont)
for couche, (base, alpha) in enumerate([(0.62, 70), (0.72, 110)]):
    pts, x = [(0, H)], 0
    while x <= W:
        pts.append((x, H * base + math.sin(x / (90 * S) + couche * 2) * 40 * S + rng.uniform(-12, 12) * S))
        x += 20 * S
    pts.append((W, H))
    md.polygon(pts, fill=(6, 10, 14, alpha))
img.paste(mont.filter(ImageFilter.GaussianBlur(3 * S)), (0, 0), mont.filter(ImageFilter.GaussianBlur(3 * S)))

# Emblème : cercle d'or, pentagone de jade, cinq éléments (comme l'icône).
cx, cy, R = W / 2, 190 * S, 135 * S
halo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(halo).ellipse([cx - R * 1.3, cy - R * 1.3, cx + R * 1.3, cy + R * 1.3], fill=OR + (45,))
img.paste(halo.filter(ImageFilter.GaussianBlur(50 * S)), (0, 0), halo.filter(ImageFilter.GaussianBlur(50 * S)))
d = ImageDraw.Draw(img)
d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=OR, width=4 * S)
pr = R * 0.72
pts = [(cx + pr * math.sin(2 * math.pi * k / 5), cy - pr * math.cos(2 * math.pi * k / 5)) for k in range(5)]
d.line(pts + [pts[0]], fill=JADE, width=5 * S, joint="curve")
for (px, py), c in zip(pts, ELEMENTS):
    r = 19 * S
    d.ellipse([px - r, py - r, px + r, py + r], fill=c, outline=NUIT, width=4 * S)

# Titre.
sceau = ImageFont.truetype(str(ROOT / "ui/fonts/MaShanZheng-Sceaux.ttf"), 120 * S)
serif = ImageFont.truetype(str(ROOT / "ui/fonts/NotoSerif-Bold.ttf"), 46 * S)
petit = ImageFont.truetype(str(ROOT / "ui/fonts/NotoSerif-Regular.ttf"), 17 * S)
def centre(y, texte, police, couleur, ombre=True):
    if ombre:
        o = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(o).text((cx, y), texte, font=police, fill=(0, 0, 0, 200), anchor="mm")
        o = o.filter(ImageFilter.GaussianBlur(6 * S))
        img.paste(o, (0, 0), o)
    ImageDraw.Draw(img).text((cx, y), texte, font=police, fill=couleur, anchor="mm")
centre(cy + 6 * S, "五行", sceau, PAPIER)
centre(372 * S, "Wu Xing", serif, OR)
centre(410 * S, "A CULTIVATION ROGUELIKE DECKBUILDER", petit, PAPIER)

# Petites cartes des figures en éventail, de part et d'autre.
figure = ImageFont.truetype(str(ROOT / "ui/fonts/MaShanZheng-Sceaux.ttf"), 40 * S)
def carte(x, y, angle, glyphe, c):
    cw, ch = 70 * S, 100 * S
    cr = Image.new("RGBA", (cw + 20 * S, ch + 20 * S), (0, 0, 0, 0))
    cd = ImageDraw.Draw(cr)
    b = 10 * S
    cd.rounded_rectangle([b, b, b + cw, b + ch], radius=8 * S, fill=(26, 38, 50, 245), outline=OR, width=2 * S)
    cd.rounded_rectangle([b + 5 * S, b + 5 * S, b + cw - 5 * S, b + ch - 5 * S], radius=5 * S, outline=c, width=2 * S)
    cd.text((b + cw / 2, b + ch / 2), glyphe, font=figure, fill=c, anchor="mm")
    cr = cr.rotate(angle, resample=Image.BICUBIC, expand=True)
    img.paste(cr, (int(x - cr.width / 2), int(y - cr.height / 2)), cr)
carte(85 * S, 230 * S, 14, "徒", ELEMENTS[0])
carte(130 * S, 205 * S, 4, "师", ELEMENTS[1])
carte(500 * S, 205 * S, -4, "仙", ELEMENTS[4])
carte(545 * S, 230 * S, -14, "尊", ELEMENTS[2])

# Cadre d'or fin.
ImageDraw.Draw(img).rectangle([10 * S, 10 * S, W - 10 * S, H - 10 * S], outline=OR + (255,), width=2 * S)

out = ROOT / "docs/itch/couverture.png"
img.resize((630, 500), Image.LANCZOS).save(out)
print(out)
