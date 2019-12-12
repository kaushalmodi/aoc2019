import std/[strformat, strutils, strscans]
import days_utils

type
  Coord = object
    x: int
    y: int
    z: int
  CoordRef = ref Coord
  CoordRefArr = array[4, CoordRef]
  PosVel = object
    pos: CoordRef
    vel: CoordRef
  PosVelRef = ref PosVel
  PosVelRefArr = array[4, PosVelRef]

proc parseCoords(fileName: string): CoordRefArr =
  let
    moons = fileName.prjDir().readFile().strip().splitLines()
  for idx, moon in moons:
    var
      x, y, z: int
    discard scanf(moon, "<x=$i, y=$i, z=$i>", x, y, z)
    result[idx] = CoordRef(x: x, y: y, z: z)

proc applyVelocity(posVelRef: PosVelRef) =
  posVelRef.pos.x += posVelRef.vel.x
  posVelRef.pos.y += posVelRef.vel.y
  posVelRef.pos.z += posVelRef.vel.z

proc applyGravity(posVels: openArray[PosVelRef]) =
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

proc calcEnergy(posVels: var openArray[PosVelRef]): int =
  for posVel in posVels:
    var
      pot: int
      kin: int
    for val in posVel.pos[].fields: pot.inc(abs(val))
    for val in posVel.vel[].fields: kin.inc(abs(val))
    result.inc(pot*kin)

proc runTime(moons: openArray[CoordRef]; timeMax: int): int =
  var
    posVels: PosVelRefArr
  for idx, moonPosRef in moons:
    posVels[idx] = PosVelRef(pos: moonPosRef, vel: CoordRef())

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

proc timeToInitState(moons: openArray[CoordRef]): int =
  result = 1
  let
    initMoonsPos = [moons[0][], moons[1][], moons[2][], moons[3][]]
  var
    posVels: PosVelRefArr
  for idx, moonPosRef in moons:
    posVels[idx] = PosVelRef(pos: moonPosRef, vel: CoordRef())

  while true:
    applyGravity(posVels)
    var
      backToInit = true
    backToInit = posVels[0].pos[] == initMoonsPos[0]
    if backToInit:
      backToInit = posVels[1].pos[] == initMoonsPos[1]
      if backToInit:
        backToInit = posVels[2].pos[] == initMoonsPos[2]
        if backToInit:
          backToInit = posVels[3].pos[] == initMoonsPos[3]
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
