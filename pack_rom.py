"""
pack_rom.py — Build a flat ROM image for the HarpMudd Bomb Jack Pocket core.

Bomb Jack (Tehkan, 1984) and its MAME clones, all on the one board, so every
set fills the same image. Dedicated entity (papilio/d18c7db core via MiSTer
Arcade-BombJack).

Usage:
  python pack_rom.py [bombjack|bombjack2|bombjackt|bombjackbl]

Clones differ from the parent only in main CPU program:
  bombjack2   13_r01b at page C
  bombjackbl  12.bin at page B, 13.bin at page C
  bombjackt   16K program ROMs (9.1j = pages 8+9, 12.1n = pages A+B), its own
              13.1r, and 8K chips for 2.5n / 3.1e / 4.1h / 5.1k. Those load
              natively into their 8K pages: the core reads only the low 4K of
              each, which is byte-identical to the parent's 4K chips.

ROM image layout (0x20000 bytes, byte offset = dn_addr in FPGA). The core
demuxes ROM writes by 8K page off dn_addr[16:13] (bombjack_top.vhd for GFX,
bombjack.vhd internals for program/audio), so each 4K ROM is loaded TWICE to
fill its 8K page — those duplicates are load-bearing, exactly as in the .mra:
  page 0  0x00000  01_h03t   8K  audio CPU program
  page 1  0x02000  02_p04t   4K x2  bg tiles (4P)
  page 2  0x04000  03_e08t   4K x2  char gen (8E)
  page 3  0x06000  04_h08t   4K x2  char gen (8H)
  page 4  0x08000  05_k08t   4K x2  char gen (8K)
  page 5  0x0A000  06_l08t   8K  bg tiles (8L)
  page 6  0x0C000  07_n08t   8K  bg tiles (8N)
  page 7  0x0E000  08_r08t   8K  bg tiles (8R)
  page 8  0x10000  09_j01b   8K  main CPU program 0x0000
  page 9  0x12000  10_l01b   8K  main CPU program 0x2000
  page A  0x14000  11_m01b   8K  main CPU program 0x4000
  page B  0x16000  12_n01b   8K  main CPU program 0x6000
  page C  0x18000  13.1r     8K  main CPU program 0xC000
  page D  0x1A000  14_j07b   8K  sprites (7J)
  page E  0x1C000  15_l07b   8K  sprites (7L)
  page F  0x1E000  16_m07b   8K  sprites (7M)
Image ends at 0x20000 exactly — no padding needed or allowed.
"""

import sys
import zipfile
import zlib
import os

HERE = os.path.dirname(os.path.abspath(__file__))
# MAME romset .zip files. No machine-specific path is committed: set the
# HARPMUDD_ROMS env var, drop the .zip files next to this script, or keep a
# "Downloaded_Artifacts" folder beside the repo (dev convention).
DEFAULT_ZIP_DIR = next(
    (d for d in (os.environ.get("HARPMUDD_ROMS"),
                 os.path.join(os.path.dirname(HERE), "Downloaded_Artifacts"))
     if d and os.path.isdir(d)),
    HERE)
ASSETS_DIR      = os.path.join(HERE, "dist", "Assets", "bombjack", "common")

ROM_IMAGE_SIZE = 0x20000

# (CRC32, expected_size, description, rom_image_offset, mirror_offset_or_None)
BOMBJACK_ROM_DEFS = [
    (0x8407917d, 0x2000, "01_h03t.bin (audio CPU prog)",   0x00000, None),
    (0x398d4a02, 0x1000, "02_p04t.bin (bg tiles 4P)",      0x02000, 0x03000),
    (0x9f0470d5, 0x1000, "03_e08t.bin (char gen 8E)",      0x04000, 0x05000),
    (0x81ec12e6, 0x1000, "04_h08t.bin (char gen 8H)",      0x06000, 0x07000),
    (0xe87ec8b1, 0x1000, "05_k08t.bin (char gen 8K)",      0x08000, 0x09000),
    (0x51eebd89, 0x2000, "06_l08t.bin (bg tiles 8L)",      0x0A000, None),
    (0x9dd98e9d, 0x2000, "07_n08t.bin (bg tiles 8N)",      0x0C000, None),
    (0x3155ee7d, 0x2000, "08_r08t.bin (bg tiles 8R)",      0x0E000, None),
    (0xc668dc30, 0x2000, "09_j01b.bin (main prog 0)",      0x10000, None),
    (0x52a1e5fb, 0x2000, "10_l01b.bin (main prog 1)",      0x12000, None),
    (0xb68a062a, 0x2000, "11_m01b.bin (main prog 2)",      0x14000, None),
    (0x1d3ecee5, 0x2000, "12_n01b.bin (main prog 3)",      0x16000, None),
    (0x70e0244d, 0x2000, "13.1r       (main prog 4)",      0x18000, None),
    (0x101c858d, 0x2000, "14_j07b.bin (sprites 7J)",       0x1A000, None),
    (0x013f58f2, 0x2000, "15_l07b.bin (sprites 7L)",       0x1C000, None),
    (0x94694097, 0x2000, "16_m07b.bin (sprites 7M)",       0x1E000, None),
]


def clone_of(parent, replace):
    """Parent defs with the entries at the given offsets swapped out."""
    return [replace.get(d[3], d) for d in parent]


