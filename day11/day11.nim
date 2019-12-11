import std/[strformat, tables]
import day02 # intcode

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
  PaintOut = tuple[hull: Hull, pos: Position]

const
  panelDefaultColor = cBlack

proc getNext[T: enum](currVal: T; incr = true): T =
  result = if incr:
             if currVal == T.high: T.low
             else: currVal.succ
           else:
             if currVal == T.low: T.high
             else: currVal.pred

proc updatePosition(moveCode: int; pos: var Position) =
  ## ``moveCode`` == 0 means it should turn left 90 degrees,
  ## and 1 means it should turn right 90 degrees.
  pos.dir = getNext(pos.dir, moveCode==1)
  # *After* the robot turns, it should always move forward exactly one
  # *panel.
  case pos.dir
  of dUp: pos.coord.y.inc
  of dRight: pos.coord.x.inc
  of dDown: pos.coord.y.dec
  of dLeft: pos.coord.x.dec
  pos.xyMin = (min(pos.xyMin.x, pos.coord.x), min(pos.xyMin.y, pos.coord.y))
  pos.xyMax = (max(pos.xyMax.x, pos.coord.x), max(pos.xyMax.y, pos.coord.y))

proc paint(sw: seq[int]; startPanelColor = cWhite): PaintOut =
  var
    currentColor = startPanelColor
    state = sw.process(@[currentColor.ord]) # Initialize IntCode
    i = 0

  # Starting position
  result.pos = Position(coord: (0, 0), dir: dUp)
  while true:
    # First, it will output a value indicating the color to paint the
    # panel the robot is over.
    result.hull[result.pos.coord] = state.outputs[0].Color
    stdout.write &"[{i:<3}] Painted {result.pos.coord} {result.hull[result.pos.coord]}, "
    # Second, it will output a value indicating the direction the
    # robot should turn.
    state.outputs[1].updatePosition(result.pos)
    echo &"turned to {result.pos.dir}, and then moved to {result.pos.coord}"
    currentColor = result.hull.getOrDefault(result.pos.coord, panelDefaultColor)

    # Continue painting ..
    state = state.codes.process(@[currentColor.ord], state.address, state.relativeBase)
    # state.address = -1 # for debug
    if state.address == -1:
      break

proc render(paintOutcome: PaintOut) =
  for y in countdown(paintOutcome.pos.xyMax.y, paintOutcome.pos.xyMin.y):
    for x in countup(paintOutcome.pos.xyMin.x, paintOutcome.pos.xyMax.x):
      if paintOutcome.hull.getOrDefault((x, y), panelDefaultColor) == cWhite: stdout.write("██")
      else: stdout.write("  ")
    echo ""

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day11 part1 challenge":
    test "check":
      check:
        "input.txt".readFileToIntSeq().paint(cBlack).hull.len == 2056

  suite "day11 part2 challenge":
    setup:
      let
        paintOutcome = "input.txt".readFileToIntSeq().paint()
      paintOutcome.render()

    test "check":
      check:
        paintOutcome.hull.len == 248
        paintOutcome.pos.xyMin == (0, -5)
        paintOutcome.pos.xyMax == (42, 0)
