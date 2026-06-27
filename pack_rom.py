"""
pack_rom.py — Build a flat ROM image for the HarpMudd Bomb Jack Pocket core.

Bomb Jack (Tehkan, 1984). Single game, dedicated entity (papilio/d18c7db core
via MiSTer Arcade-BombJack).

Usage:
  python pack_rom.py [bombjack]

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
ASSETS_DIR      = os.path.join(HERE, "Assets", "bombjack", "common")

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

#          rom_defs            out_name        description
GAMES = {
    "bombjack": (BOMBJACK_ROM_DEFS, "bombjack.rom", "Bomb Jack (Tehkan, 1984)"),
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