BOMBJACK2_ROM_DEFS = clone_of(BOMBJACK_ROM_DEFS, {
    0x18000: (0xbcafdd29, 0x2000, "13_r01b.bin (main prog 4)",   0x18000, None),
})

BOMBJACKBL_ROM_DEFS = clone_of(BOMBJACK_ROM_DEFS, {
    0x16000: (0x0f4d0726, 0x2000, "12.bin      (main prog 3)",   0x16000, None),
    0x18000: (0x9740f99b, 0x2000, "13.bin      (main prog 4)",   0x18000, None),
})

BOMBJACKT_ROM_DEFS = [
    (0x8407917d, 0x2000, "1.6h  (audio CPU prog)",          0x00000, None),
    (0xde796158, 0x2000, "2.5n  (bg tiles 4P)",             0x02000, None),
    (0x54e1dac1, 0x2000, "3.1e  (char gen 8E)",             0x04000, None),
    (0x05e428ab, 0x2000, "4.1h  (char gen 8H)",             0x06000, None),
    (0xf282f29a, 0x2000, "5.1k  (char gen 8K)",             0x08000, None),
    (0x51eebd89, 0x2000, "6.1l  (bg tiles 8L)",             0x0A000, None),
    (0x9dd98e9d, 0x2000, "7.1n  (bg tiles 8N)",             0x0C000, None),
    (0x3155ee7d, 0x2000, "8.1r  (bg tiles 8R)",             0x0E000, None),
    (0x4b59a3bb, 0x4000, "9.1j  (main prog 0+1)",           0x10000, None),
    (0x0a32506a, 0x4000, "12.1n (main prog 2+3)",           0x14000, None),
    (0x964ac5c5, 0x2000, "13.1r (main prog 4)",             0x18000, None),
    (0x101c858d, 0x2000, "14.7j (sprites 7J)",              0x1A000, None),
    (0x013f58f2, 0x2000, "15.7k (sprites 7L)",              0x1C000, None),
    (0x94694097, 0x2000, "16.7m (sprites 7M)",              0x1E000, None),
]

#            rom_defs             out_name          description
GAMES = {
    "bombjack":   (BOMBJACK_ROM_DEFS,   "bombjack.rom",   "Bomb Jack (Tehkan, 1984)"),
    "bombjack2":  (BOMBJACK2_ROM_DEFS,  "bombjack2.rom",  "Bomb Jack (earlier) (Tehkan, 1984)"),
    "bombjackt":  (BOMBJACKT_ROM_DEFS,  "bombjackt.rom",  "Bomb Jack (Tecfri, Spain) (Tehkan, 1984)"),
    "bombjackbl": (BOMBJACKBL_ROM_DEFS, "bombjackbl.rom", "Bomb Jack (bootleg, 1985)"),
}


def crc32_of(data):
    return zlib.crc32(data) & 0xFFFFFFFF


def load_zip_by_crc(zip_path):
    """Return dict {crc32: bytes} for every file in the zip."""
    found = {}
    with zipfile.ZipFile(zip_path) as zf:
        for info in zf.infolist():
            data = zf.read(info.filename)
            found[crc32_of(data)] = data
    return found


def load_dir_by_crc(zip_dir):
    """Scan all .zip files in zip_dir and return a merged {crc32: bytes} dict."""
    found = {}
    zips = sorted(f for f in os.listdir(zip_dir) if f.lower().endswith('.zip'))
    if not zips:
        print(f"  (no zip files found in {zip_dir})")
        return found
    for zname in zips:
        print(f"  scanning {zname}")
        try:
            found.update(load_zip_by_crc(os.path.join(zip_dir, zname)))
        except Exception as e:
            print(f"  WARNING: could not read {zname}: {e}")
    return found


def main():
    game = sys.argv[1].lower() if len(sys.argv) > 1 else "bombjack"
    if game not in GAMES:
        print(f"ERROR: unknown game '{game}'. Choose: {', '.join(GAMES)}")
        sys.exit(1)

    rom_defs, out_name, desc = GAMES[game]
    out_path = os.path.join(ASSETS_DIR, out_name)

    print(f"ROM packer — {desc}")
    print(f"Output: {out_path}\n")
    print(f"Scanning all zips in: {DEFAULT_ZIP_DIR}")
    found = load_dir_by_crc(DEFAULT_ZIP_DIR)
    print()

    image = bytearray(ROM_IMAGE_SIZE)
    errors = []

    for (crc, size, d, offset, mirror) in rom_defs:
        if crc in found:
            data = found[crc]
            if len(data) != size:
                errors.append(f"  WRONG SIZE  {d}: expected {size}, got {len(data)}")
                continue
            image[offset:offset + size] = data
            if mirror is not None:
                image[mirror:mirror + size] = data
            print(f"  OK          {d}  @ 0x{offset:05X}")
        else:
            errors.append(f"  MISSING     {d}  (CRC {crc:08x})")

    print()
    if errors:
        print("MISSING OR INVALID ROMs:")
        for e in errors:
            print(e)
        sys.exit(1)

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "wb") as f:
        f.write(image)

    print(f"\nSUCCESS: wrote {len(image)} bytes -> {out_path}")


if __name__ == "__main__":
    main()
