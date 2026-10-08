"""App Store creative assets: product page header (3840x1646) and search results asset (3840x2560)."""
import pathlib
import gen  # reuses stars(), device_html(), LOGO_URI, DEVICES (importing also regenerates the screenshot HTML)

HERE = pathlib.Path(__file__).parent
PHONE = gen.DEVICES["iphone"]


def page(W, H, body, glow=(140, 60, 200), seed=3):
    gr, gg, gb = glow
    return f'''<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Inter:wght@400;500;600&display=block" rel="stylesheet">
<style>
  html,body{{margin:0;width:{W}px;height:{H}px;overflow:hidden;background:#020617}}
  .canvas{{position:relative;width:{W}px;height:{H}px;overflow:hidden;color:#fff;font-family:Inter,system-ui,sans-serif;
    background:linear-gradient(160deg,#020617 0%,#0f172a 55%,#27272a 100%)}}
  .nebula{{position:absolute;inset:0;filter:blur(140px);
    background:
      radial-gradient(ellipse {W*0.32:.0f}px {H*0.42:.0f}px at {W*0.5:.0f}px {H*0.5:.0f}px, rgba({gr},{gg},{gb},.55), transparent 70%),
      radial-gradient(ellipse {W*0.25:.0f}px {H*0.35:.0f}px at {W*0.78:.0f}px {H*0.75:.0f}px, rgba(180,50,120,.35), transparent 70%),
      radial-gradient(ellipse {W*0.25:.0f}px {H*0.35:.0f}px at {W*0.2:.0f}px {H*0.3:.0f}px, rgba(60,80,200,.32), transparent 70%)}}
  .stars i{{position:absolute;border-radius:50%}}
  .eyebrow{{display:inline-flex;align-items:center;gap:28px;font-weight:500;letter-spacing:.22em;text-transform:uppercase;color:rgba(255,255,255,.62)}}
  h1{{font-family:'Instrument Serif',serif;font-weight:400;line-height:.98;letter-spacing:-.01em;margin:0}}
  h1 em{{font-style:italic;background:linear-gradient(90deg,#e9d5ff,#f9a8d4 55%,#c7d2fe);-webkit-background-clip:text;background-clip:text;color:transparent}}
  p.sub{{color:rgba(255,255,255,.72);margin:0;line-height:1.35}}
  .device{{position:absolute;box-sizing:border-box;background:linear-gradient(145deg,#5b5d66,#1d1e22 30%,#0c0c0e 60%,#3a3b42);
    box-shadow:0 0 0 2px rgba(255,255,255,.12) inset,0 80px 180px rgba(0,0,0,.7),0 0 220px rgba({gr},{gg},{gb},.35)}}
  .device .screen{{width:100%;height:100%;background-size:cover;background-position:center;box-shadow:0 0 0 3px #000}}
</style></head><body><div class="canvas">
  <div class="nebula"></div>
  <div class="stars">{gen.stars(W, H, seed)}</div>
  {body}
</div></body></html>'''


# Product page header: wide and atmospheric, sits at the top of the product page.
# Everything that matters stays in the middle ~55% of the width and ~60% of the height.
W, H = 3840, 1646
header = page(W, H, f'''
  <div style="position:absolute;left:0;right:0;top:0;bottom:0;display:flex;flex-direction:column;align-items:center;justify-content:center;text-align:center;gap:56px">
    <img src="{gen.LOGO_URI}" style="height:170px" alt="">
    <h1 style="font-size:215px">The web browser<br><em>for digital minimalists.</em></h1>
  </div>''', seed=11)
(gen.BUILD / "creative-header.html").write_text(header)

# Search results asset (3:2): headline left, three real screens fanned right, all inside the central safe area.
W, H = 3840, 2560
pw = 660  # phone screen width
phones = (
    gen.device_html(PHONE, "home", pw, f"left:{W*0.53:.0f}px;top:{H*0.20:.0f}px;transform:rotate(-8deg)")
    + gen.device_html(PHONE, "settings", pw, f"left:{W*0.73:.0f}px;top:{H*0.20:.0f}px;transform:rotate(8deg)")
    + gen.device_html(PHONE, "wiki2", pw, f"left:{W*0.63:.0f}px;top:{H*0.14:.0f}px;z-index:2")
)
search = page(W, H, f'''
  <div style="position:absolute;left:{W*0.09:.0f}px;width:{W*0.45:.0f}px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;gap:70px">
    <div class="eyebrow" style="font-size:64px"><img src="{gen.LOGO_URI}" style="height:76px" alt="">Miru Browser</div>
    <h1 style="font-size:190px">The web browser<br><em>for digital minimalists.</em></h1>
    <p class="sub" style="font-size:84px">Don't let a link drag you<br>into a doomscroll.</p>
  </div>
  {phones}''', seed=17)
(gen.BUILD / "creative-search.html").write_text(search)
print("ok")
