import std/[strformat, strutils, strscans, math]
import days_utils

const
  numMoons = 4

type
  Coord = object
    x: int
    y: int
    z: int
  CoordArr = array[numMoons, Coord]
  PosVel = object
    pos: Coord
    vel: Coord
  PosVelAxis = object
    pos: int
    vel: int
  PosVelArr = array[numMoons, PosVel]

const
  zeroVelocity = Coord(x: 0, y: 0, z: 0)

proc parseCoords(fileName: string): CoordArr =
  let
    moons = fileName.prjDir().readFile().strip().splitLines()
  for idx, moon in moons:
    var
      x, y, z: int
    discard scanf(moon, "<x=$i, y=$i, z=$i>", x, y, z)
    result[idx] = Coord(x: x, y: y, z: z)

proc updatePosVel(posVelsAxis: var openArray[PosVelAxis]) =
  for i in 0 .. posVelsAxis.high:
    # Update velocity.
    for j in i+1 .. posVelsAxis.high:
      if posVelsAxis[i].pos < posVelsAxis[j].pos:
        posVelsAxis[i].vel.inc
        posVelsAxis[j].vel.dec
      elif posVelsAxis[i].pos > posVelsAxis[j].pos:
        posVelsAxis[i].vel.dec
        posVelsAxis[j].vel.inc
    # Update position.
    posVelsAxis[i].pos.inc(posVelsAxis[i].vel)

proc posVelsToPosVelsAxes(posVels: var openArray[PosVel]): seq[seq[PosVelAxis]] =
  var
    posVelX: seq[PosVelAxis]
    posVelY: seq[PosVelAxis]
    posVelZ: seq[PosVelAxis]
  for i in 0 ..< numMoons:
    posVelX.add(PosVelAxis(pos: posVels[i].pos.x, vel: posVels[i].vel.x))
    posVelY.add(PosVelAxis(pos: posVels[i].pos.y, vel: posVels[i].vel.y))
    posVelZ.add(PosVelAxis(pos: posVels[i].pos.z, vel: posVels[i].vel.z))
  return @[posVelX, posVelY, posVelZ]

proc updatePosVel(posVels: var openArray[PosVel]): seq[seq[PosVelAxis]] =
  result = posVels.posVelsToPosVelsAxes()
  result[0].updatePosVel() # X
  result[1].updatePosVel() # Y
  result[2].updatePosVel() # Z

  # Update back posVels
  for i in 0 ..< numMoons:
    posVels[i].pos.x = result[0][i].pos; posVels[i].vel.x = result[0][i].vel
    posVels[i].pos.y = result[1][i].pos; posVels[i].vel.y = result[1][i].vel
    posVels[i].pos.z = result[2][i].pos; posVels[i].vel.z = result[2][i].vel

proc calcEnergy(posVelsAxes: openArray[seq[PosVelAxis]]): int =
  for i in 0 ..< numMoons:
    var
      pot: int
      kin: int
    for j in 0 ..< 3: # We have 3 axes X, Y, Z
      # Potential energy
      pot.inc(abs(posVelsAxes[j][i].pos))
      # Kinetic energy
      kin.inc(abs(posVelsAxes[j][i].vel))
    result.inc(pot*kin)

proc runTime(moons: openArray[Coord]; timeMax: int): int =
  var
    posVels: PosVelArr
    posVelsAxes: seq[seq[PosVelAxis]]
  for idx, moon in moons:
    posVels[idx] = PosVel(pos: moon, vel: zeroVelocity)

  for t in 0 ..< timeMax:
    posVelsAxes = updatePosVel(posVels)
    when defined(debug):
      for idx, posVel in posVels:
        if idx == 0:
          echo &"[{t:>4}] pos = {posVel.pos}, vel = {posVel.vel}"
        else:
          echo &"       pos = {posVel.pos}, vel = {posVel.vel}"
      echo ""
  result = posVelsAxes.calcEnergy()
  echo &"total energy after {timeMax} time steps = {result}"

proc timeToInitState(moons: openArray[Coord]): int =
  result = 1
  var
    posVels: PosVelArr
    timeToInit: array[3, int] # 3 for 3 axes
  for idx, moon in moons:
    posVels[idx] = PosVel(pos: moon)
  var
    posVelsAxes = posVels.posVelsToPosVelsAxes()

  # As the calculation for each axis independent of other axes, the pos/vel can be calculated
  # independently. The answer is "just an LCM" of the times takes for each of
  # X, Y and Z velocities to get back to 0.
  #
  # Below diagram (courtesy Reddit poster /u/eoincampbell) nicely visualizes how the X, Y, Z
  # coordinates cycle, how they are independent of each other and how LCM can calculate the
  # "sync point" for all 3 co-ordinates.
  #
  #  As an example, say X cycles every 3 steps, Y every 5, Z every 6.
  #
  #    X: __3__3__3__3__3__3__3__3__3__3__3__3__3__3__3__3__3__3__3__3
  #    Y: ____5____5____5____5____5____5____5____5____5____5____5____5
  #    Z: _____6_____6_____6_____6_____6_____6_____6_____6_____6_____6
  #                                    ^lcm-sync                     ^lcm-sync
  #
  # References:
  # - https://www.reddit.com/r/adventofcode/comments/e9j0ve/2019_day_12_solutions/fakf7lb
  # - https://github.com/AxlLind/AdventOfCode2019/blob/master/src/bin/12-bonus.rs
  # - Above diagram: https://www.reddit.com/r/adventofcode/comments/e9tjel/2019_day_12_2_c_need_an_satisfactory_explanation/
  for i in 0 ..< 3:
    while true:
      posVelsAxes[i].updatePosVel()
      # Tip to just check when the velocity becomes zero once again
      # and just multiplying that by 2 to get the time for the moon to
      # get back to the init position comes from:
      # - https://www.reddit.com/r/adventofcode/comments/e9nqpq/day_12_part_2_2x_faster_solution/
      # - https://github.com/wborgeaud/adventofcode2019-rust-python/blob/29c8a820cda5b92f9e579184f04c828b60b09225/Day-12/sol/src/main.rs#L125
      var
        velBackToZero = posVelsAxes[i][0].vel == 0
      for j in 1 ..< numMoons:
        if velBackToZero:
          velBackToZero = posVelsAxes[i][j].vel == 0
      timeToInit[i].inc
      if velBackToZero:
        break
  result = 2*timeToInit[0].lcm(timeToInit[1]).lcm(timeToInit[2])

when isMainModule:
  import std/[unittest]

  suite "day12 part1 tests":

    test "example 1":
      check:
        "example1.txt".parseCoords().runTime(10) == 179

    test "example 2":
      check:
        "example2.txt".parseCoords().runTime(100) == 1940

  suite "day12 part1 challenge":
    test "check":
      check:
        "input.txt".parseCoords().runTime(1000) == 9127

  suite "day12 part2 tests":

    test "example 1":
      check:
        "example1.txt".parseCoords().timeToInitState() == 2772

    test "example 2":
      check:
        "example2.txt".parseCoords().timeToInitState() == 4686774924.int

  suite "day12 part2 challenge":
    test "check":
      check:
        "input.txt".parseCoords().timeToInitState() == 353620566035124.int
