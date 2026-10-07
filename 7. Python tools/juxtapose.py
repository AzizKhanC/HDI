"""Put each NHDR 2020 figure and map next to its reproduction from the microdata.

The published figure is cropped from the NHDR 2020 PDF (from its "FIGURE x.y"
or "MAP x.y" caption down to its "Source:" line, across the beige panel the
figure sits on) and set beside the reproduced figure.

Called by "Build outputs.py". On its own, from the package folder:
    python "7. Python tools/juxtapose.py" nhdr  <folder of NHDR-style PNGs>  <outdir>
    python "7. Python tools/juxtapose.py" stata "8. Stata runs/Run YYYYMMDD HHMMSS" <outdir>
    python "7. Python tools/juxtapose.py" published <outdir>

"nhdr" pairs each published figure with its redraw in the report's style
(figures.py), which is the like-for-like comparison. "stata"
pairs it with the chart the do file draws in Section 26. Each mode writes one
PNG per figure and a PDF of all of them. Needs PyMuPDF and Pillow.
"""
import re
import sys
from pathlib import Path

import fitz
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]


def re_stem(caption):
    """File stem for a caption: "Figure 2.18" stays "Figure 2.18"."""
    return re.sub(r"[^0-9A-Za-z. ]+", " ", caption).strip()
REPORT = ROOT / "6. Raw data" / "Documents" / "NHDR-Inequality-2020---low-res.pdf"

# (report caption(s), replication files in the run folder, note). The title
# printed on each page is the report's own, read from the PDF.
MISMATCH = ("Numbering mismatch: the do file labels this chart Figure {n}, but NHDR's Figure {n} is a "
            "different chart (left). The replication ({what}) has no published counterpart.")
STATA_FIGURES = [
    ("Figure 2.18", ["Figure 2.18 IHDI loss.png"], ""),
    ("Figure 2.19", ["Figure 2.19 IHDI components.png"], ""),
    ("Figure 2.20", ["Figure 2.20 HDI quintiles.png"], ""),
    ("Figure 3.6", ["Figure 3.6 provincial HDI.png"], ""),
    (["Figure 3.10", "Figure 3.13", "Figure 3.16", "Figure 3.19"], ["Figure 3.10 quintile HDI provinces.png"],
     "The report draws one figure per province. The replication puts the four in one panel."),
    ("Figure 3.22", ["Figure 3.22 top bottom ratio.png"], ""),
    ("Figure 3.23", ["Figure 3.23 loss provinces.png"], ""),
    ("Figure 3.28", ["Figure 3.28 rural urban HDI.png"], ""),
    ("Map 4.1", ["Map 4.1 CDI 2018-19.png"], ""),
    ("Map 4.2", ["Map 4.2 YDI 2017-18.png"], ""),
    ("Map 4.3", ["Map 4.3 LDI 2017-18.png"], ""),
    ("Map 4.4", ["Map 4.4 GII 2018-19.png"], ""),
    ("Figure 4.1", ["Figure 4.1 YDI trend.png"], ""),
    ("Figure 4.4", ["Figure 4.4 LDI trend.png"], ""),
    ("Figure 4.5", ["Figure 4.5 LDI dimension change.png"], ""),
    ("Figure 4.6", ["Figure 4.6 LDI provinces.png"], ""),
    ("Figure 4.7", ["Figure 4.7 CDI gender trend.png"], MISMATCH.format(n="4.7", what="the gender-based CDI over time")),
    ("Figure 4.8", ["Figure 4.8 YDI gender trend.png"], MISMATCH.format(n="4.8", what="the gender-based YDI over time")),
    ("Figure 4.9", ["Figure 4.9 GDI trend.png"], ""),
    ("Figure 4.10", ["Figure 4.10 earnings by sex.png"], ""),
    ("Figure 4.11", ["Figure 4.11 GII trend.png"], ""),
    ("Figure 4.12", ["Figure 4.12 CDI gender.png"], ""),
    ("Figure 4.13", ["Figure 4.13 YDI gender.png"], ""),
    ("Figure 4.15", ["Figure 4.15 LDI gender.png"], ""),
    ("Figure 5.19", ["Figure 5.19 health access wealth.png"], ""),
]

