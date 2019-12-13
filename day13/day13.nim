import std/[strformat, strutils, tables, sequtils]
import day02 # intcode

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
  DrawOut = ref object
    state: ProcessOut
    map: Table[Position, Tile]
    xyMin: Position
    xyMax: Position
    score: int
    ballPos: Position
    paddlePos: Position

when defined(render):
  proc render(s: DrawOut) =
    for y in s.xyMin.y .. s.xyMax.y:
      for x in s.xyMin.x .. s.xyMax.x:
        let
          tile = s.map.getOrDefault((x, y))
        case tile
        of tWall: stdout.write("#")
        of tBlock: stdout.write("█")
        of tPaddle: stdout.write("_")
        of tBall: stdout.write("O")
        else: stdout.write(" ")
      echo ""

proc draw(stateIn: var ProcessOut; inp = jNeutral): DrawOut =
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
        result.xyMin = (min(result.xyMin.x, pos.x), min(result.xyMin.y, pos.y))
        result.xyMax = (max(result.xyMax.x, pos.x), max(result.xyMax.y, pos.y))
      let
        tile = outp.Tile
        tileStr = $tile
      doAssert not tileStr.contains("(invalid data!)")
      case tile
      of tPaddle: result.paddlePos = pos
      of tBall: result.ballPos = pos
      else: discard
      result.map[pos] = tile
  result.state = stateOut

proc draw(codes: seq[int]; mem0 = -1): DrawOut =
  var
    codes = codes # Make codes mutable
  if mem0 != -1:
    codes[0] = mem0
  var
    state: ProcessOut
  state.codes = codes
  result = state.draw()

proc play(sw: seq[int]): int =
  var
    s = sw.draw(2) # Initialize IntCode, put in 2 quarters

  while true:
    s = draw(s.state, cmp(s.ballPos.x, s.paddlePos.x).Joystick)
    if s.state.address == -1:
      if s.score > 0:
        echo &"You won! :D  (score = {s.score})"
        result = s.score
      else:
        echo &"You lost :("
      break

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day13 part1 challenge":
    setup:
      let
        s = "input.txt".readFileToIntSeq().draw()
      when defined(render):
        s.render()

    test "check":
      check:
        toSeq(s.map.values).count(tBlock) == 412

  suite "day13 part2 challenge":
    setup:
      let
        score = "input.txt".readFileToIntSeq().play()
    test "check":
      check:
        score == 20940
