"""Generate TexPilot branded icons for web (favicon, PWA) and app launcher."""
from PIL import Image, ImageDraw, ImageFont
import os
import math

def create_texpilot_icon(size, output_path, is_maskable=False):
    """Create a TexPilot branded icon at the given size."""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    if is_maskable:
        # Maskable icons need safe zone (inner 80%)
        # Fill entire canvas with background color
        draw.rectangle([0, 0, size, size], fill=(21, 101, 192))
        padding = int(size * 0.1)
        inner_size = size - 2 * padding
        # Draw rounded rect in the center
        r = int(inner_size * 0.15)
        x0, y0 = padding, padding
        x1, y1 = padding + inner_size, padding + inner_size
    else:
        # Regular icon with rounded corners
        r = int(size * 0.15)
        x0, y0 = 0, 0
        x1, y1 = size, size

    # Draw rounded rectangle with gradient-like effect (top lighter, bottom darker)
    # Since Pillow doesn't support gradients natively, we'll draw horizontal bands
    for y in range(y0, y1):
        # Interpolate from #1565C0 (21,101,192) to #0D47A1 (13,71,161)
        t = (y - y0) / max(1, (y1 - y0 - 1))
        cr = int(21 + (13 - 21) * t)
        cg = int(101 + (71 - 101) * t)
        cb = int(192 + (161 - 192) * t)
        draw.line([(x0, y), (x1, y)], fill=(cr, cg, cb, 255))

    # Create a mask for rounded corners (not needed for maskable)
    if not is_maskable:
        mask = Image.new('L', (size, size), 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=255)
        img.putalpha(mask)

    # Draw the "T" letter
    # Try to use a bold system font
    font_size = int((y1 - y0) * 0.65)
    font = None
    font_paths = [
        "C:/Windows/Fonts/arialbd.ttf",
        "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/calibrib.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                font = ImageFont.truetype(fp, font_size)
                break
            except:
                pass
    if font is None:
        font = ImageFont.load_default()

    # Center the "T"
    text = "T"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (x0 + x1 - tw) / 2 - bbox[0]
    ty = (y0 + y1 - th) / 2 - bbox[1] - int(size * 0.02)
    draw.text((tx, ty), text, fill=(255, 255, 255, 255), font=font)

    img.save(output_path)
    print(f"Created: {output_path} ({size}x{size})")


def main():
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # Web favicon (32x32 PNG)
    create_texpilot_icon(32, os.path.join(base_dir, "web", "favicon.png"))

    # PWA icons
    icons_dir = os.path.join(base_dir, "web", "icons")
    os.makedirs(icons_dir, exist_ok=True)
    create_texpilot_icon(192, os.path.join(icons_dir, "Icon-192.png"))
    create_texpilot_icon(512, os.path.join(icons_dir, "Icon-512.png"))
    create_texpilot_icon(192, os.path.join(icons_dir, "Icon-maskable-192.png"), is_maskable=True)
    create_texpilot_icon(512, os.path.join(icons_dir, "Icon-maskable-512.png"), is_maskable=True)

    # App launcher icon (1024x1024 for flutter_launcher_icons)
    assets_dir = os.path.join(base_dir, "assets")
    os.makedirs(assets_dir, exist_ok=True)
    create_texpilot_icon(1024, os.path.join(assets_dir, "texpilot_icon.png"))

    # Also create adaptive foreground (1024x1024 with padding)
    create_texpilot_icon(1024, os.path.join(assets_dir, "texpilot_icon_foreground.png"), is_maskable=True)

    print("\nAll icons generated successfully!")


if __name__ == "__main__":
    main()
