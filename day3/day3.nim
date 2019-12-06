import std/[os, strutils]

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

proc getCoordinates(wirePath: seq[string]): seq[Coord] =
  var
    turtle: Coord = (0, 0)

  for point in wirePath:
    let
      dir = point[0].Direction
      dist = point[1 .. point.high].parseInt()
    # echo &"{dir} {dist}"
    case dir
    of dirRight:
      for i in turtle.x+1 .. turtle.x+dist:
        result.add((i, turtle.y).Coord)
      turtle.x.inc(dist)
    of dirLeft:
      for i in countdown(turtle.x-1, turtle.x-dist):
        result.add((i, turtle.y).Coord)
      turtle.x.dec(dist)
    of dirUp:
      for i in turtle.y+1 .. turtle.y+dist:
        result.add((turtle.x, i).Coord)
      turtle.y.inc(dist)
    of dirDown:
      for i in countdown(turtle.y-1, turtle.y-dist):
        result.add((turtle.x, i).Coord)
      turtle.y.dec(dist)

proc manhattanDistance(wires: seq[string]): int =
  doAssert wires.len == 2
  let
    firstWireCoords = wires[0].split(',').getCoordinates()
    secondWireCoords = wires[1].split(',').getCoordinates()
  # echo firstWireCoords
  # echo secondWireCoords

  var
    intersectionCoords: seq[Coord]
  for c1 in firstWireCoords:
    for c2 in secondWireCoords:
      if c1 == c2:
        intersectionCoords.add(c1)

  # echo intersectionCoords
  for i in intersectionCoords:
    let
      dist = abs(i.x) + abs(i.y)
    if result == 0 or dist < result:
      result = dist

when isMainModule:
  import std/[unittest]

  suite "day2 tests":
    test "example 1":
      check:
        manhattanDistance(@["R8,U5,L5,D3",
                            "U7,R6,D4,L4"]) == 6
    test "example 2":
      check:
        manhattanDistance(@["R75,D30,R83,U83,L12,D49,R71,U7,L72",
                            "U62,R66,U55,R34,D71,R55,D58,R83"]) == 159
    test "example 3":
      check:
        manhattanDistance(@["R98,U47,R26,D63,R33,U87,L62,D20,R33,U53,R51",
                            "U98,R91,D20,R16,D67,R40,U7,R15,U6,R7"]) == 135

  const
    inputFile = currentSourcePath.parentDir() / "input.txt"
  doAssert inputFile.readFile().strip().splitLines().manhattanDistance() == 709
