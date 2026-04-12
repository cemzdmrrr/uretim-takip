import re

filepath = r"c:\uretim_takip\lib\pages\stok\urun_depo_yonetimi_dialog.dart"

with open(filepath, 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Double-encoded UTF-8 character mapping
# Original Turkish char -> UTF-8 bytes -> misread as Windows-1252 -> double-encoded chars
replacements = {
    '\u00c3\u009c': '\u00dc',  # Ü
    '\u00c3\u00bc': '\u00fc',  # ü
    '\u00c3\u2021': '\u00c7',  # Ç  (0x87 in Win-1252 = ‡ = U+2021)
    '\u00c3\u00a7': '\u00e7',  # ç
    '\u00c3\u2013': '\u00d6',  # Ö  (0x96 in Win-1252 = – = U+2013)
    '\u00c3\u00b6': '\u00f6',  # ö
    '\u00c4\u00b0': '\u0130',  # İ
    '\u00c4\u00b1': '\u0131',  # ı
    '\u00c5\u0178': '\u015e',  # Ş  (0x9F in Win-1252 = Ÿ = U+0178)
    '\u00c5\u0159': '\u015f',  # ş  -- wait, 0x9F? Let me recalculate
}

# Actually, let me do this more carefully.
# ş = U+015F, UTF-8 = C5 9F. Win-1252: C5 = Å (U+00C5), 9F = Ÿ (U+0178)? No, 9F in Win-1252 = Ÿ (U+0178)
# Wait, the output showed ÅŸ for ş. Å = U+00C5, Ÿ = U+0178. So ş double-encoded = Å + Ÿ? 
# Nope. Let me recalculate.
# ş = U+015F, UTF-8 bytes: C5 9F
# C5 in Win-1252 = Å (U+00C5)
# 9F in Win-1252 = Ÿ (U+0178)
# But output shows ÅŸ which is Å (U+00C5) + Ÿ... Hmm actually Ÿ=U+0178 but ŸÅŸ...
# Actually the output literally shows: baÅŸarÄ±yla -> başarıyla
# So ÅŸ → ş. Å = \u00C5, Ÿ  = \u0178? No wait, the shell might display it differently.
# Let me just find the ACTUAL codepoints in the file.

# Better approach: find sequences that look like double-encoded UTF-8 and fix them
# Pattern: bytes C0-DF followed by 80-BF when misread through Win-1252
# Win-1252 has gaps at 80-9F that map to special chars

# Let me use a direct approach: find all non-ASCII content and try to fix double-encoding

def fix_double_encoding(text):
    """Fix text that was double-encoded: UTF-8 -> Latin1/Win1252 -> UTF-8"""
    # Win-1252 to bytes mapping for the problematic range 0x80-0x9F
    win1252_map = {
        0x0152: 0x8C, 0x0153: 0x9C,
        0x0160: 0x8A, 0x0161: 0x9A,
        0x0178: 0x9F, 0x017D: 0x8E, 0x017E: 0x9E,
        0x0192: 0x83,
        0x02C6: 0x88, 0x02DC: 0x98,
        0x2013: 0x96, 0x2014: 0x97,
        0x2018: 0x91, 0x2019: 0x92,
        0x201A: 0x82, 0x201C: 0x93, 0x201D: 0x94,
        0x201E: 0x84, 0x2020: 0x86, 0x2021: 0x87,
        0x2022: 0x95, 0x2026: 0x85,
        0x2030: 0x89, 0x2039: 0x8B, 0x203A: 0x9B,
        0x20AC: 0x80, 0x2122: 0x99,
    }
    
    result = []
    i = 0
    while i < len(text):
        ch = text[i]
        cp = ord(ch)
        
        # Check if this could be the start of a double-encoded sequence
        # In double-encoded text: the first char would be in range U+00C0-U+00DF (for 2-byte UTF-8)
        # and the next char would map to a byte in 0x80-0xBF range
        if 0x00C0 <= cp <= 0x00DF and i + 1 < len(text):
            next_ch = text[i + 1]
            next_cp = ord(next_ch)
            
            # Get the original byte for the first char (it IS the byte value for Latin-1 range)
            byte1 = cp  # For U+00C0-U+00DF, the byte value equals the codepoint
            
            # Get the original byte for the second char
            byte2 = None
            if 0x80 <= next_cp <= 0xBF:
                byte2 = next_cp
            elif next_cp in win1252_map:
                byte2 = win1252_map[next_cp]
            
            if byte2 is not None and 0x80 <= byte2 <= 0xBF:
                # This looks like a double-encoded 2-byte UTF-8 sequence
                try:
                    decoded = bytes([byte1, byte2]).decode('utf-8')
                    result.append(decoded)
                    i += 2
                    continue
                except UnicodeDecodeError:
                    pass
        
        # Check for 3-byte double-encoded sequences (less common but possible)
        # E.g. İ = U+0130, UTF-8 = C4 B0. Win-1252: C4=Ä(U+00C4), B0=°(U+00B0)
        # But we might also have: C4 followed by something in 0x80-0x9F range
        
        result.append(ch)
        i += 1
    
    return ''.join(result)

fixed = fix_double_encoding(content)

# Count changes
diff_count = sum(1 for a, b in zip(content, fixed) if a != b) + abs(len(content) - len(fixed))
print(f"Characters changed: {diff_count}")
print(f"Original length: {len(content)}, Fixed length: {len(fixed)}")

# Verify Turkish characters are present
turkish_chars = set('üöşçığÜÖŞÇİĞ')
found = set(c for c in fixed if c in turkish_chars)
print(f"Turkish chars found: {found}")

# Show some context around Turkish chars
for line_no, line in enumerate(fixed.split('\n'), 1):
    if any(c in line for c in turkish_chars):
        if line_no <= 30 or 'debugPrint' in line or 'Sat' in line:
            print(f"L{line_no}: {line.strip()[:80]}")

# Write the fixed file
with open(filepath, 'w', encoding='utf-8-sig') as f:
    f.write(fixed)

print("\nFile written successfully!")
