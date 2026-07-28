# Bomb Jack (Tehkan, 1984) — Analogue Pocket

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
- **Z80 CPU core (T80):**
  - **Daniel Wallner** — original author (2001–2002, OpenCores)
  - **Mike Johnson / MikeJ** (FPGAArcade) — DJNZ M1_n fix, clock enable, IM 2 fix
    and interrupt-ack fix (v0232–0240); project tidy-up, March 2005 (Ver 300)
  - **Sean Riddle** — parity flag for 8080 vs Z80 (Ver 301)
  - **TobiFlex** — undocumented DDCB / FDCB opcodes (Ver 303, 20 April 2010)
  - **Alexey Melnikov (Sorgelig)** — timing accuracy and ZEXDOC / ZEXALL /
    Z80Full / Z80memptr verification (Ver 350, 2018), and the `T80pa`
    pseudo-asynchronous top level
- **YM2149 (AY-3-8910) sound core:** Mike Johnson / [MikeJ](https://www.fpgaarcade.com) (FPGAArcade), Jan 2005
- **SDRAM controller, data loader, I2S audio, sync FIFO:** Adam Gastineau (agg23)
- **openFPGA framework (APF), bridge command handler, reference `core_top`:** Analogue
- **PLL and other megafunctions:** Intel/Altera (Quartus-generated)

## About / Support

I'm into retro games and the Analogue Pocket, always cooking up something new.
I love being part of a community built on sharing and the love of games — so if
any of my projects bring you joy, grab me a coffee; it fuels the next thing.

☕ **[buymeacoffee.com/harpmudd](https://buymeacoffee.com/harpmudd)**
