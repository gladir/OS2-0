# MKLOGO.PY - fabrique KERNEL/LOGO.INC (logo de l'ecran de demarrage).
#
#   python3 TOOLS/MKLOGO.PY IMAGE/LOGO_OS2ZERO.png KERNEL/LOGO.INC
#
# Le logo "OS/2 ZERO (CLONE)" est recadre, reduit a 128 x 172 points et
# trame (Floyd-Steinberg) dans une palette de 16 couleurs : 7 couleurs de
# l'interface (noir, bleu fonce du titre, vert des coches, gris clair,
# gris fonce, blanc, fond sombre) et 9 teintes du logo (k-moyennes sur ses
# points clairs, plus deux gris bleutes sombres). Le noyau programme cette
# palette dans le DAC du mode 640 x 480 x 16 couleurs (mode 12h).
# Necessite Pillow (PIL). Le fichier produit est versionne : la
# construction (BUILD.sh, BUILD.BAT) n'a pas besoin de Python.
import sys, random
from PIL import Image

src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert('RGB')
crop = im.crop((318, 40, 706, 560))
H = 172
W = 128
small = crop.resize((W, H), Image.LANCZOS)
px = [small.getpixel((x, y)) for y in range(H) for x in range(W)]
bright = [p for p in px if sum(p) > 200]
random.seed(1)

def kmeans(pts, k, it=25):
    c = random.sample(pts, k)
    for _ in range(it):
        g = [[] for _ in range(k)]
        for p in pts:
            j = min(range(k), key=lambda i: sum((p[t] - c[i][t]) ** 2 for t in range(3)))
            g[j].append(p)
        c = [tuple(sum(q[t] for q in gg) // len(gg) for t in range(3)) if gg else c[i] for i, gg in enumerate(g)]
    return c

lc = sorted(kmeans(bright, 7), key=sum)
pal = [(0, 0, 0), (0, 0, 128), (0, 128, 0), (192, 192, 192), (128, 128, 128), (255, 255, 255), (20, 28, 36),
       (36, 48, 60), (10, 18, 28)] + lc
pimg = Image.new('P', (1, 1))
pimg.putpalette([c for t in pal for c in t] + [0] * (768 - 48))
q = small.quantize(palette=pimg, dither=Image.FLOYDSTEINBERG)
data = []
for y in range(H):
    for x in range(0, W, 2):
        data.append((q.getpixel((x, y)) << 4) | q.getpixel((x + 1, y)))
out = []
out.append('{ LOGO.INC - logo de l\'ecran de demarrage (fabrique par TOOLS/MKLOGO.PY')
out.append('  depuis IMAGE/LOGO_OS2ZERO.png) : %d x %d points, 4 bits par point' % (W, H))
out.append('  (deux points par octet, le premier dans les bits forts), palette de')
out.append('  16 couleurs (rouge, vert, bleu sur 8 bits). }')
out.append('')
out.append('Const')
out.append('  SplLogoW = %d;' % W)
out.append('  SplLogoH = %d;' % H)
out.append('  SplPal : Array[0..47] Of Byte = (')
v = [c for t in pal for c in t]
for i in range(0, 48, 12):
    out.append('    ' + ', '.join('%d' % b for b in v[i:i + 12]) + (',' if i + 12 < 48 else ');'))
out.append('  SplLogo : Array[0..%d] Of Byte = (' % (len(data) - 1))
for i in range(0, len(data), 20):
    out.append('    ' + ','.join('$%02X' % b for b in data[i:i + 20]) + (',' if i + 20 < len(data) else ');'))
open(dst, 'w', newline='\n').write('\n'.join(out) + '\n')
print('%s : %d x %d, %d octets' % (dst, W, H, len(data)))
