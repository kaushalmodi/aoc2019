import day2 # intcode

when isMainModule:
  import std/[unittest]

  suite "day5 tests":
    test "parameter mode tests":
      check:
        @[1002, 4, 3, 4, 33].process() == @[1002, 4, 3, 4, 99]

  # suite "day5 part1 challenge":
  #   test "check":
  #     check:
  #       someProc() == 100
