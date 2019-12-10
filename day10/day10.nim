import std/[strutils, tables, math, algorithm]
when defined(debug):
  import std/[strformat]

type
  Coord = tuple
    x: int
    y: int
  Map = Table[Coord, int]
  SlopeMap = OrderedTable[float, tuple[coord: Coord, dist: float]]

proc initMap(map: seq[string]): Map =
  for y, line in map:
    for x, ch in line.strip():
      if ch == '#':
        result[(x, y).Coord] = 0

when not defined(usingArctan):
  proc calcSlope(a, b: Coord; flipX = false, flipY = false): float =
    ## Return the slope of ``a`` looking at ``b`` in degrees.
    ## Slope is 0 degrees when ``b`` is in a straight line above ``a``.
    ## Slope is 90 degrees when ``b`` is in a straight line to the right of ``a``.
    ## Slope is 180 degrees when ``b`` is in a straight line below ``a``.
    ## And so on ..
    doAssert a != b
    let
      yDelta = (b.y - a.y).float * pow(-1, float(flipY))
      xDelta = (b.x - a.x).float * pow(-1, float(flipX))
    result = arctan2(xDelta, yDelta).radToDeg()
    if result < 0:
      result = result + 360
else:                       # The flipX and flipY params below are just for
                            # compatibility with the above proc's signature.
  proc calcSlope(a, b: Coord; flipX = false, flipY = false): float =
    ## Return the slope of ``a`` looking at ``b`` in degrees.
    ## Slope is 0 degrees when ``b`` is in a straight line above ``a``.
    ## Slope is 90 degrees when ``b`` is in a straight line to the right of ``a``.
    ## Slope is 180 degrees when ``b`` is in a straight line below ``a``.
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

proc calcDistance(a, b: Coord): float =
  ## Return distance between Cartesian coordinates ``a`` and ``b``.
  return ((a.x-b.x)^2 + (a.y-b.y)^2).float.sqrt()

proc updateAsteroidsDetCounts(map: var Map; loc: Coord): SlopeMap =
  for coord in map.keys:
    if coord == loc:
      continue
    let
      # From the puzzle description:
      #   The asteroids can be described with X,Y coordinates where X is
      #   the distance from the left edge and Y is the distance from the
      #   top edge (so the top-left corner is 0,0 and the position
      #   immediately to its right is 1,0).
      # So the Y axis is actually flipped! .. numbers are incrementing
      # while going downwards on Y axis.
      slope = calcSlope(loc, coord, flipY = true)
      dist = calcDistance(loc, coord)
    when defined(debug):
      echo &"{coord} :: {slope} {dist}"
    if not result.hasKey(slope) or
       result.hasKey(slope) and dist < result[slope].dist:
      result[slope] = (coord, dist)

  # Sort the SlopeMap type table by the slope keys.
  result.sort(cmp)

  when defined(debug3):
    echo &"From {loc} asteroid:"
    for slope in result.keys:
      echo &"  {result[slope].coord} at {slope}"
  let
    seenAsteroids = result.len
  when defined(debug3):
    echo &"{seenAsteroids} asteroids seen from {loc}"
  map[loc] = seenAsteroids

proc maxNumAsteroidsDetected(map: var Map): (Coord, int) =
  for coord in map.keys:
    discard map.updateAsteroidsDetCounts(coord)
    if map[coord] > result[1]:
      result = (coord, map[coord])

proc getVaporizedAsteroids(map: var Map; loc: Coord): seq[Coord] =
  var
    mapCopy = map
  while true:
    let
      slopeMap = mapCopy.updateAsteroidsDetCounts(loc)
    mapCopy.del(loc) # Remove the current asteroid from the map
    for key, val in slopeMap.pairs:
      mapCopy.del(val.coord)
      when defined(debug):
        echo &".. Vaporized asteroid {result.len:>3} at {val.coord} @ {key}"
      result.add(val.coord)
    if mapCopy.len == 0:
      break

