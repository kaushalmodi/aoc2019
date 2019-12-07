import std/[os, macros, strutils, sequtils]

proc prjDir*(fileName: string): string =
  const
    pDir = getProjectPath()
  result = pDir / fileName

proc readFileToSeq*(fileName: string): seq[int] =
  ## Read a file into a sequence of ints.
  let
    str = fileName.prjDir().readFile().strip()
  if str.contains({','}):
    result = str.split(',').mapIt(it.strip().parseInt())
  else:
    result = str.splitLines().mapIt(it.strip().parseInt())
