# Paint

This project demonstrates a simple **paint program** running on the Compy device.
It introduces mouse interaction, UI toolbars, color palette, brush weights, and canvas rendering.

---

## Screen layout

The screen is split into three regions:

* **Left sidebar** → tools and brush weights
* **Bottom bar** → color palette (16 colors)
* **Main area** → the canvas where you draw

Canvas is stored in an off-screen `Canvas` object (`love.graphics.newCanvas`) and rendered every frame.

---

## Tools

* **Brush (tool 1)** → draw with the selected foreground color
* **Eraser (tool 2)** → erase using the background color

Switch tools using the mouse (click in sidebar) or press `Tab`.

---

## Brush weights

In the lower half of the sidebar you see 8 slots.
Each slot corresponds to a different brush size.
Click to select the active size.
Eraser scales sizes ×1.5 automatically.

---

## Color palette

The bottom of the screen shows 16 colors (two rows of 8).

* **Left click** → set foreground (drawing color)
* **Right click / double click** → set background

Shortcut: keys `1–8` select colors; hold **Shift** to select the brighter row.

---

## Controls

* **Mouse drag (left button)** → paint with brush
* **Mouse drag (right button)** → paint with background (eraser style)
* **Mouse move** → shows a circle preview of current brush size
* **`Tab`** → cycle tools
* **`[` / `]`** → decrease / increase brush size
* **Number keys 1–8** → select colors (with Shift for bright set)

---

## Code structure

* **Hit-test helpers** → functions like `inCanvasRange`, `inPaletteRange`
* **UI rendering** → `drawToolbox`, `drawColorPalette`, `drawWeightSelector`
* **Painting ops** → `useCanvas`, `setPaintColor`, `applyPaint`
* **Input dispatchers** → `point`, `love.singleclick`, `love.doubleclick`
* **State changes** → `setColor`, `setTool`, `setLineWeight`



## Learning goals

* How to split a screen into UI regions
* How to use canvases (`love.graphics.newCanvas`) for persistent drawing
* How to handle **mouse input** (press, drag, move, click, doubleclick)
* How to design simple UI tool selectors (tools, colors, weights)

---

📌 With this example, learners can explore **drawing programs**, expand to **fill tools**, **shapes**, or even **layers** later.

