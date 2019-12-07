import std/[os, strformat]
import days_utils, day2 # intcode

const
  inputFile = currentSourcePath.parentDir() / "input.txt"
  ampControllerSw = inputFile.readFileToSeq()
  numAmps = 5
  phaseSet: set[uint8] = {0'u8, 1, 2, 3, 4}

proc ampSeries(sw: seq[int], phaseInputs: array[numAmps, int]): int =
  for i in 0 ..< numAmps:
    var
      signalInput = 0
    if i > 0:
      signalInput = result
    result = sw.process(inputs = @[phaseInputs[i].int, signalInput]).output
    echo &"[[{i}]] phase input = {phaseInputs[i]}, signal input->output = {signalInput}->{result}"

proc getHighestSignal(): int =
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

  suite "day7 part1 challenge":
    test "check":
      check:
        ampControllerSw.ampSeries([3, 1, 2, 4, 0]) == 7560
        getHighestSignal() == 17440
