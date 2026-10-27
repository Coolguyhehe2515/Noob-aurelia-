import os
from PIL import Image

names = ['iron_block', 'gold_block', 'diamond_block', 'emerald_block']
for n in names:
    path = 'pack/textures/blocks/' + n + '.png'
    if os.path.exists(path):
        im = Image.open(path).convert('RGBA')
        im.putalpha(240)
        im.save(path)
