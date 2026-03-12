"""
ユーザー提供の横長アイコン画像を 1024x1024 正方形アイコンに変換
"""
from PIL import Image

BG = (10, 10, 20)  # #0A0A14 墨

src = Image.open("assets/icon/「今」の辞書アイコン.png").convert("RGBA")
w, h = src.size  # 312x233

# サブタイトル行を除外：上部 約70% だけ使う（タイトル + アクセントライン）
crop_h = int(h * 0.70)
src_cropped = src.crop((0, 0, w, crop_h))

# 1024x1024 キャンバスに貼り付け
SIZE = 1024
canvas = Image.new("RGB", (SIZE, SIZE), BG)

# パディングを設けてスケール（短辺基準、余白15%）
scale = SIZE * 0.82 / w
new_w = int(w * scale)
new_h = int(crop_h * scale)
resized = src_cropped.resize((new_w, new_h), Image.LANCZOS)

# 縦は少し上寄り（光学的中心）
x = (SIZE - new_w) // 2
y = (SIZE - new_h) // 2 - 20

canvas.paste(resized, (x, y), resized.split()[3])
canvas.save("assets/icon/icon.png", "PNG")
print(f"✅ 変換完了: assets/icon/icon.png ({SIZE}x{SIZE})")
