import std/[strformat, strutils, tables]
when not defined(memdump):
  import std/[os]
import days_utils

const
  maxNumParameters* = 3
  maxOpCodeLen* = 2
  maxCodeLen* = maxNumParameters + maxOpCodeLen

type
  Mode* = enum
    modePosition = 0
    modeImmediate
    modeRelative
  OpCode* = enum
    opAdd = 1
    opMul = 2
    opInput = 3
    opOutput = 4
    opJumpIfTrue = 5
    opJumpIfFalse = 6
    opLessThan = 7
    opEquals = 8
    opAdjRelBase = 9
    opHalt = 99
  Code* = tuple
    op: OpCode
    modes: array[maxNumParameters, Mode]
  Spec* = tuple
    numInputs: int
    outParamIdx: int
  ProcessOut* = tuple
    address: int
    codes: seq[int]
    outputs: seq[int]

# opcode spec
let
  spec: Table[string, Spec] =
    { $opAdd         : (numInputs: 2, outParamIdx: 2),
      $opMul         : (numInputs: 2, outParamIdx: 2),
      $opInput       : (numInputs: 0, outParamIdx: 0),
      $opOutput      : (numInputs: 1, outParamIdx: -1),
      $opJumpIfTrue  : (numInputs: 2, outParamIdx: -1),
      $opJumpIfFalse : (numInputs: 2, outParamIdx: -1),
      $opLessThan    : (numInputs: 2, outParamIdx: 2),
      $opEquals      : (numInputs: 2, outParamIdx: 2),
      $opAdjRelBase  : (numInputs: 1, outParamIdx: -1),
      $opHalt        : (numInputs: 0, outParamIdx: -1) }.toTable

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
      let
        mode = parseInt($m).Mode
        mStr = $mode
      doAssert not mStr.contains("(invalid data!)")
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
      result.modes[codeLen-idx-maxNumParameters] = mode

var
  id = -1

proc process*(codes: openArray[int]; inputs: seq[int] = @[]; initialAddress = 0; quiet = false): ProcessOut =
  var
    memory: Table[int, int]
    address = initialAddress
    maxAddress = codes.len
    relativeBase = 0
    inputIdx = -1

  id.inc

  # Populate the memory
  for idx, code in codes:
    memory[idx] = code

  when defined(debug):
    var
      prevOpCode: OpCode

  while true:
    let
      rawCode = memory[address]
      code = rawCode.parseCode()
      opCodeStr = $code.op

    when defined(debug):
      echo &"[{address}] Instruction {opCodeStr} ({code.op.ord}) detected"
    # Valid opcode check
    doAssert not opCodeStr.contains("(invalid data!)")

    var
      params: array[maxNumParameters, int]
      numInputs = 0
      outParamIdx = -1
      jumpAddress = -1

    (numInputs, outParamIdx) = spec[opCodeStr]
    for idx in 0 ..< numInputs:
      let
        addr1 = address+idx+1
      if defined(debug):
        echo &"addr1 = {addr1}"
      if code.modes[idx] == modeImmediate:
        params[idx] = memory[addr1] # direct
      else:
        let
          addr2 = if code.modes[idx] == modePosition:
                    memory[addr1] # indirect, address relative to 0
                  else:
                    relativeBase+memory[addr1] # indirect, address relative to the relative base
        if defined(debug):
          echo &"addr2 = {addr2}"
        doAssert addr2 >= 0
        maxAddress = max(maxAddress, addr2)
        params[idx] = memory.getOrDefault(addr2)

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
          echo &"-> {params[outParamIdx]}"
        else:
          # If the input queue is empty, return.  The saved state of
          # the current address (instruction pointer) and the modified
          # code are part of the returned data for future restore.
          for i in 0 ..< maxAddress:
            result.codes.add(memory.getOrDefault(i))
          return
    of opOutput:
      result.outputs.add(params[0])
      when defined(debug):
        echo &"Instruction run before this {code.op} instruction: {prevOpCode}"
      case code.modes[0]
      of modePosition:
        let
          addr2 = memory[address+1]
        echo &"   .. memory[{address+1}] -> memory[{addr2}] => {params[0]}"
      of modeImmediate:
        echo &"   .. memory[{address+1}] => {params[0]}"
      of modeRelative:
        let
          addr2 = relativeBase+memory[address+1]
        echo &"   .. memory[{address+1}] -> memory[{addr2}] => {params[0]}"
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
    of opAdjRelBase:
      relativeBase.inc(params[0])
      when defined(debug):
        echo &"[{address}] Relative base = {relativeBase}"
    of opHalt:
      if not quiet:
        echo &"[{address}] Quitting .."
      for i in 0 ..< maxAddress:
        result.codes.add(memory.getOrDefault(i))
      let
        memDumpFile = prjDir(&"memdump{id}.txt")
      when defined(memdump):
        var
          memDumpStr: string
        for i, code in result.codes:
          memDumpStr.add(&"{i:>4}: {code}\n")
        memDumpFile.writeFile(memDumpStr)
      else:
        discard memDumpFile.tryRemoveFile()

      result.address = -1
      return

    if code.op in {opJumpIfTrue, opJumpIfFalse} and jumpAddress >= 0:
      doAssert jumpAddress != address # do not keep on jumping to the current address
      address = jumpAddress
    elif outParamIdx >= 0:
      doAssert code.modes[outParamIdx] != modeImmediate,
         "Parameters that an instruction writes to cannot be in immediate mode."
      var
        addr2 = memory[address+outParamIdx+1]
      when defined(debug):
        stdout.write &"==> memory[{address+outParamIdx+1}] -> "
      if code.modes[outParamIdx] == modePosition:
        when defined(debug):
          echo &"memory[{memory[address+outParamIdx+1]}] = {params[outParamIdx]}"
      elif code.modes[outParamIdx] == modeRelative:
        addr2.inc(relativeBase)
        when defined(debug):
          echo &"memory[{relativeBase}+{addr2-relativeBase}] = {params[outParamIdx]}"
      memory[addr2] = params[outParamIdx]
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
    codes = codes.process(quiet = true).codes
    when defined(debug):
      echo &"value at position 0: {codes[0]}"
    return codes[0]

  if paramCount() > 0:
    echo commandLineParams()[0].readFileToIntSeq().process().codes
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
          @[1, 9, 10, 3, 2, 3, 11, 0, 99, 30, 40, 50].process().codes == @[3500, 9, 10, 70, 2, 3, 11, 0, 99, 30, 40, 50]
      test "add 1":
        check:
          @[1, 0, 0, 0, 99].process().codes == @[2, 0, 0, 0, 99]
      test "mul 1":
        check:
          @[2, 3, 0, 3, 99].process().codes == @[2, 3, 0, 6, 99]
      test "mul 2":
        check:
          @[2, 4, 4, 5, 99, 0].process().codes == @[2, 4, 4, 5, 99, 9801]
      test "add + mul":
        check:
          @[1, 1, 1, 4, 99, 5, 6, 0, 99].process().codes == @[30, 1, 1, 4, 2, 5, 6, 0, 99]
      test "1202 program alert":
        check:
          state("input.txt", 12, 2) == 4138658
