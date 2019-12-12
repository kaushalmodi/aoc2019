import std/[strformat, strutils, strscans, math]
# import std/[typetraits]
import days_utils

type
  Coord = tuple
    x: int
    y: int
    z: int
  PosVel = tuple
    pos: Coord
    vel: Coord

# let
#   numCoords = Coord.arity

proc parseCoords(fileName: string): seq[Coord] =
  let
    moons = fileName.prjDir().readFile().strip().splitLines()
  for idx, moon in moons:
    result.add((0, 0, 0))
    discard scanf(moon, "<x=$i, y=$i, z=$i>", result[idx].x, result[idx].y, result[idx].z)

proc applyGravity(posVels: var seq[PosVel]) =
  for i in 0 .. posVels.high:
    if i < posVels.high:
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
        # for idx in 0 ..< numCoords: # Error: cannot evaluate at compile time: idx
        #   if moons[i][idx] < moons[j][idx]:
        #     result[i][idx].inc
        #     result[j][idx].dec
        #   elif moons[i][idx] > moons[j][idx]:
        #     result[i][idx].dec
        #     result[j][idx].inc
  # echo &"vels = {result}"

proc applyVelocity(posVels: var seq[PosVel]) =
  for idx in 0 .. posVels.high:
    posVels[idx].pos.x += posVels[idx].vel.x
    posVels[idx].pos.y += posVels[idx].vel.y
    posVels[idx].pos.z += posVels[idx].vel.z

proc calcEnergy(posVels: var seq[PosVel]): int =
  for posVel in posVels:
    var
      pot: int
      kin: int
    for val in posVel.pos.fields: pot.inc(abs(val))
    for val in posVel.vel.fields: kin.inc(abs(val))
    result.inc(pot*kin)

proc runTime(moons: seq[Coord]; timeMax: int): int =
  var
    posVels = newSeq[PosVel](moons.len)
  for idx, moon in moons:
    posVels[idx].pos = moon
  for t in 0 ..< timeMax:
    applyGravity(posVels)
    applyVelocity(posVels)
    when defined(debug):
      for idx, posVel in posVels:
        if idx == 0:
          echo &"[{t:>4}] pos = {posVel.pos}, vel = {posVel.vel}"
        else:
          echo &"       pos = {posVel.pos}, vel = {posVel.vel}"
      echo ""
  result = posVels.calcEnergy()
  echo &"total energy after {timeMax} time steps = {result}"

when isMainModule:
  import std/[unittest]

  suite "day12 tests":

    test "example 1":
      check:
        "example1.txt".parseCoords().runTime(10) == 179

    test "example 2":
      check:
        "example2.txt".parseCoords().runTime(100) == 1940

  suite "day12 part1 challenge":
    test "check":
      check:
        "input.txt".parseCoords().runTime(1000) == 1940
