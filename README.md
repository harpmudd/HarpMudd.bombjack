# Bomb Jack (Tehkan, 1984) — Analogue Pocket

An Analogue Pocket port of **Bomb Jack** (Tehkan, 1984) by **HarpMudd**,
built on the openFPGA framework.

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

Built on the MiSTer **Arcade-BombJack** core:

- **MiSTer port:** Sorgelig
- **FPGA arcade hardware implementation:** d18c7db — translated from the
  original schematics (papilio project), DE1-SoC adaptation by MVV

This Analogue Pocket build adapts that RTL to the openFPGA / APF framework
at the game's native 15 kHz timing (256×224, 6 MHz pixel clock), rotated
90° for the original cabinet's portrait orientation. Many thanks to the
authors above.

## Controls

| Pocket | Action |
|---|---|
| **D-Pad** | Move (8-way) |
| **Any face button** | Jump |
| **Start** | 1P Start (2P Start on controller 2) |
| **Select** | Insert coin |

## Notes & Caveats

Dip settings are fixed at the factory-style defaults: demo sounds on,
upright cabinet, 3 lives, easy difficulty, bonus life every 30,000.

## ROMs

ROMs are **not** included. Build your own from the bundled `.mra` recipe in
`Assets/bombjack/common/` — it lists the required MAME romset files by name
and CRC32, with no copyrighted data. Run it through the `mra` tool to produce
`bombjack.rom`, then keep that `.rom` in the same folder (and on your Pocket
SD card).

## Credits

- **Original arcade game:** Tehkan (1984)
- **MiSTer port:** Sorgelig
- **FPGA arcade core:** d18c7db (papilio), DE1-SoC adaptation by MVV
- **Analogue Pocket port:** HarpMudd

## About / Support

I'm into retro games and the Analogue Pocket, always cooking up something new.
I love being part of a community built on sharing and the love of games — so if
any of my projects bring you joy, grab me a coffee; it fuels the next thing.

☕ **[buymeacoffee.com/harpmudd](https://buymeacoffee.com/harpmudd)**
