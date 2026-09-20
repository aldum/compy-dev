# clock

<!-- authored By LLM; human-approved NOT YET -->

**Animated digital clock** with randomly picked foreground and background colors. Uses a LÖVE stencil for a decorative moving-circle mask effect.

## Architecture

Single-file. Sets `love.draw` and `love.update` for real-time rendering. The clock increments `t` in `update()` from actual wall-clock seconds, so it stays in sync with real time even if the frame rate varies. `setTime()` re-syncs `t` from `os.date()` (called at init and on `shift+r`).

## Notable patterns

- Uses `compy.fonts.sans` via `gfx.newFont(compy.fonts.sans, 172)` — demonstrates the `compy.fonts` namespace.
- Color cycling via `Color[c]` (the framework's terminal color table, 1–7 normal + 8–14 bright). `space` cycles foreground, `shift+space` cycles background.
- `pause("STOP THE CLOCKS!")` on `p` key — demonstrates the project suspend API.
- The stencil block at the top (`love.graphics.stencil(...)`) is decorative and somewhat experimental — it creates a cutout effect with a bouncing circle. The stencil is applied but the main rendering doesn't use `stenciltest`, so the visual effect is subtle.

## Files

`src/examples/clock/main.lua`
