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

proc draw(stateIn: var ProcessOut; inp = jNeutral): (Table[Position, Tile], ProcessOut, int) =
  let
    stateOut = stateIn.codes.process(@[inp.ord], stateIn.address, stateIn.relativeBase) # Run IntCode
  doAssert stateOut.outputs.len mod 3 == 0
  var
    xyMin: Position
    xyMax: Position
    map: Table[Position, Tile]
    score: int
  for i in countup(0, stateOut.outputs.high-2, 3):
    let
      pos = (stateOut.outputs[i], stateOut.outputs[i+1]).Position
      outp = stateOut.outputs[i+2]
    # echo &"{pos}, {outp}"
    if pos.x == -1 and pos.y == 0: # score
      score = outp
    else:
      doAssert pos.x >= 0 and pos.y >= 0
      xyMin = (min(xyMin.x, pos.x), min(xyMin.y, pos.y))
      xyMax = (max(xyMax.x, pos.x), max(xyMax.y, pos.y))
      let
        tile = outp.Tile
        tileStr = $tile
      doAssert not tileStr.contains("(invalid data!)")
      when defined(debug2):
        case tile
        of tPaddle:
          echo &"  {tile} position = {pos}"
        of tBall:
          echo &"  {tile} position = {pos}"
        else:
          discard
      map[pos] = tile
      # map.render(xyMin, xyMax)
  when defined(debug2):
    echo &"xyMin = {xyMin}, xyMax = {xyMax}"
  # map.render(xyMin, xyMax)
  result = (map, stateOut, score)

proc numRemainingBlocks(map: Table[Position, Tile]): int =
  return toSeq(map.values).count(tBlock)

proc play(sw: seq[int]): int =
  var
    sw = sw # Make sw mutable
    initState: ProcessOut
    paddlePos: Position
    ballCurrPos: Position
    ballPrevPos: Position

  sw[0] = 2 # 2 quarters
  initState.address = 0
  initState.relativeBase = 0
  initState.codes = sw
  var
    (map, state, score) = draw(initState, jLeft) # Initialize IntCode
  for pos, tile in map.pairs:
    case tile
    of tBall:
      ballPrevPos = pos
    else:
      discard
  while true:
    var
      inp: Joystick
    for pos, tile in map.pairs:
      case tile
      of tPaddle:
        paddlePos = pos
      of tBall:
        ballCurrPos = pos
      else:
        discard
    let
      ballPaddleXDelta = abs(paddlePos.x-ballCurrPos.x)
    if ballCurrPos.y > ballPrevPos.y: # the ball is coming down
      let
        ballFutureXTravel = paddlePos.y - ballCurrPos.y # because the ball is always traveling at 45 degree angle
      if ballCurrPos.x < ballPrevPos.x: # ball is heading down towards the left
        if ballCurrPos.x < paddlePos.x: # ball (heading down-left) to the left of paddle
          inp = jLeft
        elif ballCurrPos.x > paddlePos.x: # ball (heading down-left) to the right of paddle
          if ballPaddleXDelta > ballFutureXTravel:
            inp = jRight
          elif ballPaddleXDelta < ballFutureXTravel:
            inp = jLeft
          else:
            inp = jNeutral

      elif ballCurrPos.x > ballPrevPos.x: # ball is heading down towards the right
        if ballCurrPos.x < paddlePos.x: # ball (heading down-right) to the left of paddle
          if ballPaddleXDelta > ballFutureXTravel:
            inp = jLeft
          elif ballPaddleXDelta < ballFutureXTravel:
            inp = jRight
          else:
            inp = jNeutral
        elif ballCurrPos.x > paddlePos.x: # ball (heading down-right) to the right of paddle
          inp = jRight

      else:
        doAssert false, "the ball can never remain at the same X position"

    elif ballCurrPos.y < ballPrevPos.y: # the ball is now going up
      # Just try to track the ball
      if ballCurrPos.x < ballPrevPos.x: # ball is heading up towards the left
        if ballCurrPos.x < paddlePos.x: # ball (heading up-left) to the left of paddle
          inp = jLeft
        elif ballCurrPos.x > paddlePos.x: # ball (heading up-left) to the right of paddle
          inp = jRight
        else:
          # At the moment the ball and paddle are at the same X coord,
          # but it is heading left by inertia. So move the paddle by 1
          # to the left.
          inp = jLeft

      elif ballCurrPos.x > ballPrevPos.x: # ball is heading up towards the right
        if ballCurrPos.x < paddlePos.x: # ball (heading up-right) to the left of paddle
          inp = jLeft
        elif ballCurrPos.x > paddlePos.x: # ball (heading up-right) to the right of paddle
          inp = jRight
        else:
          # At the moment the ball and paddle are at the same X coord,
          # but it is heading right by inertia. So move the paddle by 1
          # to the right.
          inp = jRight

      else:
        doAssert false, "the ball can never remain at the same X position"

    else:
      inp = jNeutral
    when defined(debug2):
      echo &"ball {ballPrevPos}->{ballCurrPos}, paddle {paddlePos}, inp = {inp}"

    (map, state, score) = draw(state, inp)
    if state.address == -1:
      if score > 0:
        echo &"You won! :D  (score = {score})"
        result = score
      else:
        echo &"You lost :("
      break
    ballPrevPos = ballCurrPos

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
        arcadeOut[0].numRemainingBlocks() == 412

  suite "day13 part2 challenge":
    setup:
      let
        score = "input.txt".readFileToIntSeq().play()
    test "check":
      check:
        score == 20940
