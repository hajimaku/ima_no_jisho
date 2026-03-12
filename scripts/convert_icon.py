"""
ユーザー提供の横長アイコン画像を 1024x1024 正方形アイコンに変換
画像全体を使い、幅に合わせてスケール → 上下に背景色でパディング
"""
from PIL import Image

BG = (10, 10, 20)  # #0A0A14 墨

src = Image.open("assets/icon/「今」の辞書アイコン.png").convert("RGBA")
w, h = src.size  # 312x233

SIZE = 1024
canvas = Image.new("RGB", (SIZE, SIZE), BG)

# 画像全体を幅いっぱい（余白8%）にスケール
scale = SIZE * 0.92 / w
new_w = int(w * scale)
new_h = int(h * scale)
resized = src.resize((new_w, new_h), Image.LANCZOS)

# 水平中央・垂直中央（やや上寄り: 光学的中心）
x = (SIZE - new_w) // 2
y = (SIZE - new_h) // 2 - int(SIZE * 0.03)

canvas.paste(resized, (x, y), resized.split()[3])
canvas.save("assets/icon/icon.png", "PNG")
print(f"✅ 変換完了: assets/icon/icon.png ({SIZE}x{SIZE})")
print(f"   画像サイズ: {new_w}x{new_h}, 配置: ({x}, {y})")
