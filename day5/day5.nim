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
        inp1 = @[3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8]
        inp2 = @[3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8]
        inp3 = @[3, 3, 1108, -1, 8, 3, 4, 3, 99]
        inp4 = @[3, 3, 1107, -1, 8, 3, 4, 3, 99]
        inp5 = @[3, 12, 6, 12, 15, 1, 13, 14, 13, 4, 13, 99, -1, 0, 1, 9]
        inp6 = @[3, 3, 1105, -1, 9, 1101, 0, 0, 12, 4, 12, 99, 1]
        inp7 = @[3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107,    # addr  0 ->  9
                 8, 21, 20, 1006, 20, 31, 1106, 0, 36, 98,     # addr 10 -> 19
                 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1,      # addr 20 -> 29
                 46, 104, 999, 1105, 1, 46, 1101, 1000, 1, 20, # addr 30 -> 39
                 4, 20, 1105, 1, 46, 98, 99]                   # addr 40 -> 46

    test "parameter mode test":
      check:
        @[1002, 4, 3, 4, 33].process().modCodes == @[1002, 4, 3, 4, 99]

    test "input/output test":
      check:
        @[3, 0, 4, 0, 99].process(testInput = randVal).modCodes == @[randVal, 0, 4, 0, 99]

    test "position mode, check if input is == 8":
      check:
        inp1.process(testInput = 7).output == 0
        inp1.process(testInput = 8).output == 1
        inp1.process(testInput = 9).output == 0

    test "position mode, check if input is < 8":
      check:
        inp2.process(testInput = 7).output == 1
        inp2.process(testInput = 8).output == 0
        inp2.process(testInput = 9).output == 0

    test "immediate mode, check if input is == 8":
      check:
        inp3.process(testInput = 7).output == 0
        inp3.process(testInput = 8).output == 1
        inp3.process(testInput = 9).output == 0

    test "immediate mode, check if input is < 8":
      check:
        inp4.process(testInput = 7).output == 1
        inp4.process(testInput = 8).output == 0
        inp4.process(testInput = 9).output == 0

    test "position mode, jump test":
      check:
        inp5.process(testInput = 0).output == 0
        inp5.process(testInput = 100).output == 1

    test "immediate mode, jump test":
      check:
        inp6.process(testInput = 0).output == 0
        inp6.process(testInput = 999).output == 1

    test "a more complex test":
      check:
        # output 999 for input < 8
        inp7.process(testInput = 7).output == 999
        # output 1000 for input < 8
        inp7.process(testInput = 8).output == 1000
        # output 1001 for input > 8
        inp7.process(testInput = 9).output == 1001

  suite "day5 part1 challenge":
    setup:
      const
        idAirConditionerUnit = 1

    test "check":
      check:
        inputFile.readFileToSeq().process(testInput = idAirConditionerUnit).output == 10987514

  suite "day5 part2 challenge":
    setup:
      const
        idThermalRadiatorController = 5

    test "check":
      check:
        inputFile.readFileToSeq().process(testInput = idThermalRadiatorController).output == 14195011
