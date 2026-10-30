# Bomb Jack — Analogue Pocket

An Analogue Pocket port of **Bomb Jack** (Tehkan, 1984), built on the
openFPGA framework.

## The Game

Bomb Jack is Tehkan's caped-superhero platformer with a simple, perfect
hook: clear the screen of 24 bombs while soaring over postcard backdrops of
the Sphinx, the Acropolis, and Neuschwanstein castle. Jack's jump is the
star — a huge, floaty leap you can steer in mid-air and cut short with a
tap, turning every screen into a free-flight routing puzzle.

The depth is in the lit fuses: one bomb at a time sparks, and grabbing lit
bombs in an unbroken chain multiplies your score and feeds the bonus meter.
Robots, birds, and saucers patrol the screen and only a power-ball pickup
turns the tables. Easy to clear, brutal to clear *well* — a score-chaser's
classic.

## Hardware

Tehkan dedicated board:

| Part | Role |
|---|---|
| Zilog Z80 @ 4 MHz | Main CPU |
| Zilog Z80 + 3× AY-3-8910 | Sound |
| Display | Vertical CRT, RGB, 256×224 |

## The Port

Built on the MiSTer **Arcade-BombJack** core. d18c7db's `bombjack_top.vhd`,
translated from the original schematics, runs intact; everything around it is
the shell that adapts it to openFPGA / APF at the game's native 15 kHz timing
(256×224, 6 MHz pixel clock), rotated 90° for the cabinet's portrait screen.

## Controls

| Pocket | Action |
|---|---|
| **D-Pad** | Move (8-way) |
| **A / B / X / Y** | Jump |
| **Start** | 1P Start (2P Start on controller 2) |
| **Select** | Insert coin |

These are remappable from the Pocket's own Controls screen. One trade-off
comes with that: openFPGA won't accept named buttons and the analog-stick
mapping in the same file, so a docked controller's left stick no longer acts
as a d-pad. Its actual d-pad still works.

## Versions

Four sets run off the one core. Bomb Jack is at the top of the core's game
list; the other three are in its `_alternatives` folder:

| Menu entry | Set | |
|---|---|---|
| Bomb Jack | `bombjack` | Tehkan, 1984 |
| Bomb Jack (Earlier) | `bombjack2` | Earlier revision |
| Bomb Jack (Tecfri, Spain) | `bombjackt` | Tecfri licence |
| Bomb Jack (Bootleg) | `bombjackbl` | Bootleg, 1985 |

They differ only in the main CPU program. Graphics and sound are shared.

## ROMs

ROMs are **not** included — nothing in this repo contains copyrighted data.
Supply your own MAME romsets and build the images into
`dist/Assets/bombjack/common/` either way:

- **`.mra` recipe** — one per set in that folder. Run it through the standard
  `mra` tool, e.g. `mra bombjack2.mra`.
- **`pack_rom.py`** — drop the romset zips beside the script and run
  `python pack_rom.py bombjack2`, one set per run.

Both match files by CRC32 and produce byte-identical images.

The three clones are split sets, so keep the parent `bombjack.zip` alongside
the clone zip when building them.

Keep the `.rom` files in that folder and on your SD card — they land at
`Assets/bombjack/common/` on the card. A game only works once its `.rom` is
there; the menu lists all four either way.

## Notes

DIP settings are fixed: demo sounds on, upright cabinet, 3 lives, bird speed
easy, enemies medium. The bonus-life switch never awards a life on this game
(a quirk of the original program).

## Credits

- **Original arcade game:** Tehkan (1984)
- **FPGA arcade core:** [d18c7db](https://github.com/d18c7db) — translated
  from the schematics ([Papilio](http://papilio.cc/index.php?n=Playground.BombJack), 2012)
- **DE1-SoC adaptation:** [MVV](https://github.com/mvvproject)
- **MiSTer port:** Alexey Melnikov ([Sorgelig](https://github.com/Sorgelig))
- **Analogue Pocket port:** [HarpMudd](https://github.com/harpmudd)
- **Z80 CPU core (T80):**
  - **[Daniel Wallner](https://opencores.org/projects/t80)** — original author (2001–2002, OpenCores)
  - **Mike Johnson / [MikeJ](https://www.fpgaarcade.com)** (FPGAArcade) — DJNZ M1_n fix, clock enable, IM 2 fix
    and interrupt-ack fix (v0232–0240), the `T80sed` two-clock variant; project
    tidy-up, March 2005 (Ver 300)
  - **[Sean Riddle](http://seanriddle.com)** — parity flag for 8080 vs Z80 (Ver 301)
  - **[TobiFlex](https://github.com/TobiFlex)** — undocumented DDCB / FDCB opcodes (Ver 303, 20 April 2010)
- **YM2149 (AY-3-8910) sound core:** Mike Johnson / [MikeJ](https://www.fpgaarcade.com) (FPGAArcade), Jan 2005
- **Data loader, I2S audio, sync FIFO:** Adam Gastineau ([agg23](https://github.com/agg23))
- **openFPGA framework (APF), bridge command handler, reference `core_top`:** [Analogue](https://www.analogue.co)
- **PLL and other megafunctions:** Intel/Altera (Quartus-generated)

## About / Support

I'm into retro games and the Analogue Pocket, always cooking up something new.
I love being part of a community built on sharing and the love of games — so if
any of my projects bring you joy, chip in below; it fuels the next thing.

💛 **[Support this project via PayPal](https://www.paypal.com/donate/?hosted_button_id=S22WV924XU2ME)**
