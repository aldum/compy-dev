### Sinewave

This project demonstrates the basics of drawing on the screen.  
The final result is a display of coordinate system axes and a sine wave.

#### Drawing

First, we establish the screen coordinates.  
The top-left corner is `(0, 0)`.  
The width and height of the window are retrieved with  
`love.graphics.getWidth()` and `love.graphics.getHeight()`.  
From these values we calculate the center `(cx, cy)`, which serves  
as the origin for both the axes and the sine wave.

Unlike the usual Cartesian system on paper, the y axis in LÖVE grows  
**downwards**. This means that when plotting `y = sin(x)`, the values  
must be inverted (`cy - s * amp`) so that the wave appears correctly  
above and below the center line.

The code is divided into three simple parts:

1. **Axes** – drawn with `draw_axes(cx, cy, w, h)`.  
   This shows horizontal and vertical reference lines.  
2. **Points** – created in `build_points(cx, cy, w, amp)`.  
   The function loops across the screen width, evaluates the sine,  
   and stores `(x, y)` pairs in a table.  
3. **Plot** – rendered with `draw_points(pts)`.  
   The table of points is drawn in red, forming the sine wave.

By separating the logic into small functions, the program stays clean,  
easy to read, and fully compliant with the formatting rules  
(max 64 chars/line, ≤14 lines per function, ≤4 args per function).
