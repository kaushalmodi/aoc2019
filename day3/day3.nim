import std/[os, strutils, tables]
when defined(debug):
  import std/[strformat]

type
  Direction = enum
    dirDown = 'D'
    dirLeft = 'L'
    dirRight = 'R'
    dirUp = 'U'

type
  Coord = tuple
    x: int
    y: int
  MapVal = tuple
    hits: int
    steps: int
  MinStuff = tuple
    minDist: int # Manhattan distance
    minSteps: int
  CoordTable = Table[Coord, MapVal]

proc updateMap(wirePath: seq[string]; map: var CoordTable) =
  var
    turtle: Coord = (0, 0)
    localMap: CoordTable

  for point in wirePath:
    let
      dir = point[0].Direction
      dist = point[1 .. point.high].parseInt()
    for i in 1 .. dist:
      case dir
      of dirRight: turtle.x.inc
      of dirLeft: turtle.x.dec
      of dirUp: turtle.y.inc
      of dirDown: turtle.y.dec
      if not localMap.hasKey(turtle) and map.hasKey(turtle):
        # Increment the count only if the same wire did not intersect
        # itself.
        map[turtle].hits.inc
      else:
        map[turtle] = (1, 0).MapVal
      localMap[turtle] = (1, 0).MapVal

proc getMin(wires: seq[string]): MinStuff =
  doAssert wires.len == 2

  var
    map: CoordTable
  when defined(debug):
    var
      intersectMap: CoordTable

  for wire in wires:
    wire.split(',').updateMap(map)
    # echo map

  for k, v in map.pairs:
    if v.hits > 1:
      when defined(debug):
        intersectMap[k] = v
      let
        dist = abs(k.x) + abs(k.y)
      when defined(debug):
        echo &"distance for {k} = {dist}"
      if result.minDist == 0 or dist < result.minDist:
        result.minDist = dist
  when defined(debug):
    echo intersectMap

when isMainModule:
  import std/[unittest]

  suite "day3 tests":
    setup:
      const
        pathSets = [@["R8,U5,L5,D3",
                      "U7,R6,D4,L4"],
                    @["R75,D30,R83,U83,L12,D49,R71,U7,L72",
                      "U62,R66,U55,R34,D71,R55,D58,R83"],
                    @["R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
                      "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7"]]

    test "part 1 example 1":
      check:
        getMin(pathSets[0]).minDist == 6
    test "part 1 example 2":
      check:
        getMin(pathSets[1]).minDist == 159
    test "part 1 example 3":
      check:
        getMin(pathSets[2]).minDist == 135

  suite "day3 challenges":
    setup:
      let
        inputFile = currentSourcePath.parentDir() / "input.txt"
        inputPathSet = inputFile.readFile().strip().splitLines()

    test "part1":
      check:
        inputPathSet.getMin().minDist == 709
