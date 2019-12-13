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
    jNone = -2 # no input to the IntCode
    jLeft = -1
    jNeutral = 0
    jRight = 1

proc render(map: Table[Position, Tile], xyMin: Position, xyMax: Position) =
  for y in xyMin.y .. xyMax.y:
    for x in xyMin.x .. xyMax.x:
      let
        tile = map.getOrDefault((x, y))
      case tile
      of tWall: stdout.write("#")
      of tBlock: stdout.write("█")
      of tPaddle: stdout.write("_")
      of tBall: stdout.write("O")
      else: stdout.write(" ")
    echo ""

proc draw(stateIn: var ProcessOut; jInp = jNone): (Table[Position, Tile], ProcessOut, int) =
  let
    inp: seq[int] = if jInp == jNone: @[]
                    else: @[jInp.int]
  echo &"input = {inp}"
  let
    stateOut = stateIn.codes.process(inp, stateIn.address, stateIn.relativeBase) # Run IntCode
  doAssert stateOut.outputs.len mod 3 == 0
  var
    xyMin: Position
    xyMax: Position
    score: int
  for i in countup(0, stateOut.outputs.high-2, 3):
    let
      pos = (stateOut.outputs[i], stateOut.outputs[i+1]).Position
      outp = stateOut.outputs[i+2]
    # echo &"{pos}, {outp}"
    if pos.x == -1 and pos.y == 0: # score
      score = outp
      echo &"score = {score}"
    else:
      doAssert pos.x >= 0 and pos.y >= 0
      xyMin = (min(xyMin.x, pos.x), min(xyMin.y, pos.y))
      xyMax = (max(xyMax.x, pos.x), max(xyMax.y, pos.y))
      let
        tile = outp.Tile
        tileStr = $tile
      doAssert not tileStr.contains("(invalid data!)")
      result[0][pos] = tile
      # result[0].render(xyMin, xyMax)
  when defined(debug):
    echo &"xyMin = {xyMin}, xyMax = {xyMax}"
  result[0].render(xyMin, xyMax)
  result[1] = stateOut
  result[2] = score

proc play(sw: seq[int]): int =
  var
    sw = sw # Make sw mutable
    initState: ProcessOut
  sw[0] = 2 # 2 quarters
  initState.address = 0
  initState.relativeBase = 0
  initState.codes = sw
  var
    (map, state, score) = draw(initState, jNeutral) # Initialize IntCode
  while state.address != -1:
    (map, state, score) = draw(state, jNeutral)

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
        arcadeOut = draw(initState)
    test "check":
      check:
        toSeq(arcadeOut[0].values).count(tBlock) == 412

  # suite "day13 part2 challenge":
  #   setup:
  #     let
  #       score = "input.txt".readFileToIntSeq().play()
  #     echo score
  #   test "check":
  #     check:
  #       true
  #       # score == 412
