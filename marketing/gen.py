"""Generate App Store marketing screenshots for Miru as HTML, one file per slide per device."""
import random, pathlib, base64

HERE = pathlib.Path(__file__).parent
BUILD = HERE / "build"  # generated HTML + rendered PNGs (gitignored)
LOGO = (HERE.parent / "Miru Browser/Assets.xcassets/Logo.imageset/logo.svg").read_text()
LOGO_URI = "data:image/svg+xml;base64," + base64.b64encode(LOGO.encode()).decode()

DEVICES = {
    # canvas size, screenshot size, screen corner radius (px at native), bezel
    "iphone": dict(W=1320, H=2868, sw=1320, sh=2868, radius=170, bezel=26, scale=0.74, head=150, sub=50, eyebrow=40, pad=130, top=780, tilt=-5, chipsdev=520),
    "ipad": dict(W=2064, H=2752, sw=2064, sh=2752, radius=80, bezel=30, scale=0.68, head=160, sub=52, eyebrow=42, pad=170, top=900, tilt=-3, chipsdev=330),
}

SLIDES = [
    dict(id="1-hero", shot="home", head="The web browser<br><em>for digital minimalists.</em>", headscale=0.76,
         sub="Don't let a link drag you into a doomscroll. Miru opens the page, and nothing else.", layout="straight", glow=(150, 60, 200)),
    dict(id="2-page", shot="wiki2", head="Just the page.<br><em>Nothing else.</em>",
         sub="No tabs to hoard. No address bar pulling you elsewhere.", layout="tilt", glow=(60, 90, 220)),
    dict(id="3-ads", shot="aurora", head="No ads.<br><em>No distractions.</em>",
         sub="Ad blocking is built in, so every page stays quiet.", layout="chip", glow=(190, 60, 130),
         chips=[("shield", "Ads blocked automatically")]),
    dict(id="4-bookmark", shot="settings", back="home", head="One bookmark.<br><em>On purpose.</em>",
         sub="Choose the one site worth returning to. Once it's set, it stays.", layout="pair", glow=(120, 50, 190)),
    dict(id="5-private", shot="milkyway", head="Read it.<br><em>Close it. Move on.</em>",
         sub="No accounts. No history. Nothing saved.", layout="chips", glow=(70, 70, 200),
         chips=[("link", "Opens links from any app"), ("eye", "Data not collected")]),
]

ICONS = {
    "shield": '<path d="M12 3l7 3v5c0 4.5-3 8.3-7 10-4-1.7-7-5.5-7-10V6l7-3z"/><path d="M9 12l2 2 4-4"/>',
    "link": '<path d="M10 14a5 5 0 007 0l3-3a5 5 0 00-7-7l-1 1"/><path d="M14 10a5 5 0 00-7 0l-3 3a5 5 0 007 7l1-1"/>',
    "person": '<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 4-6 8-6s8 2 8 6"/><path d="M3 3l18 18"/>',
    "clock": '<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>',
    "eye": '<path d="M2 12s4-7 10-7 10 7 10 7-4 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/><path d="M3 3l18 18"/>',
    "lock": '<rect x="5" y="11" width="14" height="10" rx="2"/><path d="M8 11V7a4 4 0 018 0v4"/>',
}


def icon(name, size):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" '
            f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">{ICONS[name]}</svg>')


def stars(W, H, seed):
    rnd = random.Random(seed)
    out = []
    for _ in range(int(W * H / 9000)):
        x, y = rnd.uniform(0, W), rnd.uniform(0, H)
        r = rnd.choice([1, 1, 1, 1.5, 1.5, 2, 2.5, 3.2])
        a = rnd.uniform(0.25, 0.95) if r > 1.5 else rnd.uniform(0.15, 0.6)
        warm = rnd.random()
        col = "255,236,214" if warm < 0.2 else ("214,226,255" if warm < 0.45 else "255,255,255")
        glow = f";box-shadow:0 0 {r*4}px rgba({col},{a*0.8})" if r >= 2.5 else ""
        out.append(f'<i style="left:{x:.0f}px;top:{y:.0f}px;width:{r}px;height:{r}px;background:rgba({col},{a:.2f}){glow}"></i>')
    return "".join(out)


