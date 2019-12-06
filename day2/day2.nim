import std/[strutils, tables]
when defined(debug) or isMainModule:
  import std/[strformat]

const
  maxNumParameters* = 3
  maxOpCodeLen* = 2
  maxCodeLen* = maxNumParameters + maxOpCodeLen

type
  Mode* = enum
    modePosition = 0
    modeImmediate
  OpCode* = enum
    opAdd = 1
    opMul = 2
    opInput = 3
    opOutput = 4
    opHalt = 99
  Code* = tuple
    op: OpCode
    modes: array[maxNumParameters, Mode]
  Spec* = tuple
    numInputs: int
    outParamIdx: int

# opcode spec
var
  spec: Table[int, Spec]
spec[opAdd.ord] = (2, 2).Spec
spec[opMul.ord] = (2, 2).Spec
spec[opHalt.ord] = (0, -1).Spec

proc parseCode*(code: int): Code =
  doAssert code >= 1 # opAdd
  let
    codeStr = $code
    codeLen = codeStr.len
  doAssert codeLen <= maxCodeLen
  case codeLen
  of 1, 2:
    result.op = code.OpCode
    result.modes = [modePosition, modePosition, modePosition]
  else:
    result.op = codeStr[codeLen-2 .. codeLen-1].parseInt().OpCode
    for idx, m in codeStr[0 ..< codeLen-maxOpCodeLen]:
      doAssert (m in {'0', '1'})
      #|---------+-----+-------------|
      #| codeLen | idx | modes index |
      #|---------+-----+-------------|
      #|       3 |   0 | 3-0-3 = 0   |
      #|       4 |   0 | 4-0-3 = 1   |
      #|       4 |   1 | 4-1-3 = 0   |
      #|       5 |   0 | 5-0-3 = 2   |
      #|       5 |   1 | 5-1-3 = 1   |
      #|       5 |   2 | 5-2-3 = 0   |
      #|---------+-----+-------------|
      result.modes[codeLen-idx-maxNumParameters] = parseInt($m).Mode

proc process*(codes: seq[int]): seq[int] =
  result = codes
  var
    address = 0

  while address < codes.len():
    let
      rawCode = result[address]
      code = rawCode.parseCode()

    var
      params: array[maxNumParameters, int]
      numInputs = 0
      outParamIdx = -1

    if spec.hasKey(code.op.ord):
      (numInputs, outParamIdx) = spec[code.op.ord]
      if numInputs > 0:
        for idx in 0 ..< numInputs:
          if code.modes[idx] == modePosition:
            params[idx] = result[codes[address+idx+1]]
          else:
            params[idx] = result[address+idx+1]

    when defined(debug):
      echo &"{rawCode} => code = {code}, params = {params}"

    case code.op
    of opAdd:
      when defined(debug):
        echo &"[{address}] Add opcode {code.op.ord} detected"
      params[outParamIdx] = params[0] + params[1]
    of opMul:
      when defined(debug):
        echo &"[{address}] Mul opcode {code.op.ord} detected"
      params[outParamIdx] = params[0] * params[1]
    of opInput:
      discard
    of opOutput:
      discard
    of opHalt:
      when defined(debug):
        echo &"[{address}] Halt opcode {code.op.ord} detected, aborting .."
      break

    if outParamIdx >= 0:
      if code.modes[outParamIdx] == modePosition:
        result[codes[address+outParamIdx+1]] = params[outParamIdx]
      else:
        result[address+outParamIdx+1] = params[outParamIdx]
      address.inc(1 + numInputs + 1) # incr over the current opcode, input params and output param
    else:
      address.inc(1 + numInputs) # incr over the current opcode and input params

  when defined(debug):
    echo &"Modified codes: {result}"

when isMainModule:
  import std/[os, unittest]
  import days_utils

  const
    inputFile = currentSourcePath.parentDir() / "input.txt"

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
