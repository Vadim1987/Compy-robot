# Integrating the robot modules into compy-dev

## The short way

From the root of this repository:

    tools/integrate.py ~/compy-dev

That copies the shipping modules into `src/robot/`, registers the
built-in in both environments, and verifies the result. It is
safe to re-run; anything already in place is left alone.

Then build an APK — see BUILDING.md.

## What it does, and why

### Layout

The modules go to `src/robot/`. Their `require` paths are dotted
(`require("robot.transport")`) and resolve against the package
root, which for compy-dev is `src/` — the build zips `src/*` into
game.love. The tests in this repository live under `robot/` and
run from the repository root for the same reason: identical paths
in both places, so the files never drift apart.

Shipping: `lineReader.lua`, `serial.lua`, `jni.lua`,
`usbAndroid.lua`, `transport.lua`, `move.lua`.

Development only, not copied: `test*.lua`, `fakeFirmware.py`.

### Two environments

Compy runs code in two separate environments, and a built-in
registered in one is invisible in the other:

- `ConsoleController.prepare_env` fills `cc.main_env` — the
  console.
- `ConsoleController.prepare_project_env` fills `project_env` —
  user programs.

Lessons need the second one; the first is what makes manual
testing from the console possible. So both get the built-in:

```lua
  require("robot.move")

  prepared.robot_move       = robot_move
  prepared.robot_connect    = robot_connect
```

```lua
  project_env.robot_move      = robot_move
  project_env.robot_connect   = robot_connect
```

`require` happens in `prepare_env`, which runs first, so the
globals exist by the time the project environment is built.

`robot_connect` is optional but useful in a lesson: it makes the
connection, and any error about it, happen at a predictable point
instead of on the first movement.

## Blocking and the UI

`robot_move` blocks until the wheels stop, which is what makes a
child's program read top to bottom.

Measured on a Compy device: a program with an endless loop
freezes the screen but never raises Android's "not responding"
dialog — SDL runs the game loop off the Android UI thread. A
movement of a few seconds is therefore fine, and the screen
simply stops redrawing while the robot drives.

So the hook below stays off. The reader calls `LINE_READER_IDLE`
once per quiet 0.2s slice while waiting, should it ever be
needed:

```lua
  LINE_READER_IDLE = love.event.pump
```

Think twice before switching it on: pumping events inside a
child's program means input, or a quit, can arrive in the middle
of a movement.

## What the first connection looks like

Android asks the user to confirm access the first time, naming
the device: *Allow Compy IDE to access BBC micro:bit CMSIS-DAP?*
While the dialog is up, `robot_connect` is polling for the
permission, and it continues once granted. The dialog has a
checkbox for making the choice permanent — worth ticking during
testing.

For a classroom this is still one dialog per child per session.
The fix is a `device_filter.xml` naming the micro:bit vendor id
(0x0D28) plus a meta-data entry alongside the
`USB_DEVICE_ATTACHED` intent-filter that the love-android fork
already declares; Android then associates the app with the device
and stops asking. That is a small change to the fork,
deliberately left until the transport itself was proven.

## What a lesson program looks like

```lua
robot_move(30, 30, 1)     -- forward for a second
robot_move(-50, 50, 0.5)  -- turn in place
robot_move(-30, -30, 1)   -- back up
```

Speeds are percentages from -100 to 100, negative runs a wheel
backwards. Time is in seconds and may be fractional.

## When something fails

Errors from the Android path name the stage they failed at, for
example `stage endpoints: CDC set incomplete`, which locates the
problem without a debugger on the device. The stages, in order:
`selfcheck`, `env`, `activity`, `manager`, `scan`, `permission`,
`open`, `endpoints`, `claim`, `acm`.

`stage scan: no micro:bit on the bus` with the cable plugged in
usually means the device is not powered from the port — check
that the Compy end really is a host port.
