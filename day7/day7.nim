import std/[os, strformat, sequtils]
import days_utils, day2 # intcode

const
  inputFile = currentSourcePath.parentDir() / "input.txt"
  ampControllerSw = inputFile.readFileToSeq()
  numAmps = 5

proc ampSeries(sw: seq[int], phaseInputs: array[numAmps, int]): int =
  var
    state: array[numAmps, ProcessOut]
  state[0] = sw.process(@[phaseInputs[0].int, 0])
  for i in 1 ..< numAmps:
    state[i] = sw.process(@[phaseInputs[i].int, state[i-1].output])
  while true:
    if state[^1].address == -1:
      # address==-1 in the returned state means that that amp's
      # intcode process saw the 99 opcode and it's now in Halt state.
      break
    state[0] = state[0].modCodes.process(@[state[^1].output], state[0].address)
    #                                      ^^^^^^^^ feedback from last stage of amp
    for i in 1 ..< numAmps:
      state[i] = state[i].modCodes.process(@[state[i-1].output], state[i].address)
  result = state[^1].output

proc getHighestSignal(feedbackLoop = false): int =
  let
    phaseSet = if feedbackLoop:
                 {5'u8, 6, 7, 8, 9}
               else:
                 {0'u8, 1, 2, 3, 4}
  var
    output: int
    cnt = 1
  for p1 in phaseSet:
    for p2 in phaseSet-{p1}:
      for p3 in phaseSet-{p1}-{p2}:
        for p4 in phaseSet-{p1}-{p2}-{p3}:
          for p5 in phaseSet-{p1}-{p2}-{p3}-{p4}:
            echo &"Attempt {cnt} ::"
            output = ampControllerSw.ampSeries([p1.int, p2.int, p3.int, p4.int, p5.int])
            echo &"{p1} {p2} {p3} {p4} {p5} .. {output} [max: {result}]"
            echo ""
            if output > result:
              result = output
            cnt.inc

when isMainModule:
  import std/[unittest]

  suite "day7 tests":
    test "thruster signal tests":
      check:
        @[3, 15, 3, 16, 1002, 16, 10, 16, 1, 16,
          15, 15, 4, 15, 99, 0, 0].ampSeries([4, 3, 2, 1, 0]) == 43210

        @[3, 23, 3, 24, 1002, 24, 10, 24, 1002, 23,
          -1, 23, 101, 5, 23, 23, 1, 24, 23, 23,
          4, 23, 99, 0, 0].ampSeries([0, 1, 2, 3, 4]) == 54321

        @[3, 31, 3, 32, 1002, 32, 10, 32, 1001, 31,
          -2, 31, 1007, 31, 0, 33, 1002, 33, 7, 33,
          1, 33, 31, 31, 1, 32, 31, 31, 4, 31,
          99, 0, 0, 0].ampSeries([1, 0, 4, 3, 2]) == 65210

    test "thruster signal (with feedback loop) tests":
      check:
        @[3, 26, 1001, 26, -4, 26, 3, 27, 1002, 27, 2, 27, 1, 27, 26,
          27, 4, 27, 1001, 28, -1, 28, 1005, 28, 6, 99, 0, 0, 5].ampSeries([9, 8, 7, 6, 5]) == 139629729

        @[3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,
          -5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,
          53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10].ampSeries([9, 7, 8, 5, 6]) == 18216

  suite "day7 part1 challenge":
    test "check":
      check:
        ampControllerSw.ampSeries([3, 1, 2, 4, 0]) == 7560
        getHighestSignal() == 17440

  suite "day7 part2 challenge":
    test "check":
      check:
        getHighestSignal(feedbackLoop = true) == 27561242