def device_html(d, shot, w, extra_style="", cls="device"):
    """A phone/tablet frame around a real simulator capture, `w` px wide (screen only)."""
    h = w * d["sh"] / d["sw"]
    r = d["radius"] * w / d["sw"]
    b = d["bezel"] * w / d["sw"] * 1.6
    return f'''
    <div class="{cls}" style="width:{w + 2*b:.0f}px;height:{h + 2*b:.0f}px;border-radius:{r + b:.0f}px;padding:{b:.0f}px;{extra_style}">
      <div class="screen" style="border-radius:{r:.0f}px;background-image:url('../raw/{d["name"]}-{shot}.png')"></div>
    </div>'''


def slide_html(name, d, s, idx):
    W, H = d["W"], d["H"]
    gr, gg, gb = s["glow"]
    pad = d["pad"]
    sw = W * d["scale"]
    L = s["layout"]
    dev = ""
    chips = ""
    if L == "straight":
        dev = device_html(d, s["shot"], sw, f"left:{(W - sw)/2 - 20:.0f}px;top:{d['top']}px")
    elif L == "tilt":
        dev = device_html(d, s["shot"], sw, f"left:{(W - sw)/2 + W*0.03:.0f}px;top:{d['top'] + 40}px;transform:rotate({d['tilt']}deg)")
    elif L == "chip":
        dev = device_html(d, s["shot"], sw, f"left:{(W - sw)/2 - 20:.0f}px;top:{d['top'] + 60}px")
        ic, text = s["chips"][0]
        chips = f'<div class="chip float" style="left:{W*0.5:.0f}px;top:{d["top"] + sw*1.25:.0f}px;transform:translateX(-50%) rotate(-3deg)">{icon(ic, d["sub"]*1.1)}<span>{text}</span></div>'
    elif L == "pair":
        bw = sw * 0.86
        dev = device_html(d, s["back"], bw, f"left:{-bw*0.30:.0f}px;top:{d['top'] + 260}px;transform:rotate(-9deg)", "device back")
        dev += device_html(d, s["shot"], bw, f"left:{W - bw*0.95:.0f}px;top:{d['top'] + 60}px;transform:rotate(6deg)")
        chips = f'<div class="chip float" style="left:{W*0.5:.0f}px;top:{d["top"] + 1.15*bw:.0f}px;transform:translateX(-50%)">{icon("lock", d["sub"]*1.1)}<span>Set once. Yours for good.</span></div>'
    elif L == "chips":
        sw2 = sw * 0.92
        dev = device_html(d, s["shot"], sw2, f"left:{(W - sw2)/2:.0f}px;top:{d['top'] + d['chipsdev']}px")
        rows = "".join(f'<div class="chip">{icon(i, d["sub"]*1.1)}<span>{t}</span></div>' for i, t in s["chips"])
        chips = f'<div class="chipgrid" style="top:{d["top"] - 10}px">{rows}</div>'

    return f'''<!doctype html><html><head><meta charset="utf-8">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@400;500;600&display=block" rel="stylesheet">
<style>
  html,body{{margin:0;width:{W}px;height:{H}px;overflow:hidden;background:#020617}}
  .canvas{{position:relative;width:{W}px;height:{H}px;overflow:hidden;
    background:linear-gradient(160deg,#020617 0%,#0f172a 55%,#27272a 100%);font-family:Inter,system-ui,sans-serif;color:#fff}}
  .nebula{{position:absolute;inset:0;filter:blur(90px);
    background:
      radial-gradient(ellipse {W*0.55:.0f}px {H*0.28:.0f}px at {W*(0.75 if idx%2 else 0.25):.0f}px {H*0.55:.0f}px, rgba({gr},{gg},{gb},.55), transparent 70%),
      radial-gradient(ellipse {W*0.45:.0f}px {H*0.2:.0f}px at {W*(0.2 if idx%2 else 0.8):.0f}px {H*0.82:.0f}px, rgba(180,50,120,.35), transparent 70%),
      radial-gradient(ellipse {W*0.5:.0f}px {H*0.15:.0f}px at {W*0.5:.0f}px {H*0.08:.0f}px, rgba(60,80,200,.28), transparent 70%)}}
  .stars i{{position:absolute;border-radius:50%}}
  .text{{position:absolute;left:{pad}px;right:{pad}px;top:{pad + 20}px;text-align:center}}
  .eyebrow{{display:inline-flex;align-items:center;gap:{d['eyebrow']*0.5:.0f}px;font-size:{d['eyebrow']}px;font-weight:500;
    letter-spacing:.22em;text-transform:uppercase;color:rgba(255,255,255,.62)}}
  .eyebrow img{{height:{d['eyebrow']*1.15:.0f}px}}
  h1{{text-wrap:balance;font-family:'Instrument Serif',serif;font-weight:400;font-size:{d['head']}px;line-height:.98;letter-spacing:-.01em;margin:{d['head']*0.28:.0f}px 0 0}}
  h1 em{{font-style:italic;background:linear-gradient(90deg,#e9d5ff,#f9a8d4 55%,#c7d2fe);-webkit-background-clip:text;background-clip:text;color:transparent}}
  p.sub{{font-size:{d['sub']}px;line-height:1.35;color:rgba(255,255,255,.72);margin:{d['sub']*0.8:.0f}px auto 0;max-width:{W*0.8:.0f}px;text-wrap:balance}}
  .device{{position:absolute;box-sizing:border-box;
    background:linear-gradient(145deg,#5b5d66,#1d1e22 30%,#0c0c0e 60%,#3a3b42);
    box-shadow:0 0 0 2px rgba(255,255,255,.12) inset,0 60px 140px rgba(0,0,0,.65),0 0 160px rgba({gr},{gg},{gb},.35)}}
  .device .screen{{width:100%;height:100%;background-size:cover;background-position:center;box-shadow:0 0 0 3px #000}}
  .chip{{display:inline-flex;align-items:center;gap:{d['sub']*0.5:.0f}px;padding:{d['sub']*0.55:.0f}px {d['sub']*0.9:.0f}px;
    font-size:{d['sub']*0.92:.0f}px;font-weight:500;color:#fff;white-space:nowrap;border-radius:999px;
    background:rgba(15,23,42,.78);border:1.5px solid rgba(255,255,255,.20);backdrop-filter:blur(30px);-webkit-backdrop-filter:blur(30px);
    box-shadow:0 20px 60px rgba(0,0,0,.45)}}
  .chip svg{{color:#e9d5ff;flex:none}}
  .chip.float{{position:absolute;z-index:5}}
  .chipgrid{{position:absolute;left:{pad}px;right:{pad}px;display:flex;flex-wrap:wrap;justify-content:center;gap:{d['sub']*0.5:.0f}px}}
</style></head><body><div class="canvas">
  <div class="nebula"></div>
  <div class="stars">{stars(W, H, idx * 7 + len(name))}</div>
  <div class="text">
    <div class="eyebrow"><img src="{LOGO_URI}" alt="">Miru Browser</div>
    <h1 style="font-size:{d['head']*s.get('headscale',1) if d['name']=='iphone' else d['head']:.0f}px">{s['head']}</h1>
    <p class="sub">{s['sub']}</p>
  </div>
  {dev}
  {chips}
</div></body></html>'''


for name, d in DEVICES.items():
    d["name"] = name
    for i, s in enumerate(SLIDES):
        BUILD.mkdir(exist_ok=True)
        (BUILD / f"{name}-{s['id']}.html").write_text(slide_html(name, d, s, i))
print("ok")
