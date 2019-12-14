import std/[strformat, strutils, strscans, math, sequtils]
import days_utils

const
  numAxes = 3
  numMoons = 4

type
  Coord1Arr = array[numMoons, int] # an array of values of the same coordinate for all moons
  Coord3Arr = array[numAxes, Coord1Arr] # an array of Coord1Arr elements, one for each of X, Y, Z

proc parseCoords(fileName: string): Coord3Arr =
  let
    posSeq = fileName.prjDir().readFile().strip().splitLines()
  for i, pos in posSeq:
    var
      axes: array[numAxes, int]
    discard scanf(pos, "<x=$i, y=$i, z=$i>", axes[0], axes[1], axes[2])
    for j, axis in axes:
      result[j][i] = axis

proc updatePosVel(posz: var Coord1Arr, velz: var Coord1Arr) =
  for i in 0 .. posz.high:
    for j in i+1 .. posz.high:
      let
        moonICloser = -cmp(posz[i], posz[j])
      # Update velocity.
      velz[i].inc(moonICloser); velz[j].inc(-moonICloser)
    # Update position.
    posz[i].inc(velz[i])

proc calcEnergy(posz: var Coord3Arr, velz: var Coord3Arr): array[numMoons, int] =
  for m in 0 ..< numMoons:
    var
      pot, kin: array[numMoons, int]
    for axis in 0 ..< numAxes:
      # Potential energy
      pot[m].inc(abs(posz[axis][m]))
      # Kinetic energy
      kin[m].inc(abs(velz[axis][m]))
    result[m] = pot[m]*kin[m]

proc runForTime(posz: var Coord3Arr; timeMax: int): int =
  var
    velz: Coord3Arr
  for t in 0 ..< timeMax:
    for axis in 0 ..< numAxes:
      updatePosVel(posz[axis], velz[axis])
    when defined(debug):
      for i in 0 ..< numMoons:
        if i == 0:
          echo &"[{t:>4}] pos = ({posz[0][i]}, {posz[1][i]}, {posz[2][i]}), vel = ({velz[0][i]}, {velz[1][i]}, {velz[2][i]})"
        else:
          echo &"       pos = ({posz[0][i]}, {posz[1][i]}, {posz[2][i]}), vel = ({velz[0][i]}, {velz[1][i]}, {velz[2][i]})"
      echo ""
  result = calcEnergy(posz, velz).foldl(a+b)
  echo &"total energy after {timeMax} time steps = {result}"

proc timeToInitState(posz: var Coord3Arr): int =
  result = 1
  var
    velz: Coord3Arr
    timeToInit: array[numAxes, int]

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
  for axis in 0 ..< numAxes:
    while true:
      updatePosVel(posz[axis], velz[axis])
      # Tip to just check when the velocity becomes zero once again
      # and just multiplying that by 2 to get the time for the moon to
      # get back to the init position comes from:
      # - https://www.reddit.com/r/adventofcode/comments/e9nqpq/day_12_part_2_2x_faster_solution/
      # - https://github.com/wborgeaud/adventofcode2019-rust-python/blob/29c8a820cda5b92f9e579184f04c828b60b09225/Day-12/sol/src/main.rs#L125
      var
        velBackToZero = velz[axis][0] == 0
      for m in 1 ..< numMoons:
        if velBackToZero:
          velBackToZero = velz[axis][m] == 0
      timeToInit[axis].inc
      if velBackToZero:
        break
  # Do an LCM of timeToInit for all axes
  when (NimMajor, NimMinor, NimPatch) <= (1, 0, 99): # For Nim 1.0.x and older
    result = 2*timeToInit[0].lcm(timeToInit[1]).lcm(timeToInit[2])
  else:
    result = 2*lcm(timeToInit)

when isMainModule:
  import std/[unittest]

  suite "day12 example 1 tests":
    setup:
      var
        posz = "example1.txt".parseCoords()

    test "example 1 part 1":
      check:
        posz.runForTime(10) == 179

    test "example 1 part 2":
      check:
        posz.timeToInitState() == 2772

  suite "day12 example 2 tests":
    setup:
      var
        posz = "example2.txt".parseCoords()

    test "example 2 part 1":
      check:
        posz.runForTime(100) == 1940

    test "example 2 part 2":
      check:
        posz.timeToInitState() == 4686774924.int

  suite "day12 challenges":
    setup:
      var
        posz = "input.txt".parseCoords()

    test "part1":
      check:
        posz.runForTime(1000) == 9127

    test "part2":
      check:
        posz.timeToInitState() == 353620566035124.int
