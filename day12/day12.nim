import std/[strformat, strutils, strscans]
import days_utils

type
  Coord = object
    x: int
    y: int
    z: int
  CoordArr = array[4, Coord]
  PosVel = object
    pos: Coord
    vel: Coord
  PosVelArr = array[4, PosVel]

proc parseCoords(fileName: string): CoordArr =
  let
    moons = fileName.prjDir().readFile().strip().splitLines()
  for idx, moon in moons:
    var
      x, y, z: int
    discard scanf(moon, "<x=$i, y=$i, z=$i>", x, y, z)
    result[idx] = Coord(x: x, y: y, z: z)

proc applyVelocity(posVel: var PosVel) =
  posVel.pos.x += posVel.vel.x
  posVel.pos.y += posVel.vel.y
  posVel.pos.z += posVel.vel.z

proc applyGravity(posVels: var openArray[PosVel]) =
  for i in 0 .. posVels.high:
    for j in i+1 .. posVels.high:
      if posVels[i].pos.x < posVels[j].pos.x:
        posVels[i].vel.x.inc
        posVels[j].vel.x.dec
      elif posVels[i].pos.x > posVels[j].pos.x:
        posVels[i].vel.x.dec
        posVels[j].vel.x.inc

      if posVels[i].pos.y < posVels[j].pos.y:
        posVels[i].vel.y.inc
        posVels[j].vel.y.dec
      elif posVels[i].pos.y > posVels[j].pos.y:
        posVels[i].vel.y.dec
        posVels[j].vel.y.inc

      if posVels[i].pos.z < posVels[j].pos.z:
        posVels[i].vel.z.inc
        posVels[j].vel.z.dec
      elif posVels[i].pos.z > posVels[j].pos.z:
        posVels[i].vel.z.dec
        posVels[j].vel.z.inc
    posVels[i].applyVelocity()

proc calcEnergy(posVels: var openArray[PosVel]): int =
  for posVel in posVels:
    var
      pot: int
      kin: int
    for val in posVel.pos.fields: pot.inc(abs(val))
    for val in posVel.vel.fields: kin.inc(abs(val))
    result.inc(pot*kin)

proc runTime(moons: openArray[Coord]; timeMax: int): int =
  var
    posVels: PosVelArr
  for idx, moon in moons:
    posVels[idx] = PosVel(pos: moon)

  for t in 0 ..< timeMax:
    applyGravity(posVels)
    when defined(debug):
      for idx, posVel in posVels:
        if idx == 0:
          echo &"[{t:>4}] pos = {posVel.pos}, vel = {posVel.vel}"
        else:
          echo &"       pos = {posVel.pos}, vel = {posVel.vel}"
      echo ""
  result = posVels.calcEnergy()
  echo &"total energy after {timeMax} time steps = {result}"

proc timeToInitState(moons: openArray[Coord]): int =
  result = 1
  var
    posVels: PosVelArr
  for idx, moon in moons:
    posVels[idx] = PosVel(pos: moon)

  while true:
    applyGravity(posVels)
    var
      backToInit = true
    backToInit = posVels[0].pos == moons[0]
    if backToInit:
      backToInit = posVels[1].pos == moons[1]
      if backToInit:
        backToInit = posVels[2].pos == moons[2]
        if backToInit:
          backToInit = posVels[3].pos == moons[3]
    result.inc
    if backToInit:
      break
    when defined(profile):
      if result == 1_000_000:
        break

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

    # Thu Dec 12 08:34:46 EST 2019 - kmodi
    # FIXME Commenting the below test until this code is optimized for speed.
    # test "example 2":
    #   check:
    #     "example2.txt".parseCoords().timeToInitState() == 4686774924.int

  # Thu Dec 12 08:34:46 EST 2019 - kmodi
  # FIXME Commenting the below test until this code is optimized for speed.
  # suite "day12 part2 challenge":
  #   test "check":
  #     check:
  #       "input.txt".parseCoords().timeToInitState() == 4686774924.int

  when defined(profile):
    echo "Running profiling proc .."
    discard "example2.txt".parseCoords().timeToInitState()
