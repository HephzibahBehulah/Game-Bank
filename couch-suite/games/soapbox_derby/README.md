# Soapbox Derby

A gravity-powered downhill racing game with no engine boost. Choose one of eight named routes, manage the cart's line through four racing gates, avoid two route hazards, and preserve stability on uneven hills. Speed comes from the authored grade and grip; aggressive steering at high speed consumes stability. Results include elapsed time, line score, a medal rating, unlocked routes, and saved best times.

## Run
Open the Godot 4 project at `couch-suite/project.godot`. Choose Racing → Soapbox Derby from the hub, or run `games/soapbox_derby.tscn` directly.

## Controls
- A / Left Arrow: steer left.
- D / Right Arrow: steer right.
- Space / Down Arrow: brake.
- Gamepad left stick: steer; B/Circle or LT: brake; D-pad: course selection; A/Cross: confirm; Start/Options: pause and resume.
- Escape / B: return to course selection or the hub.

## Race strategy
Look at the next gate's amber marker and steer early toward that side. A clean gate awards line points. Red hazard markers identify a collision zone; steer around them. Braking reduces speed and helps recover stability. A crash ends the run. Completing a course unlocks the next stage; progress and best times are saved locally.

Fictional courses and physics are designed for gameplay and do not model an actual road or real vehicle.
