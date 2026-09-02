# Examples — Index

All examples live under `src/examples/`. Each is a self-contained project with a `main.lua`. They demonstrate different combinations of framework capabilities.

Detailed docs for each are in this directory.

| Example | One-line description | Draw mode | Input mode |
|---|---|---|---|
| [balloons](balloons.md) | Real-time typing game — pop balloons before they fill the screen | real-time `love.draw` | `user_input()` overlay |
| [clock](clock.md) | Animated digital clock with randomised color cycling | real-time `love.draw` + `love.update` | keyboard (`love.keyreleased`) |
| [guess](guess.md) | Number guessing game with per-character validation | pen-and-paper (`love.update` polling) | `validated_input()` overlay |
| [life](life.md) | Conway's Game of Life with mouse and keyboard controls | real-time `love.draw` + `love.update` | `love.keypressed`, `love.mousepressed` |
| [paint](paint.md) | Pixel paint app with palette, brush/eraser, and line weight | real-time `love.draw`, draws to own canvas | `compy.singleclick`, `love.mousemoved`, `love.keypressed` |
| [pong](pong.md) | Full Pong game with AI opponent and fixed-timestep physics | real-time `love.draw` + `love.update` | keyboard + mouse; selectable AI strategy |
| [repl](repl.md) | Minimal REPL — echoes whatever text the user types | pen-and-paper (`love.update` polling) | `input_text()` overlay |
| [sapper](sapper.md) | Minesweeper (pen-and-paper) with click-driven board | pen-and-paper | `compy.singleclick`, `compy.doubleclick`, `love.mousepressed` |
| [sine](sine.md) | One-shot sine wave plot drawn at init, no update loop | pen-and-paper (init only) | none |
| [tixy](tixy.md) | Live-coded pixel grid — edit the tixy formula in-app | real-time `love.draw` + `love.update` | `input_code()` overlay (live Lua) |
| [turtle](turtle.md) | Turtle-graphics interpreter driven by typed commands | real-time `love.draw`, draws trails | `input_text()` + `love.keypressed` |
| [valid](valid.md) | Validator showcase — collects user input with custom rules | pen-and-paper (`love.update` polling) | `validated_input()` overlay |
