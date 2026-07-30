# Compy robot

Driving an ElecFreaks TPBot from a Compy program, so that children
can move a real robot by calling a built-in function.

Two halves talk over a plain-text serial protocol: a firmware on
the micro:bit that turns command lines into motor movement, and a
Lua transport on the Compy side that ships those lines and exposes
`robot_move` to lesson programs. The protocol is the contract
between them, and it is deliberately text-based so it can be
driven by hand from a terminal.

## Contents

| Path | What it is |
| --- | --- |
| `PROTOCOL.md` | The wire protocol: commands, replies, framing, timeouts, hand-testing recipe |
| `firmware.py` | MicroPython firmware for the micro:bit — reads command lines, drives the TPBot over I2C |
| `test_firmware.py` | Protocol-logic tests for the firmware, with the micro:bit runtime stubbed |
| `FLASHING.md` | Flashing the firmware and running the smoke test |
| `robot/` | Compy-side Lua modules; drops into compy-dev as `src/robot/` |
| `robot/INTEGRATION.md` | Layout, the `prepare_env` registration, and the blocking-wait question |
| `microbit-lua/` | Protocol handler for the Lua firmware in `nagydani/microbit-lua`, as a patch to `lua-script.lua` |

## Status

Verified on hardware: the firmware drives a real TPBot — forward,
turn in place, reverse, full speed — and answers `ERR i2c` when the
chassis is off, `ERR range` and `ERR parse` on bad input. The I2C
motor format was reconstructed from the official ElecFreaks
extension and matches the one in `nagydani/microbit-lua`.

Verified in a sandbox only: the Compy-side modules, against a
pseudo-terminal firmware simulator. The POSIX backend is exercised
end to end; the Android USB backend is written without a device and
reports every setup step as a staged error, so a single device run
locates a failure precisely.

Not started: calibration figures for the lesson (how far the robot
travels at a given percentage, how much it drifts), which need a
tape measure and a floor.

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