# The NHDR-style redraws: one file per published figure, named after it.
NHDR_FIGURES = [(c, [re_stem(c) + ".png"], "") for c in
                ["Figure 2.18", "Figure 2.19", "Figure 2.20", "Figure 3.6", "Figure 3.10", "Figure 3.13",
                 "Figure 3.16", "Figure 3.19", "Figure 3.22", "Figure 3.23", "Figure 3.28", "Map 4.1", "Map 4.2",
                 "Map 4.3", "Map 4.4", "Figure 4.1", "Figure 4.4", "Figure 4.5", "Figure 4.6", "Figure 4.7",
                 "Figure 4.8", "Figure 4.9", "Figure 4.10", "Figure 4.11", "Figure 4.12", "Figure 4.13",
                 "Figure 4.15", "Figure 5.19"]]

BG = (255, 255, 255)
INK = (40, 40, 40)
MUTED = (110, 110, 110)
PUB_TAG = (239, 68, 41)     # NHDR 2020 red (#EF4429)
REP_TAG = (31, 98, 136)     # NHDR 2020 navy (#1F6288)


def font(size, bold=False):
    for name in (["arialbd.ttf", "Arial Bold.ttf"] if bold else ["arial.ttf", "Arial.ttf"]):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def find_caption(doc, caption):
    """Page index and block of the uppercase caption, e.g. 'FIGURE 2.18'."""
    pat = re.compile(re.escape(caption.upper()) + r"(?!\d)")
    for i, page in enumerate(doc):
        for b in page.get_text("blocks"):
            if pat.match(b[4].strip()):
                return i, fitz.Rect(b[:4])
    raise LookupError(caption)


def crop_published(doc, caption, dpi=200):
    """Render the figure from its caption to its Source line."""
    i, cap = find_caption(doc, caption)
    page = doc[i]
    blocks = [(fitz.Rect(b[:4]), b[4].strip()) for b in page.get_text("blocks")]
    below = [r for r, t in blocks
             if r.y0 > cap.y0 and abs(r.x0 - cap.x0) < 15 and re.match(r"(Source|Note)s?\s*:", t)]
    src = max((r for r in below if r.y0 - cap.y0 < 700), key=lambda r: -r.y0, default=None)
    y1 = (src.y1 + 3) if src else min(cap.y0 + 420, page.rect.y1)
    # Width: the panel the figure sits on, or failing that the widest block in the column.
    x1 = cap.x1
    for d in page.get_drawings():
        r = d.get("rect")
        if r is None or d.get("fill") is None:
            continue
        if cap.x0 - 12 <= r.x0 <= cap.x0 + 30 and r.y0 >= cap.y0 - 5 and r.y1 <= y1 + 5 and r.width > 60:
            x1 = max(x1, r.x1)
    for r, t in blocks:
        if cap.y0 <= r.y0 <= y1 and abs(r.x0 - cap.x0) < 15:
            x1 = max(x1, r.x1)
    if src:
        x1 = max(x1, src.x1)
    clip = fitz.Rect(cap.x0 - 4, cap.y0 - 4, x1 + 4, y1)
    pix = page.get_pixmap(dpi=dpi, clip=clip)
    nxt = sorted((r for r, t in blocks if r.y0 > cap.y0 + 2 and abs(r.x0 - cap.x0) < 15), key=lambda r: r.y0)
    title = page.get_textbox(nxt[0]) if nxt else ""
    title = re.sub(r"\s+", " ", title).strip().replace("’", "'")
    return Image.frombytes("RGB", (pix.width, pix.height), pix.samples), i + 1, title


def stack_vertical(images, gap=20):
    w = max(im.width for im in images)
    h = sum(im.height for im in images) + gap * (len(images) - 1)
    out = Image.new("RGB", (w, h), BG)
    y = 0
    for im in images:
        out.paste(im, (0, y))
        y += im.height + gap
    return out


def fit_height(im, h):
    return im.resize((max(1, round(im.width * h / im.height)), h), Image.LANCZOS)


