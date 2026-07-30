--- robot_move(left, right, seconds): the built-in kids
--- call from a compy program to drive the TPBot.
---
--- Blocking by design: it returns only after the movement
--- has finished (the firmware replies OK when the wheels
--- stop), so a program reads top to bottom as a sequence
--- of actions. Negative speeds spin a wheel backwards:
--- robot_move(-50, 50, 1) turns in place.
---
--- Errors are raised with error(msg, 0): short, readable
--- messages without file positions, for children.
---
--- Integration: require this from the platform, then
--- expose robot_move (and optionally robot_connect) in the
--- user program environment
--- (ConsoleController.prepare_env).

require("robot.transport")

--- extra read time on top of the movement itself
ROBOT_EXTRA_WAIT_S = 2
ROBOT_SECONDS_MAX = 30
--- kid-readable hints for firmware error replies
ROBOT_HINTS = {
  ["ERR i2c"] = "is the robot switched on?",
}

local robot_port = nil

local function robotError(msg)
  error(msg, 0)
end

--- tonumber rather than a type check, so a value that reads
--- as a number is accepted however it arrived. Rejections
--- quote what came in: a child sees which of their arguments
--- was wrong, and during bring-up it shows what the runtime
--- actually passed.
local function checkSpeed(value, side)
  local speed = tonumber(value)
  if not speed or speed < -100 or speed > 100 then
    robotError(side .. " wheel speed must be a number from "
      .. "-100 to 100, got " .. tostring(value))
  end
  return math.floor(speed + 0.5)
end

local function checkSeconds(value)
  local seconds = tonumber(value)
  if not seconds or seconds <= 0
      or seconds > ROBOT_SECONDS_MAX then
    robotError("time must be a number of seconds up to "
      .. ROBOT_SECONDS_MAX .. ", got " .. tostring(value))
  end
  local ms = math.floor(seconds * 1000 + 0.5)
  if ms < 1 then ms = 1 end
  return ms
end

--- Raise a kid-readable error for a port that opened but does
--- not answer, naming a refused port setup when there was one
--- since that is the likely cause.
local function handshakeFailed(port)
  local why = port.acmRefused
      and (" (port setup refused: " .. port.acmRefused .. ")")
      or ""
  transportClose(port)
  robotError("the robot is not answering, "
    .. "check the cable and try again" .. why)
end

--- Open the transport and verify our firmware answers.
--- dev is optional (tests, unusual device names).
function robot_connect(dev)
  local port, err = transportOpen(dev)
  if not port then
    robotError("robot not connected (" .. err .. ")")
  end
  if transportCommand(port, "PING", 2) ~= "PONG" then
    handshakeFailed(port)
  end
  robot_port = port
end

local function dropPort()
  if robot_port then
    transportClose(robot_port)
    robot_port = nil
  end
end

local function ensureConnected()
  if not robot_port then robot_connect() end
  return robot_port
end

function robot_move(left, right, seconds)
  local l = checkSpeed(left, "left")
  local r = checkSpeed(right, "right")
  local ms = checkSeconds(seconds)
  local port = ensureConnected()
  local line = "M " .. l .. " " .. r .. " " .. ms
  local wait = ms / 1000 + ROBOT_EXTRA_WAIT_S
  local reply, err = transportCommand(port, line, wait)
  if reply == "OK" then return true end
  if reply == nil then dropPort() end
  local why = reply and (ROBOT_HINTS[reply] or reply)
      or ("connection lost: " .. tostring(err))
  robotError("robot problem: " .. why)
end
