import std/[os, strutils, sequtils, strformat]

const
  opAdd = 1
  opMul = 2
  opHalt = 99

proc availCheck(address: int; codes: seq[int]) =
  if codes.len()-1 < address+3:
    echo &"Unable to access address {address+3}, aborting .."
    quit QuitFailure

proc update(skipAddrs: var seq[int]; address: int) =
  for i in 1 .. 3:
    skipAddrs.add(address + i)
  echo &"Skipped addresses: {skipAddrs}"

proc process(codes: seq[int]): seq[int] =
  result = codes
  var
    address = 0
    skipAddrs: seq[int]

  for code in codes:
    if address in skipAddrs:
      echo &"[{address}] Skipping this .."
      address.inc()
      continue

    case code
    of opAdd:
      echo &"[{address}] Add code {code} detected"
      address.availCheck(codes)
      result[codes[address+3]] = result[codes[address+1]] + result[codes[address+2]]
      skipAddrs.update(address)
    of opMul:
      echo &"[{address}] Mul code {code} detected"
      address.availCheck(codes)
      result[codes[address+3]] = result[codes[address+1]] * result[codes[address+2]]
      skipAddrs.update(address)
    of opHalt:
      echo &"[{address}] Halt code {code} detected, aborting .."
      break
    else:
      echo &"[{address}] code {code} detected"
    address.inc()

  echo &"Modified codes: {result}"

proc state1202Alert(codes: seq[int]) =
  var
    codes = codes
  codes[1] = 12
  codes[2] = 2
  let
    modCodes = codes.process()
  echo &"value at position 0: {modCodes[0]}"

when isMainModule:
  let
    fileName = if paramCount() > 0:
                 # Use the first input arg as the input file name, is present.
                 commandLineParams()[0]
               else:
                 "input.txt"
    codes = readFile(fileName).strip().split(',').mapIt(it.strip().parseInt())
  codes.state1202Alert()
  # discard codes.process()
