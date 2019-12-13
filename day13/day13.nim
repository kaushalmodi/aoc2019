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
    score: int
    ballPos: Position
    paddlePos: Position

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

proc draw(stateIn: var ProcessOut; inp = jNeutral): DrawOut =
  result = DrawOut()
  let
    stateOut = stateIn.codes.process(@[inp.ord], stateIn.address, stateIn.relativeBase) # Run IntCode
  doAssert stateOut.outputs.len mod 3 == 0
  var
    xyMin: Position
    xyMax: Position
  for i in countup(0, stateOut.outputs.high-2, 3):
    let
      pos = (stateOut.outputs[i], stateOut.outputs[i+1]).Position
      outp = stateOut.outputs[i+2]
    # echo &"{pos}, {outp}"
    if pos.x == -1 and pos.y == 0: # score
      result.score = outp
    else:
      doAssert pos.x >= 0 and pos.y >= 0
      xyMin = (min(xyMin.x, pos.x), min(xyMin.y, pos.y))
      xyMax = (max(xyMax.x, pos.x), max(xyMax.y, pos.y))
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
      # result.map.render(xyMin, xyMax)
  when defined(debug2):
    echo &"xyMin = {xyMin}, xyMax = {xyMax}"
  # result.map.render(xyMin, xyMax)
  result.state = stateOut

proc play(sw: seq[int]): int =
  var
    sw = sw # Make sw mutable
    initState: ProcessOut
    ballPrevPos: Position
    s = DrawOut() # Initialize the DrawOut state variable

  sw[0] = 2 # 2 quarters
  initState.codes = sw

  s = draw(initState, jLeft) # Initialize IntCode
  ballPrevPos = s.ballPos

  while true:
    var
      inp = jNeutral # Default input if none of the below if conditions match
    let
      ballPaddleXDelta = abs(s.paddlePos.x-s.ballPos.x)

    if s.ballPos.y > ballPrevPos.y: # the ball is coming down
      let
        ballFutureXTravel = s.paddlePos.y - s.ballPos.y # because the ball is always traveling at 45 degree angle
      if s.ballPos.x < ballPrevPos.x: # ball is heading down towards the left
        if s.ballPos.x < s.paddlePos.x: # ball (heading down-left) to the left of paddle
          inp = jLeft
        elif s.ballPos.x > s.paddlePos.x: # ball (heading down-left) to the right of paddle
          if ballPaddleXDelta > ballFutureXTravel:
            inp = jRight
          elif ballPaddleXDelta < ballFutureXTravel:
            inp = jLeft

      elif s.ballPos.x > ballPrevPos.x: # ball is heading down towards the right
        if s.ballPos.x < s.paddlePos.x: # ball (heading down-right) to the left of paddle
          if ballPaddleXDelta > ballFutureXTravel:
            inp = jLeft
          elif ballPaddleXDelta < ballFutureXTravel:
            inp = jRight
        elif s.ballPos.x > s.paddlePos.x: # ball (heading down-right) to the right of paddle
          inp = jRight

      else:
        doAssert false, "the ball can never remain at the same X position"

    elif s.ballPos.y < ballPrevPos.y: # the ball is now going up
      # Just try to track the ball
      if s.ballPos.x < ballPrevPos.x: # ball is heading up towards the left
        if s.ballPos.x < s.paddlePos.x: # ball (heading up-left) to the left of paddle
          inp = jLeft
        elif s.ballPos.x > s.paddlePos.x: # ball (heading up-left) to the right of paddle
          inp = jRight
        else:
          # At the moment the ball and paddle are at the same X coord,
          # but it is heading left by inertia. So move the paddle by 1
          # to the left.
          inp = jLeft

      elif s.ballPos.x > ballPrevPos.x: # ball is heading up towards the right
        if s.ballPos.x < s.paddlePos.x: # ball (heading up-right) to the left of paddle
          inp = jLeft
        elif s.ballPos.x > s.paddlePos.x: # ball (heading up-right) to the right of paddle
          inp = jRight
        else:
          # At the moment the ball and paddle are at the same X coord,
          # but it is heading right by inertia. So move the paddle by 1
          # to the right.
          inp = jRight

      else:
        doAssert false, "the ball can never remain at the same X position"

    when defined(debug2):
      echo &"ball {ballPrevPos}->{s.ballPos}, paddle {s.paddlePos}, inp = {inp}"

    ballPrevPos = s.ballPos
    s = draw(s.state, inp)
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
