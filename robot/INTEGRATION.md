# Integrating the robot modules into compy-dev

The modules in `robot/` are written to drop into compy-dev
unchanged. Everything below is the compy-dev side of the work;
nothing in this repo needs to change.

## Layout

Copy the `robot/` directory into `src/`, so the modules end up at
`src/robot/`. The `require` paths inside them are already dotted
(`require("robot.transport")`) and resolve against the package
root, which for compy-dev is `src/`. That is also why the tests
in this repo live under `robot/` and are run from the repository
root: the same paths work in both places, so the files stay
identical and cannot drift apart.

Shipping files: `lineReader.lua`, `serial.lua`, `jni.lua`,
`usbAndroid.lua`, `transport.lua`, `move.lua`.

Development-only files, not needed in compy-dev: `test*.lua`,
`fakeFirmware.py`, `protocolPatch.lua`.

## Registering the built-in

In `src/controller/consoleController.lua`, inside
`ConsoleController.prepare_env`, alongside the other `prepared.*`
entries:

```lua
  require("robot.move")

  prepared.robot_move       = robot_move
  prepared.robot_connect    = robot_connect
```

`robot_connect` is optional. It is useful in a lesson if the
teacher wants the connection (and its error message) to happen at
a predictable point rather than on the first movement, but
`robot_move` connects on its own when needed.

## Keeping the UI responsive

`robot_move` blocks until the wheels stop, which is what makes a
child's program read top to bottom. On Android a multi-second
block on the main loop can trip the system's "application not
responding" dialog. The reader calls `LINE_READER_IDLE` once per
quiet 0.2s slice while waiting, so pointing it at an event pump
is the mitigation:

```lua
  LINE_READER_IDLE = love.event.pump
```

Whether this is needed, and whether pumping is enough or the wait
belongs off the main loop entirely, is a question for the device
test: run a program with an endless loop first and see how the
runtime behaves today.

## What a lesson program looks like

```lua
robot_move(30, 30, 1)     -- forward for a second
robot_move(-50, 50, 0.5)  -- turn in place
robot_move(-30, -30, 1)   -- back up
```

Speeds are percentages from -100 to 100, negative runs a wheel
backwards. Time is in seconds and may be fractional.

## First device run

Plug the micro:bit (seated in the TPBot, chassis on) into the
Compy device and call `robot_move` from a program. If the Android
USB path fails, the error names the stage it failed at — for
example `stage endpoints: CDC set incomplete` — which is enough
to locate the problem without a debugger on the device.
