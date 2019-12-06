import std/[os, strformat]
when defined(debug):
  import std/[strutils]
import days_utils

type
  OpCode = enum
    opAdd = 1
    opMul = 2
    opHalt = 99

proc process(codes: seq[int]): seq[int] =
  result = codes
  var
    address = 0

  while address < codes.len():
    let
      code = result[address].OpCode
    case code
    of opAdd:
      when defined(debug):
        echo &"[{address}] Add code {code.ord} detected"
      result[codes[address+3]] = result[codes[address+1]] + result[codes[address+2]]
      address.inc(4) # skip operands and output pointer registers
    of opMul:
      when defined(debug):
        echo &"[{address}] Mul code {code.ord} detected"
      result[codes[address+3]] = result[codes[address+1]] * result[codes[address+2]]
      address.inc(4) # skip operands and output pointer registers
    of opHalt:
      when defined(debug):
        echo &"[{address}] Halt code {code.ord} detected, aborting .."
      break

  when defined(debug):
    echo &"Modified codes: {result}"

proc state(fileName: string, noun = -1, verb = -1): int =
  var
    codes = fileName.readFileToSeq()
  if noun in {0 .. 99}:
    codes[1] = noun
  if verb in {0 .. 99}:
    codes[2] = verb
  let
    modCodes = codes.process()
  when defined(debug):
    echo &"value at position 0: {modCodes[0]}"
  return modCodes[0]

when isMainModule:
  import std/[unittest]

  const
    inputFile = currentSourcePath.parentDir() / "input.txt"

  if paramCount() > 0:
    echo commandLineParams()[0].readFileToSeq().process()
  else:
    let
      specialOutput = 19690720
    block nvLoop:
      for n in 0 .. 99:
        for v in 0 .. 99:
          if state(inputFile, n, v) == specialOutput:
            echo &"output matched with {specialOutput}!"
            echo &"{100*n + v}"
            break nvLoop

    suite "day2 tests":
      test "example":
        check:
          @[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50].process() == @[3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50]
      test "add 1":
        check:
          @[1, 0, 0, 0, 99].process() == @[2, 0, 0, 0, 99]
      test "mul 1":
        check:
          @[2, 3, 0, 3, 99].process() == @[2, 3, 0, 6, 99]
      test "mul 2":
        check:
          @[2, 4, 4, 5, 99, 0].process() == @[2, 4, 4, 5, 99, 9801]
      test "add + mul":
        check:
          @[1, 1, 1, 4, 99, 5, 6, 0, 99].process() == @[30, 1, 1, 4, 2, 5, 6, 0, 99]
      test "1202 program alert":
        check:
          state(inputFile, 12, 2) == 4138658
