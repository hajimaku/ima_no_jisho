"""
アプリアイコン生成スクリプト
出力: assets/icon/icon.png (1024x1024)
デザイン: 墨背景 / 金の「今」/ 朱のアクセントライン
"""
import os
from PIL import Image, ImageDraw

SIZE = 1024

# カラーパレット
BG      = (10, 10, 20)       # #0A0A14 墨
GOLD    = (201, 168, 76)     # #C9A84C 金
VERMIL  = (232, 74, 47)      # #E84A2F 朱
WASHI   = (245, 240, 232)    # #F5F0E8 和紙

def draw_rounded_rect(draw, xy, radius, fill):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=radius, fill=fill)

def main():
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 背景（丸角）
    draw_rounded_rect(draw, [0, 0, SIZE, SIZE], radius=224, fill=BG)

    # 朱のアクセントライン（上部・細め）
    line_w = 5
    line_h = 80
    cx = SIZE // 2
    draw.rectangle([cx - line_w // 2, 140, cx + line_w // 2, 140 + line_h], fill=VERMIL)

    # 金のアクセントライン（下部・細め）
    draw.rectangle([cx - line_w // 2, SIZE - 140 - line_h, cx + line_w // 2, SIZE - 140],
                   fill=(GOLD[0], GOLD[1], GOLD[2], 80))

    # 「今」の文字をベジェ曲線で描画する代わりに、
    # フォントファイルを探して使用する
    font_path = None
    candidates = [
        "/System/Library/Fonts/ヒラギノ明朝 ProN W6.ttc",
        "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc",
        "/Library/Fonts/NotoSerifJP-Bold.otf",
        "/System/Library/Fonts/Hiragino Mincho ProN W6.otf",
    ]
    for c in candidates:
        if os.path.exists(c):
            font_path = c
            break

    if font_path:
        from PIL import ImageFont
        font_size = 480
        font = ImageFont.truetype(font_path, font_size)
        char = "今"
        # テキストサイズ取得
        bbox = draw.textbbox((0, 0), char, font=font)
        tw = bbox[2] - bbox[0]
        th = bbox[3] - bbox[1]
        tx = (SIZE - tw) // 2 - bbox[0]
        ty = (SIZE - th) // 2 - bbox[1] - 30  # 少し上寄りに調整
        # シャドウ（朱、少し透明）
        draw.text((tx + 4, ty + 4), char, font=font,
                  fill=(VERMIL[0], VERMIL[1], VERMIL[2], 60))
        # 本体（金）
        draw.text((tx, ty), char, font=font, fill=GOLD)
    else:
        # フォントが見つからない場合：金の四角プレースホルダー
        print("警告: 日本語フォントが見つかりません。プレースホルダーを使用します。")
        draw.rounded_rectangle([280, 280, 744, 744], radius=40,
                                fill=(GOLD[0], GOLD[1], GOLD[2], 200))

    # 出力
    out_dir = "assets/icon"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "icon.png")
    # RGBA → RGB（背景色を合成）
    bg_img = Image.new("RGB", (SIZE, SIZE), BG)
    bg_img.paste(img, mask=img.split()[3])
    bg_img.save(out_path, "PNG")
    print(f"✅ アイコン生成完了: {out_path} ({SIZE}x{SIZE})")

if __name__ == "__main__":
    main()
