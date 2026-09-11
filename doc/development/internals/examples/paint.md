# paint


<!-- authored By LLM; human-approved NOT YET -->

**Pixel paint application** with a color palette, brush/eraser tools, and line weight selector.

## Architecture

Single-file. Overrides `love.draw` and registers pointer and keyboard handlers through `compy.input.hooks`. Uses `compy.input.hooks.singleclick` and `compy.input.hooks.doubleclick` (left click = primary color, right click = background color). Real-time draw mode for the UI; drawing to the canvas is immediate (pen-and-paper within a sub-canvas).

## Canvas strategy

The paint canvas is a separate `love.Canvas` (`gfx.newCanvas(can_w, can_h)`), distinct from the framework's virtual canvas. Drawing calls use `canvas:renderTo(function() ... end)` — this is LÖVE's API for directing draw calls to a specific canvas. In `love.draw`, this canvas is drawn with `gfx.draw(canvas, box_w)` at an offset to leave room for the toolbox.

This means the paint buffer is fully owned by the example and is independent of the framework's virtual canvas compositing.

## Layout

Screen divided into: left toolbox strip (`box_w`), main canvas, bottom palette row (`pal_h`). Hit-testing via explicit range checks (`inCanvasRange`, `inPaletteRange`, `inToolRange`, `inWeightRange`). No UI library.

## Tool drawing

Brush and eraser icons are drawn with `gfx.push()`/`gfx.pop()`, `gfx.translate()`, `gfx.scale()`, `gfx.rotate()`. The brush tip uses `love.math.newBezierCurve` for a smooth flame shape — the most complex drawing code in any example.

## Points of attention

- `compy.input.hooks.singleclick` is for discrete color selection / tool selection. `compy.input.hooks.mousemoved` handles continuous paint strokes (checks `love.mouse.isDown` to require held button).
- Right-click (`btn == 2`) sets background color in the palette and paints with background color on canvas — the `compy.input.hooks.doubleclick` is mapped here rather than a true double-click.
- The `goose` color (a teal `{0.303, 0.431, 0.431}`) used for the weight selector highlight is a named constant for historical/whimsical reasons.

## Files

`src/examples/paint/main.lua`
