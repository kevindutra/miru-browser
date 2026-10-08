"""Transparent two-phone hero image for mirubrowser.com, matching the App Store style."""
import pathlib, gen
HERE = pathlib.Path(__file__).parent
P = gen.DEVICES["iphone"]
W, H = 1240, 1520
pw = 560
phones = (
    gen.device_html(P, "wiki2", pw * 0.92, f"left:{W - pw*0.92 - 150:.0f}px;top:250px;transform:rotate(9deg)", "device back")
    + gen.device_html(P, "home", pw, "left:110px;top:120px;transform:rotate(-6deg);z-index:2")
)
html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
  html,body{{margin:0;width:{W}px;height:{H}px;overflow:hidden;background:transparent}}
  .device{{position:absolute;box-sizing:border-box;background:linear-gradient(145deg,#5b5d66,#1d1e22 30%,#0c0c0e 60%,#3a3b42);
    box-shadow:0 0 0 2px rgba(255,255,255,.14) inset,0 40px 80px rgba(0,0,0,.55)}}
  .device .screen{{width:100%;height:100%;background-size:cover;background-position:center;box-shadow:0 0 0 3px #000}}
</style></head><body>{phones}</body></html>'''
(gen.BUILD / "site-hero.html").write_text(html)
