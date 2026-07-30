# Getting the modules onto a device

The Compy side ships inside the Compy application, so testing it
means building a Compy application that contains it. How you
build Compy is your business — this describes what has to end up
in the build, how to check that it did, and what to do on the
device.

If you would rather not build anything, take a prebuilt APK from
the repository's Releases page and skip to "On the device".

## What has to be in the build

Run the installer against your compy-dev checkout:

    tools/integrate.py ~/compy-dev

It copies six modules into `src/robot/` and registers
`robot_move` and `robot_connect` in both environments Compy runs
code in. Details and the manual equivalent are in
INTEGRATION.md.

Then build Compy the way you normally do. The build packages
`src/*` into game.love, so the modules travel with it; no build
configuration changes are needed.

## Check the package, not the source tree

Two silent failure modes cost hours during bring-up: editing a
file after game.love was already zipped, and installing an APK
built before the fix — successive builds carry the same name
unless the commit changes. Both look exactly like "the fix
didn't work".

So check the artifact you are about to install:

    unzip -p <apk> assets/robot/usbAndroid.lua | grep -c acmRefused
    unzip -p <apk> assets/robot/move.lua | grep -c tonumber

Both must be non-zero. Grep for something only the new version
contains: a substring that also occurs in the old file — like
`eps.comm`, which matches the older `eps.commId` — will
cheerfully confirm the wrong thing.

## On the device

Install the APK. Seat the micro:bit in the TPBot, switch the
chassis on, and plug it into the Compy device. From the console:

    robot_connect()

Android asks for permission the first time, naming the device as
BBC micro:bit CMSIS-DAP; grant it. A cleared line with no message
means the port opened and the firmware answered `PING`. Then:

    robot_move(30, 30, 1)

The robot drives forward for a second. Run the same call from a
program as well — that exercises the other environment, which is
the one lessons use.

If something fails, the error names the stage it failed at; the
stages are listed at the end of INTEGRATION.md.
