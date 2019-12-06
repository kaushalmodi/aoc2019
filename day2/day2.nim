import std/[os, strutils, sequtils, strformat]
import days_utils

const
  opAdd = 1
  opMul = 2
  opHalt = 99

proc process(codes: seq[int]): seq[int] =
  result = codes
  var
    address = 0

  while address < codes.len():
    let
      code = result[address]
    case code
    of opAdd:
      echo &"[{address}] Add code {code} detected"
      result[codes[address+3]] = result[codes[address+1]] + result[codes[address+2]]
      address.inc(4) # skip operands and output pointer registers
    of opMul:
      echo &"[{address}] Mul code {code} detected"
      result[codes[address+3]] = result[codes[address+1]] * result[codes[address+2]]
      address.inc(4) # skip operands and output pointer registers
    of opHalt:
      echo &"[{address}] Halt code {code} detected, aborting .."
      break
    else:
      echo &"[{address}] Invalid code {code} detected"
      quit QuitFailure

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
  echo &"value at position 0: {modCodes[0]}"
  return modCodes[0]

when isMainModule:
  let
    fileName = if paramCount() > 0:
                 # Use the first input arg as the input file name, is present.
                 commandLineParams()[0]
               else:
                 "input.txt"
  # discard state(fileName) # for testing without setting the noun and verb
  discard state(fileName, 12, 2) # 1202 program alert

  let
    specialOutput = 19690720
  block nvLoop:
    for n in 0 .. 99:
      for v in 0 .. 99:
        if state(fileName, n, v) == specialOutput:
          echo &"output matched with {specialOutput}!"
          echo &"{100*n + v}"
          break nvLoop
