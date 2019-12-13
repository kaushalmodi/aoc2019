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
    # echo &"{pos}, {outp}"
    if pos.x == -1 and pos.y == 0: # score
      result.score = outp
    else:
      doAssert pos.x >= 0 and pos.y >= 0
      result.xyMin = (min(result.xyMin.x, pos.x), min(result.xyMin.y, pos.y))
      result.xyMax = (max(result.xyMax.x, pos.x), max(result.xyMax.y, pos.y))
      let
        tile = outp.Tile
        tileStr = $tile
      doAssert not tileStr.contains("(invalid data!)")
      case tile
      of tPaddle:
        result.paddlePos = pos
        when defined(debug2):
          echo &"  {tile} position = {pos}"
      of tBall:
        result.ballPos = pos
        when defined(debug2):
          echo &"  {tile} position = {pos}"
      else:
        discard
      result.map[pos] = tile
  when defined(debug2):
    echo &"result.xyMin = {result.xyMin}, result.xyMax = {result.xyMax}"
  result.state = stateOut

proc play(sw: seq[int]): int =
  var
    sw = sw # Make sw mutable
    initState: ProcessOut
    s = DrawOut() # Initialize the DrawOut state variable

  sw[0] = 2 # 2 quarters
  initState.codes = sw

  s = draw(initState, jLeft) # Initialize IntCode

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
        sw = "input.txt".readFileToIntSeq()
      var
        initState: ProcessOut
      initState.codes = sw
      let
        s = draw(initState)
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
