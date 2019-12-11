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
  Position = object
    coord: Coord
    dir: Direction
    xyMin: Coord
    xyMax: Coord
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
  pos.xyMin = (min(pos.xyMin.x, pos.coord.x), min(pos.xyMin.y, pos.coord.y))
  pos.xyMax = (max(pos.xyMax.x, pos.coord.x), max(pos.xyMax.y, pos.coord.y))

proc paint(sw: seq[int]; startPanelColor = cWhite): tuple[hull: Hull, pos: Position] =
  var
    currentColorCode = startPanelColor.ord
    address = 0
    state = sw.process(@[currentColorCode]) # Initialize IntCode
    i = 0

  # Starting position
  result.pos = Position(coord: (0, 0), dir: dUp)
  while true:
    # First, it will output a value indicating the color to paint the
    # panel the robot is over.
    result.hull[result.pos.coord] = state.outputs[0].Color
    stdout.write &"[{i:<3}] Painted {result.pos.coord} {result.hull[result.pos.coord]}, and "
    # Second, it will output a value indicating the direction the
    # robot should turn.
    state.outputs[1].updatePosition(result.pos)
    echo &"moved to {result.pos.coord}, now facing {result.pos.dir}"
    currentColorCode = result.hull.getOrDefault(result.pos.coord).ord

    # Continue painting ..
    state = state.codes.process(@[currentColorCode], state.address)
    # state.address = -1 # for debug
    if state.address == -1:
      break

when isMainModule:
  import std/[unittest]

  suite "day11 part1 challenge":
    test "check":
      check:
        "input.txt".readFileToIntSeq().paint(cBlack).hull.len == 2056

  # suite "day11 part2 challenge":
  #   test "check":
  #     check:
  #       true
