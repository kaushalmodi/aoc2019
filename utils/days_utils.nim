import std/[strutils, sequtils]

proc readFileToSeq*(fileName: string): seq[int] =
  ## Read a file into a sequence of ints.
  let
    str = fileName.readFile().strip()
  if str.contains({','}):
    result = str.split(',').mapIt(it.strip().parseInt())
  else:
    result = str.splitLines().mapIt(it.strip().parseInt())
