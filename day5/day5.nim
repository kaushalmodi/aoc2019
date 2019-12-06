import day2 # intcode

when isMainModule:
  import std/[os, unittest, random]
  import days_utils

  randomize()

  const
    inputFile = currentSourcePath.parentDir() / "input.txt"

  suite "day5 tests":
    setup:
      let
        randVal = rand(high(int8))

    test "parameter mode test":
      check:
        @[1002, 4, 3, 4, 33].process() == @[1002, 4, 3, 4, 99]

    test "input/output test":
      check:
        @[3, 0, 4, 0, 99].process(testInput = randVal) == @[randVal, 0, 4, 0, 99]

  suite "day5 part1 challenge":
    setup:
      let
        output = inputFile.readFileToSeq().process(testInput = 1)
        diagCodeLocation = output[221]
        diagCode = output[diagCodeLocation]

    test "check":
      check:
        diagCode == 10987514
