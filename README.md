# Compy robot

Driving an ElecFreaks TPBot from a Compy program, so that children
can move a real robot by calling a built-in function.

Two halves talk over a plain-text serial protocol: a firmware on
the micro:bit that turns command lines into motor movement, and a
Lua transport on the Compy side that ships those lines and exposes
`robot_move` to lesson programs. The protocol is the contract
between them, and it is deliberately text-based so it can be
driven by hand from a terminal.

## Getting it running

1. Flash the micro:bit with `firmware.py` — see FLASHING.md — and
   smoke-test it from a terminal using the recipe at the end of
   PROTOCOL.md. This needs no Compy device and proves the firmware
   and the robot independently of everything else.
2. Install the Compy side into a compy-dev checkout:
   `tools/integrate.py ~/compy-dev` (see robot/INTEGRATION.md).
3. Build a Compy APK containing it and run it on a device — see
   robot/BUILDING.md. If you would rather not build, the Releases
   page carries a prebuilt APK.

## Contents

| Path | What it is |
| --- | --- |
| `PROTOCOL.md` | The wire protocol: commands, replies, framing, timeouts, hand-testing recipe |
| `firmware.py` | MicroPython firmware for the micro:bit — reads command lines, drives the TPBot over I2C |
| `test_firmware.py` | Protocol-logic tests for the firmware, with the micro:bit runtime stubbed |
| `FLASHING.md` | Flashing the firmware and running the smoke test |
| `tools/integrate.py` | Installs the modules into a compy-dev checkout and registers the built-in |
| `robot/` | Compy-side Lua modules; they live in compy-dev as `src/robot/` |
| `robot/INTEGRATION.md` | Layout, the two environments, blocking, the USB permission dialog, failure stages |
| `robot/BUILDING.md` | What has to be in the build, verifying the package, running it on a device |
| `microbit-lua/` | Protocol handler for the Lua firmware in `nagydani/microbit-lua`, as a patch to `lua-script.lua` |

## Status

Working on hardware end to end: a `robot_move` call on a Compy
device drives a real TPBot — the call goes through the Lua
built-in, LuaJIT FFI into JNI, the Android USB host API, a CDC-ACM
serial link, the firmware, and I2C to the motors. Forward, turn in
place, reverse and full speed all behave.

The I2C motor format was reconstructed from the official
ElecFreaks extension; it matches the one in `nagydani/microbit-lua`
and it drives the real chassis.

Sandbox only: the POSIX serial backend, which exists for
development and CI rather than for the classroom, is exercised
against a pseudo-terminal firmware simulator.

Not started: calibration figures for the lesson — how far the
robot travels at a given percentage, how much it drifts — which
need a tape measure and a floor.

## Running the tests

From the repository root, with `lua` 5.1 or `luajit`:

    python3 test_firmware.py
    luajit robot/testLineReader.lua
    lua microbit-lua/testProtocolPatch.lua

The suites that talk to a serial port need the simulator running
and its device path passed in:

    python3 robot/fakeFirmware.py &      # prints the pty path
    luajit robot/testSerial.lua /dev/pts/N
    luajit robot/testTransport.lua /dev/pts/N
    luajit robot/testMove.lua /dev/pts/N
