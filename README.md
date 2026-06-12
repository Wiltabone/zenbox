# The Reflective Zen Box

A generative visual installation by **Wilbert Tabone & Thijs Prakken** (2026), built on top of the [`.abstraction()`](https://github.com/tmhglnd/abstraction) codebase. It runs in the browser via a local NodeJS server and is designed to be driven by a wireless hardware controller (e.g. ESP32) sending OSC messages. Runs on a RPi2+ with a small LCD screen.

## Follow my work

[wiltabone.com](https://www.wiltabone.com)

# Install

This installation runs in the browser via a localhost NodeJS server. First install node modules:

`npm install`

Then start the server:

`npm start`

Then navigate in the browser to:

`http://localhost:3000`

Send OSC messages to control the visuals to:

`port 9999`

### OSC Control Map

All continuous values (`/dial/*`, `/slider/*`) are in the range `0–4096` (ADC resolution of the ESP32) and are normalised to `0–1` internally.

| Address | Range | Function |
|---|---|---|
| `/dial/1` | 0–4096 | Primary frequency / scale |
| `/dial/2` | 0–4096 | Colour / hue dimension |
| `/dial/3` | 0–4096 | Modulation / warp amount |
| `/slider/1` | 0–4096 | Speed / scroll rate |
| `/slider/2` | 0–4096 | Geometry size / scale factor |
| `/slider/3` | 0–4096 | Feedback / blend amount |
| `/slider/4` | 0–4096 | Secondary frequency / noise density |
| `/2way/1` | 0 or 1 | Feedback layer on/off |
| `/2way/2` | 0 or 1 | Colour invert |
| `/2way/3` | 0 or 1 | Mirror / symmetry axis |
| `/3way/1` | 0, 1, or 2 | Post-processing: 0=raw, 1=pixelate, 2=posterize |
| `/3way/2` | 0, 1, or 2 | Blend mode: 0=add, 1=diff, 2=mult |
| `/button/1` | 0 or 1 | Cycle to next visual snippet (on press) |
| `/button/2` | 0 or 1 | Freeze motion (hold down) |
| `/button/3` | 0 or 1 | Randomise all continuous controls (on press) |

### Visual Snippets

The installation cycles through 10 Hydra visual snippets in order:

1. **squiggle** – gradient shape with noise modulation and feedback
2. **mosaic** – oscillator with kaleidoscope and voronoi pixel modulation
3. **smear** – self-referencing buffer smear with scrolling and colour shift
4. **glass** – oscillator with kaleid modulation and shape repetition
5. **paint** – noise-based painterly texture with feedback
6. **tunnel** – zooming concentric rings warped with voronoi
7. **ripple** – scrolling gradient distorted by noise, water-like surface
8. **fracture** – voronoi cells with colour banding and stained-glass effect
9. **lattice** – high-kaleid oscillator scrolled and multiplied against itself, crystalline moiré pattern
10. **vortex** – self-modulating kaleid vortex with time-driven rotation and cycling symmetry

# Make this into an installation running on a Raspberry Pi

It is possible to run this installation on a Raspberry Pi 4+ (3 or 2 are also possible but on a low visual resolution, like 160x90 pixels or less, this however is aesthetically quite pleasing!).


# Acknowledgements

**The Reflective Zen Box** was created by Wilbert Tabone & Thijs Prakken (2026).

It is a derivative of the `.abstraction()` installation [`.abstraction()`](https://github.com/tmhglnd/abstraction) codebase.

# License

The software in this repository is licensed under the [**GNU GPLv3** license](https://choosealicense.com/licenses/gpl-3.0/)

The creative output of this work is licensed under the [**CC BY-SA 4.0** license](https://creativecommons.org/licenses/by-sa/4.0/legalcode)

This is a [**Free Culture License**](https://creativecommons.org/share-your-work/public-domain/freeworks)!

You are free to:

- `Share` — copy and redistribute the material in any medium or format

- `Adapt` — remix, transform, and build upon the material for any purpose, even commercially.

Under the following terms:

- `Attribution` — You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.

- `ShareAlike` — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

