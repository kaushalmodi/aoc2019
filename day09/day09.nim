import std/[strformat]
import days_utils, day02 # intcode

when isMainModule:
  import std/[unittest]

  suite "day9 tests":
    test "op code 9: adjust relative base":
      check:
        @[109, 8, 204, -1, 99, 0, 0, 100, 0, 200].process().output == 100
        #   0  1    2   3   4  5  6  7    8  9
        @[109, 8, 204,  1, 99, 0, 0, 100, 0, 200].process().output == 200

    test "64-bit support":
      check:
        @[1102, 34915192, 34915192, 7, 4, 7, 99, 0].process().output == 1219070632396864
        # Note set 'i64 conversion to the first element to let the
        # compiler know that the `codes` input to the `process` proc
        # needs to be `seq[int64]`.
        @[104'i64, 1125899906842624, 99].process().output == 1125899906842624

    test "available memory needed to be larger than the program memory":
      check:
        @[109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, 16, 101, 1006, 101, 0, 99].process().codes ==
        @[109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, #   0 -> 9
          16, 101, 1006, 101, 0, 99, 0, 0, 0, 0,         #  10 -> 19
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  20 -> 29
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  30 -> 39
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  40 -> 49
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  50 -> 59
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  60 -> 69
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  70 -> 79
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  80 -> 89
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0,                  #  90 -> 99
          16]                                            # 100

  suite "day9 part1 challenge":
    test "check":
      check:
        "input.txt".readFileToIntSeq().process(inputs = @[1]).output == 2932210790

  # suite "day9 part2 challenge":
  #   test "check":
  #     check:
