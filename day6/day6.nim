import std/[strutils, critbits]
when defined(debug):
  import std/[strformat]

type
  Map = CritBitTree[string]
  OrbitDist = tuple
    orbit: string
    dist: int

proc genMap(uob: seq[string]): Map =
  for orbit in uob:
    let
      elems = orbit.split(')')
      heavy = elems[0]
      light = elems[1]
    when defined(debug2):
      echo &"{light} orbits around {heavy}"
    # A light body can orbit only around one heavy object. So the map
    # must contain only one light -> heavy mapping.
    doAssert not result.contains(light)
    result[light] = heavy

proc getNumOrbits(map: Map; light: string; numOrbits: var int; path: var seq[OrbitDist]) =
  numOrbits.inc
  path.add((light, numOrbits-2))
  when defined(debug):
    stdout.write &"{light}:{numOrbits}, "
  if map[light] == "COM":
    when defined(debug):
      echo "COM"
    return
  else:
    getNumOrbits(map, map[light], numOrbits, path)

proc getNumOrbits(uob: seq[string]): int =
  ## Calculate the total number of direct and indirect
  ## orbits from the Universal Orbital Map (uob).
  let
    map = uob.genMap()
  for light in map.keys:
    var
      numOrbits: int
      path: seq[OrbitDist] # unused but need to declared it
    getNumOrbits(map, light, numOrbits, path)
    result.inc(numOrbits)

proc minOrbitalTransfers(uob: seq[string]; fromOrbit = "YOU", toOrbit = "SAN"): int =
  let
    map = uob.genMap()
  var
    numOrbits1: int
    path1: seq[OrbitDist]
    numOrbits2: int
    path2: seq[OrbitDist]
  getNumOrbits(map, fromOrbit, numOrbits1, path1)
  getNumOrbits(map, toOrbit, numOrbits2, path2)
  when defined(debug):
    echo path1
    echo path2

  for o1 in path1:
    for o2 in path2:
      if o1.orbit == o2.orbit:
        return o1.dist + o2.dist

when isMainModule:
  import std/[unittest]
  import days_utils

  suite "day6 tests":
    setup:
      let
        uob1 = "example1.txt".prjDir().readFile().strip().splitLines()
        uob2 = "example2.txt".prjDir().readFile().strip().splitLines()

    test "example 1":
      check:
        uob1.getNumOrbits() == 42

    test "example 2":
      check:
        uob2.minOrbitalTransfers() == 4

  suite "day6 challenge":
    setup:
      let
        uob = "input.txt".prjDir().readFile().strip().splitLines()
    test "check":
      check:
        uob.getNumOrbits() == 158090
        uob.minOrbitalTransfers() == 241
