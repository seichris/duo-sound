#!/usr/bin/env python3
"""Build a static support/privacy/SEO site. Default is explicitly noindex preview."""
import argparse
import html
import shutil
from urllib.parse import urljoin
import release_check as rc

parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--release',action='store_true',help='Require submission evidence and configured public URLs')
args=parser.parse_args()
if args.release:
    errors=rc.check(rc.ROOT,submission=True)
    if errors: raise SystemExit('\n'.join(errors))
owner=rc.load(rc.ROOT/'release/readiness.json')['owner']
output=rc.ROOT/'build'/('site-release' if args.release else 'site-preview')
if output.exists(): shutil.rmtree(output)
(output/'assets').mkdir(parents=True)
shutil.copyfile(rc.ROOT/'App/Assets.xcassets/AppIcon.appiconset/AppIcon.png',output/'assets/app-icon.png')
esc=html.escape
base=(owner['marketing_url'] or '').rstrip('/')+'/'
contact=(f'<p>Publisher: {esc(owner["legal_name"])}. <a href="mailto:{esc(owner["support_email"],quote=True)}">Email support</a>.</p>'
         if owner['legal_name'] and owner['support_email'] else
         '<p>Development support: <a href="https://github.com/seichris/duo-sound/issues">the Duo Sound project on GitHub</a>. Publisher/contact details must be configured before public release. Issues are public; do not share private information.</p>')
summary=(rc.ROOT/'App/PrivacySummary.txt').read_text()
privacy=''.join('<p>'+esc(p)+'</p>' for p in summary.split('\n\n')[:-1])+contact
pages={
    'index.html': ('Duo Sound — opening and closing effects for iPhone Duo',
        'Explore original fold sound effects and custom short clips. Learn about compatibility, foreground limits, and the current developer preview.',
        '''<div class="hero"><img src="assets/app-icon.png" width="144" height="144" alt="Duo Sound: an original folded-waveform icon"><div><p class="eyebrow">DUO SOUND</p><h1>A little sound.<br>Your kind of fold.</h1><p class="lead">Choose an opening effect. Give closing its own voice. Start with original sounds or import a short clip.</p></div></div>
        <section><h2>Opening and closing sounds for iPhone Duo</h2><p>The intended physical-fold experience works only while Duo Sound is visible and active on supported hardware. It is not an iOS system-sound setting or an always-on background service.</p><p>In the developer preview, Open, Close, and the hinge slider are clearly labelled simulations. Physical hinge support still needs SDK compilation and device validation.</p></section>
        <div class="grid"><section><h2>Make it yours</h2><p>Choose Chime, Paper, Arcade, Orbit, or Click independently for each direction. Import playable unprotected audio up to 5 seconds and 8 MiB.</p></section><section><h2>Keep control</h2><p>Adjust effect volume, disable either effect, or preview a selection. Playback respects Silent Mode and follows your current audio output.</p></section></div>
        <section><h2>Can it play while another app is open?</h2><p>No. This project does not provide a verified system-wide fold listener. Locking, interruption, or suspension cancels pending effects.</p><p><a href="support.html">Read the sound and compatibility guide</a> · <a href="https://github.com/seichris/duo-sound">Follow development on GitHub</a></p></section>'''),
    'support.html': ('Duo Sound support — imports, audio and compatibility',
        'Get help with sound previews, Silent Mode, audio routes, custom imports and foreground-only fold effects.',
        '''<h1>Sound help</h1><h2>No sound?</h2><p>Turn off Silent Mode, check system and effect volume, and confirm the audio route. Headphones or a Bluetooth device may be receiving the sound. Choose a preset other than Off, then tap Preview.</p><h2>How do I import a clip?</h2><p>Tap Import under the opening or closing selection and choose a file in Files. The app accepts playable unprotected clips up to 5 seconds and 8 MiB (8,388,608 bytes). Failed imports leave your previous selection unchanged. Use audio you have permission to use.</p><h2>Why does a fold not trigger?</h2><p>The standard preview uses simulated input. A physical hinge needs a validated hardware build and supported device. The app must remain visible and active; the initial sample establishes a silent baseline. Closing during a display handoff is still a hardware validation gate.</p><h2>How do I remove my data?</h2><p>Deleting the app removes active local settings and imported copies. Offloading may retain data; backups are managed separately in iOS. There is no Duo Sound account to delete.</p>'''+contact),
    'privacy.html': ('Duo Sound privacy — local audio and settings',
        'How Duo Sound handles local settings, imported audio, backups and voluntary external support contact.',
        '<h1>Privacy</h1>'+privacy)
}
if args.release:
    title, _, body = pages['index.html']
    body = body.replace('The intended physical-fold experience works', 'Physical fold effects work')
    body = body.replace('In the developer preview, Open, Close, and the hinge slider are clearly labelled simulations. Physical hinge support still needs SDK compilation and device validation.', 'Physical detection requires compatible iPhone Duo hardware and iOS. Manual previews and the hinge slider remain clearly labelled simulations; they never claim a physical fold occurred.')
    pages['index.html'] = (title, 'Choose opening and closing effects for iPhone Duo. Original sounds, short-clip imports, and clear foreground-only controls.', body)
    title, description, body = pages['support.html']
    body = body.replace('The standard preview uses simulated input. A physical hinge needs a validated hardware build and supported device.', 'Manual previews use simulated input. Physical detection requires a supported iPhone Duo and compatible iOS.')
    body = body.replace('Closing during a display handoff is still a hardware validation gate.', 'No pending effect is replayed after the app becomes inactive or changes displays.')
    pages['support.html'] = (title, description, body)

