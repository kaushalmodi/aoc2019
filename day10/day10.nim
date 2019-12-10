import std/[strformat, strutils, tables, math]

type
  Coord = tuple
    x: int
    y: int
  Map = Table[Coord, int]

proc initMap(map: seq[string]): Map =
  for y, line in map:
    for x, ch in line.strip():
      if ch == '#':
        result[(x, y).Coord] = 0

proc calcAngle(a, b: Coord): float =
  ## Return the angle of ``a`` looking at ``b`` in degrees.
  ## Angle is 0 degrees when ``b`` is in a straight line above ``a``.
  ## Angle is 90 degrees when ``b`` is in a straight line to the right of ``a``.
  ## Angle is 180 degrees when ``b`` is in a straight line below ``a``.
  ## And so on ..
  doAssert a != b
  if a.x == b.x:
    if a.y > b.y:
      return 0.0 # b is in a straight line above a
    else:
      return 180.0 # b is in a straight line below a
  if a.y == b.y:
    if a.x < b.x:
      return 90.0 # b is in a straight line to the right of a
    else:
      return 90.0 + 180.0 # b is in a straight line to the left of a
  let
    oppAdj = abs(a.y - b.y) / abs(a.x - b.x)
    acuteAngleAlongXAxis = oppAdj.arctan().radToDeg()
  if a.x < b.x:
    if b.y < a.y: # b is in top-right quadrant with respect to a
      return 90.0 - acuteAngleAlongXAxis
    else: # b is in bottom-right quadrant with respect to a
      return 90.0 + acuteAngleAlongXAxis
  else:
    if b.y < a.y: # b is in top-left quadrant with respect to a
      return 270.0 + acuteAngleAlongXAxis
    else: # b is in bottom-left quadrant with respect to a
      return 270.0 - acuteAngleAlongXAxis

proc updateAsteroidsDetCounts(map: var Map; loc: Coord) =
  var
    angleMap: Table[float, bool]
  for coord in map.keys:
    if coord == loc:
      continue
    else:
      let
        angle = calcAngle(loc, coord)
      when defined(debug2):
        echo &"{coord} at {angle}"
      angleMap[angle] = true
  let
    seenAsteroids = angleMap.len
  when defined(debug):
    echo &"{seenAsteroids} asteroids seen from {loc}"
  map[loc] = seenAsteroids

proc maxNumAsteroidsDetected(mapStr: seq[string]): (Coord, int) =
  var
    map = mapStr.initMap()
  for coord in map.keys:
    map.updateAsteroidsDetCounts(coord)
    if map[coord] > result[1]:
      result = (coord, map[coord])

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day10 tests":
    test "example 1":
      check:
        "example1.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((3, 4).Coord, 8)

    test "example 2":
      check:
        "example2.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((5, 8).Coord, 33)

    test "example 3":
      check:
        "example3.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((1, 2).Coord, 35)

    test "example 4":
      check:
        "example4.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((6, 3).Coord, 41)

    test "example 5":
      check:
        "example5.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((11, 13).Coord, 210)

  suite "day10 part1 challenge":
    test "check":
      check:
        "input.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((19, 14).Coord, 274)
