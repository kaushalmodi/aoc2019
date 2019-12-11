import std/[strformat, tables]
import days_utils, day02 # intcode

type
  Coord = tuple
    x: int
    y: int
  Direction = enum # values are in clockwise rotation order
    dUp = "up"
    dRight = "right"
    dDown = "down"
    dLeft = "left"
  Position = tuple
    coord: Coord
    dir: Direction
  Color = enum
    cBlack = (0, "black")
    cWhite = (1, "white")
  Hull = Table[Coord, Color]

proc turn(currentDir: Direction; clockwise = true): Direction =
  if clockwise:
    if currentDir == dLeft:
      return dUp
    else:
      return currentDir.succ
  else:
    if currentDir == dUp:
      return dLeft
    else:
      return currentDir.pred

proc updatePosition(moveCode: int; pos: var Position) =
  ## ``moveCode`` == 0 means it should turn left 90 degrees,
  ## and 1 means it should turn right 90 degrees.
  pos.dir = turn(pos.dir, moveCode==1)
  # *After* the robot turns, it should always move forward exactly one
  # *panel.
  case pos.dir
  of dUp: pos.coord.y.inc
  of dRight: pos.coord.x.inc
  of dDown: pos.coord.y.dec
  of dLeft: pos.coord.x.dec

proc paint(sw: seq[int]): Hull =
  var
    currentColorCode = cBlack.ord
    address = 0
    pos: Position = ((0, 0).Coord, dUp)
    state = sw.process(@[currentColorCode]) # Initialize IntCode
    i = 0

  while true:
    # First, it will output a value indicating the color to paint the
    # panel the robot is over.
    result[pos.coord] = state.outputs[0].Color
    stdout.write &"[{i:<3}] Painted {pos.coord} {result[pos.coord]}, and "
    # Second, it will output a value indicating the direction the
    # robot should turn.
    state.outputs[1].updatePosition(pos)
    echo &"moved to {pos.coord}, now facing {pos.dir}"
    currentColorCode = result.getOrDefault(pos.coord).ord

    # Continue painting ..
    state = state.codes.process(@[currentColorCode], state.address)
    # state.address = -1 # for debug
    if state.address == -1:
      break

when isMainModule:
  import std/[unittest]

  let
    paintedHull = "input.txt".readFileToIntSeq().paint()

  suite "day11 part1 challenge":
    test "check":
      check:
        paintedHull.len == 2056
