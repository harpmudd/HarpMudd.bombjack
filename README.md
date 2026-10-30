# Bomb Jack — Analogue Pocket

An Analogue Pocket port of **Bomb Jack** (Tehkan, 1984), built on the
openFPGA framework.

## The Game

Clear each screen of 24 bombs with Jack's huge, steerable jump. Grab the lit
bombs in order for big scores, and dodge the robots, birds and saucers until
a power ball lets you turn the tables.

## Hardware

| Part | Role |
|---|---|
| Zilog Z80 @ 4 MHz | Main CPU |
| Zilog Z80 + 3× AY-3-8910 | Sound |
| Display | Vertical CRT, 256×224 |

## Controls

| Pocket | Action |
|---|---|
| **D-Pad** | Move |
| **A / B / X / Y** | Jump |
| **Start** | 1P Start |
| **Select** | Insert coin |

Buttons can be remapped from the Pocket's Controls screen. A docked
controller's left stick doesn't act as a d-pad.

## Versions

Bomb Jack is at the top of the game list; the rest are in `_alternatives`.

| Menu entry | Set |
|---|---|
| Bomb Jack | `bombjack` |
| Bomb Jack (Earlier) | `bombjack2` |
| Bomb Jack (Tecfri, Spain) | `bombjackt` |
| Bomb Jack (Bootleg) | `bombjackbl` |

## ROMs

ROMs are **not** included. Build each `.rom` from your own MAME romset with
the `.mra` recipe in `dist/Assets/bombjack/common/` (e.g. `mra bombjack.mra`),
and put it in `Assets/bombjack/common/` on your SD card. The clones also need
the parent `bombjack.zip`.

## Credits

- **Original arcade game:** Tehkan (1984)
- **FPGA arcade core:** [d18c7db](https://github.com/d18c7db), DE1-SoC adaptation by [MVV](https://github.com/mvvproject)
- **MiSTer port:** [Sorgelig](https://github.com/Sorgelig)
- **Analogue Pocket port:** [HarpMudd](https://github.com/harpmudd)
- **Z80 CPU (T80):** [Daniel Wallner](https://opencores.org/projects/t80), [MikeJ](https://www.fpgaarcade.com), [Sean Riddle](http://seanriddle.com), [TobiFlex](https://github.com/TobiFlex)
- **YM2149 sound:** [MikeJ](https://www.fpgaarcade.com)
- **Data loader, I2S audio, sync FIFO:** [agg23](https://github.com/agg23)
- **openFPGA framework:** [Analogue](https://www.analogue.co)

## About / Support

I'm into retro games and the Analogue Pocket, always cooking up something new.
I love being part of a community built on sharing and the love of games — so if
any of my projects bring you joy, chip in below; it fuels the next thing.

💛 **[Support this project via PayPal](https://www.paypal.com/donate/?hosted_button_id=S22WV924XU2ME)**
