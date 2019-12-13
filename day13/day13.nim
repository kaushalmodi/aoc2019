import std/[strformat, strutils, tables, sequtils]
when defined(render):
  import std/[os, terminal]
import day02 # intcode

when defined(render):
  const
    canvasWidth = 44
    canvasHeight = 24

type
  Position = tuple
    x: int # Looks like the position cannot be negative
    y: int
  Tile = enum
    tEmpty = "empty"
    tWall = "wall"
    tBlock = "block"
    tPaddle = "paddle"
    tBall = "ball"
  Joystick = enum
    jLeft = (-1, "left")
    jNeutral = (0, "nowhere")
    jRight = (1, "right")
  Map = ref object
    tiles: Table[Position, Tile]
    xyMin: Position
    xyMax: Position
  DrawOut = ref object
    state: ProcessOut
    score: int
    ballPos: Position
    paddlePos: Position

when defined(render):
  proc render(map: Map; s: DrawOut) =
    for y in map.xyMin.y .. map.xyMax.y:
      for x in map.xyMin.x .. map.xyMax.x:
        let
          tile = map.tiles.getOrDefault((x, y))
        case tile
        of tWall: stdout.write("█")
        of tBlock: stdout.write("░")
        of tPaddle: stdout.write("▂")
        of tBall: stdout.write("✪")
        else: stdout.write(" ")
      echo ""

    # Move cursor back to top-left of the canvas.
    stdout.cursorUp(canvasHeight)
    stdout.cursorBackward(canvasWidth)

    sleep(10)

proc draw(map: var Map; stateIn: var ProcessOut; inp = jNeutral): DrawOut =
  result = DrawOut()
  let
    stateOut = stateIn.codes.process(@[inp.ord], stateIn.address, stateIn.relativeBase) # Run IntCode
  doAssert stateOut.outputs.len mod 3 == 0
  for i in countup(0, stateOut.outputs.high-2, 3):
    let
      pos = (stateOut.outputs[i], stateOut.outputs[i+1]).Position
      outp = stateOut.outputs[i+2]
    if pos.x == -1 and pos.y == 0: # score
      result.score = outp
    else:
      doAssert pos.x >= 0 and pos.y >= 0
      when defined(render):
        map.xyMin = (min(map.xyMin.x, pos.x), min(map.xyMin.y, pos.y))
        map.xyMax = (max(map.xyMax.x, pos.x), max(map.xyMax.y, pos.y))
      let
        tile = outp.Tile
        tileStr = $tile
      doAssert not tileStr.contains("(invalid data!)")
      case tile
      of tPaddle: result.paddlePos = pos
      of tBall: result.ballPos = pos
      else: discard
      map.tiles[pos] = tile
  when defined(render):
    map.render(result)
  result.state = stateOut

proc draw(map: var Map; codes: seq[int]; mem0 = -1): DrawOut =
  var
    codes = codes # Make codes mutable
  if mem0 != -1:
    codes[0] = mem0
  var
    state: ProcessOut
  state.codes = codes
  result = map.draw(state)

proc play(sw: seq[int]): int =
  var
    map = Map()
    s = map.draw(sw, 2) # Initialize IntCode, put in 2 quarters

  when defined(render):
    stdout.hideCursor()

  while true:
    s = map.draw(s.state, cmp(s.ballPos.x, s.paddlePos.x).Joystick)
    if s.state.address == -1:
      break

  when defined(render):
    stdout.cursorDown(canvasHeight)
    stdout.showCursor()
    echo ""

  if s.score > 0:
    echo &"You won! :D  (score = {s.score})"
    result = s.score
  else:
    echo &"You lost :("

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day13 part1 challenge":
    setup:
      var
        map = Map()
      discard map.draw("input.txt".readFileToIntSeq())

    test "check":
      check:
        toSeq(map.tiles.values).count(tBlock) == 412

  suite "day13 part2 challenge":
    setup:
      let
        score = "input.txt".readFileToIntSeq().play()
    test "play":
      check:
        score == 20940
