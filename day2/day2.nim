import std/[strformat, strutils, tables]

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
    opJumpIfTrue = 5
    opJumpIfFalse = 6
    opLessThan = 7
    opEquals = 8
    opHalt = 99
  Code* = tuple
    op: OpCode
    modes: array[maxNumParameters, Mode]
  Spec* = tuple
    numInputs: int
    outParamIdx: int
  ProcessOut* = tuple
    address: int
    modCodes: seq[int]
    output: int

# opcode spec
let
  spec: Table[string, Spec] =
    { $opAdd         : (numInputs: 2, outParamIdx: 2),
      $opMul         : (numInputs: 2, outParamIdx: 2),
      $opHalt        : (numInputs: 0, outParamIdx: -1),
      $opInput       : (numInputs: 0, outParamIdx: 0),
      $opOutput      : (numInputs: 1, outParamIdx: -1),
      $opJumpIfTrue  : (numInputs: 2, outParamIdx: -1),
      $opJumpIfFalse : (numInputs: 2, outParamIdx: -1),
      $opLessThan    : (numInputs: 2, outParamIdx: 2),
      $opEquals      : (numInputs: 2, outParamIdx: 2) }.toTable

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

proc process*(codes: seq[int]; inputs: seq[int] = @[]; initialAddress = 0; quiet = false): ProcessOut =
  result.modCodes = codes
  var
    address = initialAddress
    prevOpCode: OpCode
    inputIdx = -1

  while address < codes.len():
    let
      rawCode = result.modCodes[address]
      code = rawCode.parseCode()
      opCodeStr = $code.op

    when defined(debug):
      echo &"[{address}] Instruction {opCodeStr} ({code.op}) detected"
    # Valid opcode check
    doAssert not opCodeStr.contains("(invalid data!)")

    var
      params: array[maxNumParameters, int]
      numInputs = 0
      outParamIdx = -1
      jumpAddress = -1

    if spec.hasKey(opCodeStr):
      (numInputs, outParamIdx) = spec[opCodeStr]
      if numInputs > 0:
        for idx in 0 ..< numInputs:
          if code.modes[idx] == modePosition:
            params[idx] = result.modCodes[result.modCodes[address+idx+1]]
          else:
            params[idx] = result.modCodes[address+idx+1]

    when defined(debug):
      echo &"{rawCode} => code = {code}, params = {params}"

    case code.op
    of opAdd:
      params[outParamIdx] = params[0] + params[1]
    of opMul:
      params[outParamIdx] = params[0] * params[1]
    of opInput:
      if inputs.len == 0:
        stdout.write "User Input? "
        params[outParamIdx] = stdin.readLine().parseInt()
      else:
        if inputIdx < inputs.high:
          inputIdx.inc
          params[outParamIdx] = inputs[inputIdx]
          echo &"Received input {params[outParamIdx]}"
        else:
          # If the input queue is empty, return.  The saved state of
          # the current address (instruction pointer) and the modified
          # code are part of the returned data for future restore.
          return
    of opOutput:
      result.output = params[0]
      echo &"Instruction run before this {code.op} instruction: {prevOpCode}"
      if code.modes[0] == modePosition:
        echo &" -> Value at address {result.modCodes[address+1]} (pointed to by address {address+1}) = {result.output}"
      else:
        echo &" -> Value at address {address+1} = {result.output}"
    of opJumpIfTrue:
      if params[0] != 0:
        jumpAddress = params[1]
    of opJumpIfFalse:
      if params[0] == 0:
        jumpAddress = params[1]
    of opLessThan:
      params[outParamIdx] = 0
      if params[0] < params[1]:
        params[outParamIdx] = 1
    of opEquals:
      params[outParamIdx] = 0
      if params[0] == params[1]:
        params[outParamIdx] = 1
    of opHalt:
      if not quiet:
        echo &"[{address}] Quitting .."
      when defined(debug):
        echo &"Modified codes: {result.modCodes}"
      result.address = -1
      return

    if code.op in {opJumpIfTrue, opJumpIfFalse} and jumpAddress >= 0:
      doAssert jumpAddress != address # do not keep on jumping to the current address
      address = jumpAddress
    elif outParamIdx >= 0:
      # Parameters that an instruction writes to will never be in
      # immediate mode.
      doAssert code.modes[outParamIdx] == modePosition
      result.modCodes[result.modCodes[address+outParamIdx+1]] = params[outParamIdx]
      address.inc(1 + numInputs + 1) # incr over the current opcode, input params and output param
    else:
      address.inc(1 + numInputs) # incr over the current opcode and input params
    result.address = address
    when defined(debug):
      echo &".. next address = {address}"
    prevOpCode = code.op

when isMainModule:
  import std/[os, unittest]
  import days_utils

  proc state(fileName: string, noun = -1, verb = -1): int =
    var
      codes = fileName.readFileToIntSeq()
    if noun in {0 .. 99}:
      codes[1] = noun
    if verb in {0 .. 99}:
      codes[2] = verb
    let
      modCodes = codes.process(quiet = true).modCodes
    when defined(debug):
      echo &"value at position 0: {modCodes[0]}"
    return modCodes[0]

  if paramCount() > 0:
    echo commandLineParams()[0].readFileToIntSeq().process().modCodes
  else:
    let
      specialOutput = 19690720
    block nvLoop:
      for n in 0 .. 99:
        for v in 0 .. 99:
          if state("input.txt", n, v) == specialOutput:
            echo &"output matched with {specialOutput}!"
            echo &"{100*n + v}"
            break nvLoop

    suite "day2 tests":
      test "example":
        check:
          @[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50].process().modCodes == @[3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50]
      test "add 1":
        check:
          @[1, 0, 0, 0, 99].process().modCodes == @[2, 0, 0, 0, 99]
      test "mul 1":
        check:
          @[2, 3, 0, 3, 99].process().modCodes == @[2, 3, 0, 6, 99]
      test "mul 2":
        check:
          @[2, 4, 4, 5, 99, 0].process().modCodes == @[2, 4, 4, 5, 99, 9801]
      test "add + mul":
        check:
          @[1, 1, 1, 4, 99, 5, 6, 0, 99].process().modCodes == @[30, 1, 1, 4, 2, 5, 6, 0, 99]
      test "1202 program alert":
        check:
          state("input.txt", 12, 2) == 4138658
