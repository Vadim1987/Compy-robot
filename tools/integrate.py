#!/usr/bin/env python3
"""Install the robot modules into a compy-dev checkout.

Copies the shipping modules to src/robot/ and registers the
built-in in both environments Compy runs code in: the console
(prepare_env) and user programs (prepare_project_env). Safe to
re-run: patches that are already present are left alone.

    tools/integrate.py ~/compy-dev
"""
import shutil
import sys
from pathlib import Path

MODULES = [
    "lineReader.lua", "serial.lua", "jni.lua",
    "usbAndroid.lua", "transport.lua", "move.lua",
]

CONSOLE_ANCHOR = """  prepared.quit             = function()
    love.event.quit()
  end
"""

CONSOLE_PATCH = """
  require("robot.move")

  prepared.robot_move       = robot_move
  prepared.robot_connect    = robot_connect
"""

PROJECT_ANCHOR = """  project_env.close_project   = function()
    close_project(cc)
  end
"""

PROJECT_PATCH = """
  project_env.robot_move      = robot_move
  project_env.robot_connect   = robot_connect
"""


def fail(message):
    print("error: " + message, file=sys.stderr)
    sys.exit(1)


def copy_modules(here, compy):
    target = compy / "src" / "robot"
    target.mkdir(parents=True, exist_ok=True)
    for name in MODULES:
        source = here / "robot" / name
        if not source.is_file():
            fail("missing module: %s" % source)
        shutil.copy2(source, target / name)
    print("modules -> %s" % target)


def patch(text, anchor, addition, marker, label):
    if marker in text:
        print("%s: already registered" % label)
        return text, False
    if text.count(anchor) != 1:
        fail("%s: anchor found %d times, expected 1 -- the file "
             "has moved on, patch it by hand (see "
             "robot/INTEGRATION.md)" % (label, text.count(anchor)))
    print("%s: registered" % label)
    return text.replace(anchor, anchor + addition), True


def patch_controller(compy):
    path = (compy / "src" / "controller" /
            "consoleController.lua")
    if not path.is_file():
        fail("not a compy checkout: %s missing" % path)
    text = path.read_text()
    text, a = patch(text, CONSOLE_ANCHOR, CONSOLE_PATCH,
                    "prepared.robot_move", "console")
    text, b = patch(text, PROJECT_ANCHOR, PROJECT_PATCH,
                    "project_env.robot_move", "programs")
    if a or b:
        path.write_text(text)


def verify(compy):
    checks = [
        (compy / "src/robot/usbAndroid.lua", "acmRefused"),
        (compy / "src/robot/move.lua", "tonumber"),
        (compy / "src/controller/consoleController.lua",
         "project_env.robot_move"),
    ]
    for path, needle in checks:
        if needle not in path.read_text():
            fail("verification failed: %s lacks %s"
                 % (path, needle))
    print("verified")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    compy = Path(sys.argv[1]).expanduser()
    here = Path(__file__).resolve().parent.parent
    if not compy.is_dir():
        fail("no such directory: %s" % compy)
    copy_modules(here, compy)
    patch_controller(compy)
    verify(compy)
    print("\nNext: build the APK, then verify the package "
          "actually contains it --\n"
          "  unzip -p <apk> assets/robot/usbAndroid.lua "
          "| grep -c acmRefused")


main()
