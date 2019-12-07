import std/[strutils, critbits]
when defined(debug):
  import std/[strformat]

type
  Map = CritBitTree[string]

proc genMap(uob: seq[string]): Map =
  for orbit in uob:
    let
      elems = orbit.split(')')
      heavy = elems[0]
      light = elems[1]
    when defined(debug):
      echo &"{light} orbits around {heavy}"
    # A light body can orbit only around one heavy object. So the map
    # must contain only one light -> heavy mapping.
    doAssert not result.contains(light)
    result[light] = heavy
  when defined(debug):
    echo result

proc getNumOrbits(map: Map; light: string; numOrbits: var int) =
  numOrbits.inc
  when defined(debug):
    stdout.write &"{light}, "
  if map[light] == "COM":
    when defined(debug):
      echo "COM"
    return
  else:
    getNumOrbits(map, map[light], numOrbits)

proc getNumOrbits(uob: seq[string]): int =
  ## Calculate the total number of direct and indirect
  ## orbits from the Universal Orbital Map (uob).
  let
    map = uob.genMap()
  for light in map.keys:
    var
      numOrbits: int
    getNumOrbits(map, light, numOrbits)
    result.inc(numOrbits)

when isMainModule:
  import std/[unittest]

  suite "day6 tests":
    setup:
      let
        uob = "example1.txt".readFile().strip().splitLines()
    test "example 1":
      check:
        uob.getNumOrbits() == 42

  suite "day6 part1 challenge":
    setup:
      let
        uob = "input.txt".readFile().strip().splitLines()
    test "check":
      check:
        uob.getNumOrbits() == 158090