css='''*{box-sizing:border-box}body{margin:0;background:#121225;color:#f3f1ff;font:18px/1.65 system-ui,-apple-system,sans-serif}main,nav,footer{max-width:1060px;margin:auto;padding:24px}nav{display:flex;gap:24px;flex-wrap:wrap}a{color:#c5bbff}a:focus-visible{outline:3px solid #fff;outline-offset:6px}.hero{display:flex;align-items:center;gap:40px;padding:40px 0}.hero img{border-radius:30px}h1{font-size:clamp(36px,6vw,64px);line-height:1.1;letter-spacing:-.04em;margin:10px 0 24px}h2{font-size:26px;line-height:1.3}.eyebrow{letter-spacing:.15em;font-size:14px;font-weight:700;color:#b9adff}.lead{font-size:22px;max-width:650px}.notice{border-left:4px solid #bdacff;padding:16px 20px;background:#222039}.grid{display:grid;grid-template-columns:1fr 1fr;gap:24px}section{padding:12px 0}footer{border-top:1px solid #46435c;font-size:14px;color:#c3bfd5}p{max-width:76ch}@media(max-width:650px){.hero{align-items:flex-start;flex-direction:column;gap:20px}.grid{grid-template-columns:1fr}.hero img{width:96px;height:96px;border-radius:22px}}'''
(output/'assets/site.css').write_text(css)
for filename,(title,description,body) in pages.items():
    canonical=(f'<link rel="canonical" href="{esc(urljoin(base,filename),quote=True)}">' if args.release else '')
    notice=('' if args.release else '<aside class="notice"><strong>Developer preview — not an App Store release.</strong> Physical Duo hinge behavior is unverified. No download or availability claim is made.</aside>')
    text=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{esc(title)}</title><meta name="description" content="{esc(description,quote=True)}"><meta name="robots" content="{'index,follow' if args.release else 'noindex,nofollow'}">{canonical}<meta property="og:title" content="{esc(title,quote=True)}"><meta property="og:description" content="{esc(description,quote=True)}"><meta property="og:type" content="website"><link rel="icon" href="assets/app-icon.png"><link rel="stylesheet" href="assets/site.css"></head><body><nav aria-label="Main"><a href="index.html">Duo Sound</a><a href="support.html">Support</a><a href="privacy.html">Privacy</a></nav><main>{notice}{body}</main><footer>Duo Sound is an independent project, not affiliated with or endorsed by Apple. No tracking scripts, advertising tags, ratings, pricing or store badges are embedded.</footer></body></html>'''
    (output/filename).write_text(text,encoding='utf-8')
# Allow crawling so a crawler can read the noindex directive; don't block that directive in robots.txt.
(output/'robots.txt').write_text('User-agent: *\nDisallow:\n')
if args.release:
    urls=''.join('<url><loc>'+esc(urljoin(base,name))+'</loc></url>' for name in pages)
    (output/'sitemap.xml').write_text('<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'+urls+'</urlset>')
print(output)