when isMainModule:
  import std/[unittest]
  import days_utils

  proc maxNumAsteroidsDetected(mapStr: seq[string]): (Coord, int) =
    var
      map = mapStr.initMap()
    return map.maxNumAsteroidsDetected()

  suite "day10 small examples":
    test "example 1":
      check:
        "example1.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((3, 4), 8)

    test "example 2":
      check:
        "example2.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((5, 8), 33)

    test "example 3":
      check:
        "example3.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((1, 2), 35)

    test "example 4":
      check:
        "example4.txt".readFileToStrSeq().maxNumAsteroidsDetected() == ((6, 3), 41)

  suite "day10 vaporize example":
    setup:
      var
        map = "example6.txt".readFileToStrSeq().initMap()
      let
        vaporizedAsteroids = map.getVaporizedAsteroids((8, 3))

    test "example 6":
      check:
        vaporizedAsteroids.len == 36
        #                        1 1 1 1 1 1 1
        #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6
        #  0 . # . . . . # # # 2 4 . . . # . .
        #  1 # # . . . # # . 1 3 # 6 7 . . 9 #
        #  2 # # . . . # . . . 5 . 8 # # # # .
        #  3 . . # . . . . . X . . . # # # . .
        #  4 . . # . # . . . . . # . . . . # #
        vaporizedAsteroids[0 .. 8] == @[(8, 1), (9, 0), (9, 1), (10, 0), (9, 2),
                                        (11, 1), (12, 1), (11, 2), (15, 1)]

        #                        1 1 1 1 1 1 1
        #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6
        #  0 . # . . . . # # # . . . . . # . .
        #  1 # # . . . # # . . . # . . . . . #
        #  2 # # . . . # . . . . . . 1 2 3 4 .
        #  3 . . # . . . . . X . . . 5 # # . .
        #  4 . . # . 9 . . . . . 8 . . . . 7 6
        vaporizedAsteroids[9 .. 17] == @[(12, 2), (13, 2), (14, 2), (15, 2), (12, 3),
                                         (16, 4), (15, 4), (10, 4), (4, 4)]

        #                        1 1 1 1 1 1 1
        #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6
        #  0 . 8 . . . . # # # . . . . . # . .
        #  1 5 6 . . . 9 # . . . # . . . . . #
        #  2 3 4 . . . 7 . . . . . . . . . . .
        #  3 . . 2 . . . . . X . . . . # # . .
        #  4 . . 1 . . . . . . . . . . . . . .
        vaporizedAsteroids[18 .. 26] == @[(2, 4), (2, 3), (0, 2), (1, 2), (0, 1),
                                          (1, 1), (5, 2), (1, 0), (5, 1)]

        #                        1 1 1 1 1 1 1
        #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6
        #  0 . . . . . . 2 3 4 . . . . . 6 . .
        #  1 . . . . . . 1 . . . 5 . . . . . 7
        #  2 . . . . . . . . . . . . . . . . .
        #  3 . . . . . . . . X . . . . 8 9 . .
        #  4 . . . . . . . . . . . . . . . . .
        vaporizedAsteroids[27 .. 35] == @[(6, 1), (6, 0), (7, 0), (8, 0), (10, 1),
                                          (14, 0), (16, 1), (13, 3), (14, 3)]

  suite "day10 big example":
    setup:
      const
        refCoord = (11, 13).Coord
      var
        map = "example5.txt".readFileToStrSeq().initMap()
      let
        vaporizedAsteroids = map.getVaporizedAsteroids(refCoord)

    test "example 5":
      check:
        map.maxNumAsteroidsDetected() == (refCoord, 210)
        vaporizedAsteroids.len == 299
        vaporizedAsteroids[0] == (11, 12)
        vaporizedAsteroids[1] == (12, 1)
        vaporizedAsteroids[2] == (12, 2)
        vaporizedAsteroids[9] == (12, 8)
        vaporizedAsteroids[19] == (16, 0)
        vaporizedAsteroids[49] == (16, 9)
        vaporizedAsteroids[99] == (10, 16)
        vaporizedAsteroids[198] == (9, 6)
        vaporizedAsteroids[199] == (8, 2)
        vaporizedAsteroids[200] == (10, 9)
        vaporizedAsteroids[298] == (11, 1)

  suite "day10 challenges":
    setup:
      var
        map = "input.txt".readFileToStrSeq().initMap()
        refVal = map.maxNumAsteroidsDetected()
      let
        vaporizedAsteroids = map.getVaporizedAsteroids(refVal[0])

    test "part1":
      check:
        refVal[1] == 274

    test "part2":
      check:
        vaporizedAsteroids[199].x * 100 + vaporizedAsteroids[199].y == 305