def labelled(im, tag, colour, width):
    """Scale an image to a column width and put a coloured tag above it."""
    im = im.resize((width, max(1, round(im.height * width / im.width))), Image.LANCZOS)
    bar = 56
    out = Image.new("RGB", (width, im.height + bar), BG)
    d = ImageDraw.Draw(out)
    d.rectangle([0, 0, width, 8], fill=colour)
    d.text((0, 16), tag, fill=colour, font=font(26, bold=True))
    out.paste(im, (0, bar))
    return out


def wrap(d, text, fnt, width):
    lines, line = [], ""
    for word in text.split():
        test = (line + " " + word).strip()
        if d.textlength(test, font=fnt) <= width:
            line = test
        else:
            lines.append(line)
            line = word
    return lines + ([line] if line else [])


def juxtapose(pub, rep, title, flag="", tag="Reproduced from microdata"):
    col = 1100
    left = labelled(pub, "Published, NHDR 2020", PUB_TAG, col)
    right = labelled(rep, tag, REP_TAG, col)
    body_h = max(left.height, right.height)
    pad, gutter = 40, 48
    W = pad * 2 + col * 2 + gutter
    probe = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    tl = wrap(probe, title, font(34, bold=True), W - 2 * pad)
    fl = wrap(probe, flag, font(24, bold=True), W - 2 * pad) if flag else []
    head = 26 + 44 * len(tl) + (34 * len(fl) + 10 if fl else 0) + 16
    H = head + body_h + pad
    out = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(out)
    y = 26
    for ln in tl:
        d.text((pad, y), ln, fill=INK, font=font(34, bold=True))
        y += 44
    for ln in fl:
        d.text((pad, y + 4), ln, fill=(200, 40, 40), font=font(24, bold=True))
        y += 34
    out.paste(left, (pad, head))
    out.paste(right, (pad + col + gutter, head))
    d.line([(pad + col + gutter // 2, head), (pad + col + gutter // 2, head + body_h)], fill=(220, 220, 220), width=2)
    return out


def main(mode, src, outdir):
    src = Path(src)
    if not src.is_absolute():
        src = ROOT / src
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    figures = NHDR_FIGURES if mode == "nhdr" else STATA_FIGURES
    doc = fitz.open(REPORT)
    pages, missing = [], []
    for caps, files, flag in figures:
        caps = [caps] if isinstance(caps, str) else caps
        reps = [src / f for f in files]
        if not all(p.exists() for p in reps):
            missing.append(", ".join(caps))
            continue
        crops = [crop_published(doc, c) for c in caps]
        pub = stack_vertical([c[0] for c in crops])
        rep = stack_vertical([Image.open(p).convert("RGB") for p in reps])
        title = f"{caps[0]}  {crops[0][2]}" if len(caps) == 1 else             f"{' / '.join(caps)}  HDI by quintile within each province, (2018-2019)"
        # Figure 4.8 plots a published index, so its values come from the WEF reports.
        tag = "Reproduced from the WEF reports" if caps[0] == "Figure 4.8" else "Reproduced from microdata"
        im = juxtapose(pub, rep, title, flag, tag)
        stem = re_stem(caps[0])
        im.save(outdir / f"{stem}.png", optimize=True)
        pages.append(stem)
    if pages:
        # PyMuPDF rather than Pillow's PDF writer, which needs a JPEG encoder.
        pdf = fitz.open()
        for stem in pages:
            png = outdir / f"{stem}.png"
            w, h = Image.open(png).size
            page = pdf.new_page(width=w * 72 / 150, height=h * 72 / 150)
            page.insert_image(page.rect, filename=str(png))
        name = "NHDR2020 figures published vs reproduced" + ("" if mode == "nhdr" else " Stata charts") + ".pdf"
        pdf.save(outdir / name, deflate=True)
    print(f"{len(pages)} side-by-side figures written to {outdir}")
    if missing:
        print("No reproduced file for:", "; ".join(missing))


def export_published(outdir, dpi=200):
    """Save each published figure crop on its own."""
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)
    doc = fitz.open(REPORT)
    for caps, _, _ in NHDR_FIGURES:
        im, page, _ = crop_published(doc, caps, dpi=dpi)
        im.save(outdir / f"{re_stem(caps)} p{page}.png", optimize=True)


if __name__ == "__main__":
    if sys.argv[1] == "published":
        export_published(sys.argv[2])
    else:
        main(sys.argv[1], sys.argv[2], sys.argv[3])
